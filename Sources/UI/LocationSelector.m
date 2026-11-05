#import "LocationSelector.h"
#import "../Headers.h"
#import "../Constants.h"
#import "WAExtraLocalization.h"

@interface LocationSelector ()
@property (nonatomic, strong) MKMapView *mapView;
@end

@implementation LocationSelector

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = [WAExtraLocalization localizedStringForKey:@"SELECT_FAKE_LOCATION_TITLE"];
    self.view.backgroundColor = [UIColor systemBackgroundColor];

    [self setupMapView];
    [self setupCloseButton];
    [self setupMapSelectorSegment];
    [self loadDefaultLocation];
}

- (void)setupMapView {
    self.mapView = [[MKMapView alloc] initWithFrame:self.view.bounds];
    self.mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.mapView.delegate = self;
    [self.view addSubview:self.mapView];

    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleMapTap:)];
    [self.mapView addGestureRecognizer:tapGesture];
}

- (void)setupCloseButton {
    UIBarButtonItem *closeItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(closeButtonTapped)];
    self.navigationItem.rightBarButtonItem = closeItem;
}

- (void)closeButtonTapped {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)setupMapSelectorSegment {
    NSArray *mapTypes = @[@"Map", @"Satellite", @"Hybrid"];
    UISegmentedControl *segmentControl = [[UISegmentedControl alloc] initWithItems:mapTypes];
    segmentControl.selectedSegmentIndex = 0;

    [segmentControl addTarget:self action:@selector(mapTypeChanged:) forControlEvents:UIControlEventValueChanged];
    segmentControl.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:segmentControl];

    [NSLayoutConstraint activateConstraints:@[
        [segmentControl.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor constant:16],
        [segmentControl.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor constant:-16],
        [segmentControl.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-16],
        [segmentControl.heightAnchor constraintEqualToConstant:32]
    ]];
}

- (void)mapTypeChanged:(UISegmentedControl *)sender {
    switch (sender.selectedSegmentIndex) {
        case 0:
            self.mapView.mapType = MKMapTypeStandard;
            break;
        case 1:
            self.mapView.mapType = MKMapTypeSatellite;
            break;
        case 2:
            self.mapView.mapType = MKMapTypeHybrid;
            break;
        default:
            break;
    }
}

- (void)loadDefaultLocation {
    CGFloat savedLongitude = [[NSUserDefaults standardUserDefaults] floatForKey:FAKE_LONGITUDE_KEY];
    CGFloat savedLatitude = [[NSUserDefaults standardUserDefaults] floatForKey:FAKE_LATITUDE_KEY];

    CLLocationCoordinate2D centerCoordinate;
    if (savedLongitude != 0.0 && savedLatitude != 0.0) {
        centerCoordinate = CLLocationCoordinate2DMake(savedLatitude, savedLongitude);
        [self addPinAtCoordinate:centerCoordinate withTitle:@"Selected Location"];
    } else {
        centerCoordinate = CLLocationCoordinate2DMake(37.7749, -122.4194); // Default to San Francisco
    }

    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(centerCoordinate, 5000, 5000);
    [self.mapView setRegion:region animated:YES];
}

- (void)handleMapTap:(UITapGestureRecognizer *)gesture {
    CGPoint touchPoint = [gesture locationInView:self.mapView];
    CLLocationCoordinate2D coordinate = [self.mapView convertPoint:touchPoint toCoordinateFromView:self.mapView];

    [self addPinAtCoordinate:coordinate withTitle:@"Selected Location"];

    [[NSUserDefaults standardUserDefaults] setFloat:coordinate.longitude forKey:FAKE_LONGITUDE_KEY];
    [[NSUserDefaults standardUserDefaults] setFloat:coordinate.latitude forKey:FAKE_LATITUDE_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];

    [[NSNotificationCenter defaultCenter] postNotificationName:@"TweakLocationChanged" object:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"LeadLocationChanged" object:nil];
}

- (void)addPinAtCoordinate:(CLLocationCoordinate2D)coordinate withTitle:(NSString *)title {
    MKPointAnnotation *annotation = [[MKPointAnnotation alloc] init];
    annotation.coordinate = coordinate;
    annotation.title = title;

    [self.mapView removeAnnotations:self.mapView.annotations];
    [self.mapView addAnnotation:annotation];
}

@end
