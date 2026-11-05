#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import <objc/runtime.h>
#import "Constants.h"
#import "Headers.h"

static inline BOOL shouldFakeLocation(void) {
    return [[NSUserDefaults standardUserDefaults] boolForKey:FAKE_LOCATION_ENABLED_KEY];
}

static CLLocation *getFakeLocation(void) {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    CGFloat savedLongitude = [defaults floatForKey:FAKE_LONGITUDE_KEY];
    CGFloat savedLatitude = [defaults floatForKey:FAKE_LATITUDE_KEY];
    if (savedLongitude == 0.0 && savedLatitude == 0.0) {
        return nil;
    }
    CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(savedLatitude, savedLongitude);
    return [[CLLocation alloc] initWithCoordinate:coord
                                         altitude:15.0
                               horizontalAccuracy:5.0
                                 verticalAccuracy:5.0
                                        course:0.0
                                         speed:0.0
                                     timestamp:[NSDate date]];
}

@interface WATweakFakeLocationManager : NSObject
@property (nonatomic, strong) NSHashTable<CLLocationManager *> *locationManagers;
@property (nonatomic, strong) NSTimer *lieToDelegateTimer;
+ (instancetype)shared;
- (void)lieToDelegates;
@end

@implementation WATweakFakeLocationManager

+ (instancetype)shared {
    static WATweakFakeLocationManager *inst = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        inst = [[WATweakFakeLocationManager alloc] init];
    });
    return inst;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.locationManagers = [NSHashTable weakObjectsHashTable];
        [self setupTimer];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(appDidEnterBackground)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(appDidBecomeActive)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:nil];
    }
    return self;
}

- (void)setupTimer {
    if (self.lieToDelegateTimer) return;
    __weak typeof(self) weakSelf = self;
    self.lieToDelegateTimer = [NSTimer scheduledTimerWithTimeInterval:15.0
                                                              repeats:YES
                                                                block:^(NSTimer * _Nonnull timer) {
        [weakSelf lieToDelegates];
    }];
}

- (void)lieToDelegates {
    if (!shouldFakeLocation()) return;
    CLLocation *fake = getFakeLocation();
    if (!fake) return;

    NSArray *fakeArr = @[fake];
    for (CLLocationManager *mgr in [self.locationManagers allObjects]) {
        if (!mgr) continue;
        id<CLLocationManagerDelegate> del = mgr.delegate;
        if (!del) continue;
        if ([del respondsToSelector:@selector(locationManager:didUpdateLocations:)]) {
            [del locationManager:mgr didUpdateLocations:fakeArr];
        }
    }
}

- (void)appDidEnterBackground {
    [self.lieToDelegateTimer invalidate];
    self.lieToDelegateTimer = nil;
}

- (void)appDidBecomeActive {
    [self setupTimer];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end

%hook CLLocationManager

- (id)init {
    self = %orig;
    if (self) {
        [[WATweakFakeLocationManager shared].locationManagers addObject:self];
    }
    return self;
}

- (void)setDelegate:(id)delegate {
    %orig;
    [[WATweakFakeLocationManager shared].locationManagers addObject:self];
    if (shouldFakeLocation()) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[WATweakFakeLocationManager shared] lieToDelegates];
        });
    }
}

- (CLLocation *)location {
    if (shouldFakeLocation()) {
        CLLocation *fake = getFakeLocation();
        if (fake) return fake;
    }
    return %orig;
}

- (void)startUpdatingLocation {
    %orig;
    if (shouldFakeLocation()) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[WATweakFakeLocationManager shared] lieToDelegates];
        });
    }
}

%end

%hook MKCoreLocationProvider

- (void)locationManager:(id)manager didUpdateLocations:(id)locations {
    if (shouldFakeLocation()) {
        CLLocation *fake = getFakeLocation();
        if (fake) {
            %orig(manager, @[fake]);
            return;
        }
    }
    %orig;
}

- (id)initWithCLLocationManager:(id)locationManager {
    if ([locationManager isKindOfClass:[CLLocationManager class]]) {
        [[WATweakFakeLocationManager shared].locationManagers addObject:(CLLocationManager *)locationManager];
    }
    return %orig;
}

%end

%hook DeviceLocationManager

- (void)locationManager:(id)manager didUpdateLocations:(id)locations {
    if (shouldFakeLocation()) {
        CLLocation *fake = getFakeLocation();
        if (fake) {
            %orig(manager, @[fake]);
            return;
        }
    }
    %orig;
}

%end

%ctor {
    @autoreleasepool {
        Class devLocCls = objc_getClass("DeviceLocationManager.DeviceLocationManager");
        if (!devLocCls) devLocCls = objc_getClass("DeviceLocationManager");
        if (devLocCls) {
            %init(DeviceLocationManager = devLocCls);
        }
        %init;
        [WATweakFakeLocationManager shared];
    }
}
