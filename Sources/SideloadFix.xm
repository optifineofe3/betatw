#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <UserNotifications/UserNotifications.h>
#import <Contacts/Contacts.h>
#import <Security/Security.h>
#import <Intents/Intents.h>
#import <AVFoundation/AVFoundation.h>
#import <Photos/Photos.h>
#import <objc/runtime.h>
#include <dlfcn.h>
#include <unistd.h>
#import "Headers.h"
#import "Logger.h"
#import "fishhook.h"

static NSURL *fakeGroupContainerURL = nil;
static NSString *keychainAccessGroup = nil;

#pragma mark - 1. Keychain Access Group Sanitization (sparkle-ig-main pattern)

static OSStatus (*orig_SecItemDelete)(CFDictionaryRef);
static OSStatus (*orig_SecItemAdd)(CFDictionaryRef, CFTypeRef*);
static OSStatus (*orig_SecItemUpdate)(CFDictionaryRef, CFDictionaryRef);
static OSStatus (*orig_SecItemCopyMatching)(CFDictionaryRef, CFTypeRef*);

static CFDictionaryRef sanitizedQuery(CFDictionaryRef query, BOOL injectWhenMissing) {
    if (!query) return NULL;
    NSDictionary *dict = (__bridge NSDictionary *)query;
    if (![dict isKindOfClass:[NSDictionary class]]) {
        return (CFDictionaryRef)CFRetain(query);
    }

    BOOL hasGroup = dict[(__bridge NSString *)kSecAttrAccessGroup] != nil;
    if (!hasGroup && !injectWhenMissing) {
        return (CFDictionaryRef)CFRetain(query);
    }

    NSMutableDictionary *mutableQuery = [dict mutableCopy];
    if (keychainAccessGroup && keychainAccessGroup.length > 0) {
        mutableQuery[(__bridge NSString *)kSecAttrAccessGroup] = keychainAccessGroup;
    } else {
        [mutableQuery removeObjectForKey:(__bridge NSString *)kSecAttrAccessGroup];
    }
    return (CFDictionaryRef)CFBridgingRetain(mutableQuery);
}

static OSStatus hook_SecItemAdd(CFDictionaryRef attributes, CFTypeRef* result) {
    CFDictionaryRef cleanAttrs = sanitizedQuery(attributes, YES);
    OSStatus status = orig_SecItemAdd(cleanAttrs ? cleanAttrs : attributes, result);
    if (cleanAttrs) CFRelease(cleanAttrs);
    return status;
}

static OSStatus hook_SecItemCopyMatching(CFDictionaryRef query, CFTypeRef* result) {
    CFDictionaryRef cleanQuery = sanitizedQuery(query, YES);
    OSStatus status = orig_SecItemCopyMatching(cleanQuery ? cleanQuery : query, result);
    if (cleanQuery) CFRelease(cleanQuery);
    return status;
}

static OSStatus hook_SecItemUpdate(CFDictionaryRef query, CFDictionaryRef attributesToUpdate) {
    CFDictionaryRef cleanQuery = sanitizedQuery(query, YES);
    CFDictionaryRef cleanAttrs = sanitizedQuery(attributesToUpdate, NO);
    OSStatus status = orig_SecItemUpdate(cleanQuery ? cleanQuery : query, cleanAttrs ? cleanAttrs : attributesToUpdate);
    if (cleanQuery) CFRelease(cleanQuery);
    if (cleanAttrs) CFRelease(cleanAttrs);
    return status;
}

static OSStatus hook_SecItemDelete(CFDictionaryRef query) {
    CFDictionaryRef cleanQuery = sanitizedQuery(query, YES);
    OSStatus status = orig_SecItemDelete(cleanQuery ? cleanQuery : query);
    if (cleanQuery) CFRelease(cleanQuery);
    return status;
}

static void createDirectoryIfNotExists(NSURL *URL) {
    if (!URL) return;
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:URL.path]) {
        [fm createDirectoryAtURL:URL withIntermediateDirectories:YES attributes:nil error:nil];
    }
}

static void loadKeychainAccessGroup(void) {
    NSDictionary *dummyItem = @{
        (__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrAccount : @"dummyWAFix",
        (__bridge id)kSecAttrService : @"dummyService",
        (__bridge id)kSecReturnAttributes : @YES,
    };

    CFTypeRef result = NULL;
    OSStatus ret = SecItemCopyMatching((__bridge CFDictionaryRef)dummyItem, &result);
    if (ret == errSecItemNotFound) {
        ret = SecItemAdd((__bridge CFDictionaryRef)dummyItem, &result);
    }

    if (ret == errSecSuccess && result) {
        NSDictionary *resultDict = (__bridge id)result;
        keychainAccessGroup = [resultDict[(__bridge id)kSecAttrAccessGroup] copy];
        CFRelease(result);
        WATweakLog(@"Keychain access group discovered: %@", keychainAccessGroup);
    }
}

#pragma mark - 2. SecTask Entitlement Check Spoofing (Siri & CloudKit)

typedef struct __SecTask *SecTaskRef;

static CFTypeRef (*orig_SecTaskCopyValueForEntitlement)(SecTaskRef, CFStringRef, CFErrorRef *);
static CFDictionaryRef (*orig_SecTaskCopyValuesForEntitlements)(SecTaskRef, CFArrayRef, CFErrorRef *);

static CFTypeRef hook_SecTaskCopyValueForEntitlement(SecTaskRef task, CFStringRef entitlement, CFErrorRef *error) {
    if (entitlement) {
        NSString *ent = (__bridge NSString *)entitlement;
        if ([ent isEqualToString:@"com.apple.developer.siri"]) {
            WATweakLog(@"SecTaskCopyValueForEntitlement: spoofing com.apple.developer.siri -> YES");
            return (CFTypeRef)CFRetain(kCFBooleanTrue);
        }
        if ([ent isEqualToString:@"com.apple.developer.icloud-container-environment"] ||
            [ent isEqualToString:@"com.apple.developer.icloud-services"]) {
            return NULL;
        }
    }
    return orig_SecTaskCopyValueForEntitlement ? orig_SecTaskCopyValueForEntitlement(task, entitlement, error) : NULL;
}

static CFDictionaryRef hook_SecTaskCopyValuesForEntitlements(SecTaskRef task, CFArrayRef entitlements, CFErrorRef *error) {
    CFDictionaryRef origDict = orig_SecTaskCopyValuesForEntitlements ? orig_SecTaskCopyValuesForEntitlements(task, entitlements, error) : NULL;
    NSMutableDictionary *mut = origDict ? [(__bridge NSDictionary *)origDict mutableCopy] : [NSMutableDictionary dictionary];
    mut[@"com.apple.developer.siri"] = @YES;
    [mut removeObjectForKey:@"com.apple.developer.icloud-container-environment"];
    [mut removeObjectForKey:@"com.apple.developer.icloud-services"];
    return (CFDictionaryRef)CFBridgingRetain(mut);
}

#pragma mark - 3. CloudKit Sideload Fix (Suppresses CKException in LiveContainer)

%hook CKContainer

+ (id)defaultContainer {
    return nil;
}

+ (id)containerWithIdentifier:(id)a {
    return nil;
}

- (id)_setupWithContainerID:(id)a options:(id)b {
    return nil;
}

- (id)_initWithContainerIdentifier:(id)a {
    return nil;
}

%end

%hook CKEntitlements

- (id)initWithEntitlementsDict:(NSDictionary *)entitlements {
    NSMutableDictionary *mutEntitlements = [entitlements mutableCopy];
    [mutEntitlements removeObjectForKey:@"com.apple.developer.icloud-container-environment"];
    [mutEntitlements removeObjectForKey:@"com.apple.developer.icloud-services"];
    return %orig([mutEntitlements copy]);
}

%end

#pragma mark - 4. DeviceCheck & App Attest Sideload Fix

%hook DCDevice

+ (instancetype)currentDevice {
    return %orig;
}

- (BOOL)isSupported {
    return NO;
}

- (void)generateTokenWithCompletionHandler:(void (^)(NSData *token, NSError *error))completionHandler {
    WATweakLog(@"DCDevice generateTokenWithCompletionHandler -> returning unsupported error");
    if (completionHandler) {
        NSError *err = [NSError errorWithDomain:@"com.apple.devicecheck.error" code:1 userInfo:nil];
        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(nil, err);
        });
    }
}

%end

%hook DCAppAttestService

+ (instancetype)sharedService {
    return %orig;
}

- (BOOL)isSupported {
    return NO;
}

- (void)generateKeyWithCompletionHandler:(void (^)(NSString *keyId, NSError *error))completionHandler {
    WATweakLog(@"DCAppAttestService generateKeyWithCompletionHandler -> returning unsupported error");
    if (completionHandler) {
        NSError *err = [NSError errorWithDomain:@"com.apple.devicecheck.error" code:1 userInfo:nil];
        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(nil, err);
        });
    }
}

- (void)attestKey:(NSString *)keyId clientDataHash:(NSData *)clientDataHash completionHandler:(void (^)(NSData *attestationObject, NSError *error))completionHandler {
    WATweakLog(@"DCAppAttestService attestKey -> returning unsupported error");
    if (completionHandler) {
        NSError *err = [NSError errorWithDomain:@"com.apple.devicecheck.error" code:1 userInfo:nil];
        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(nil, err);
        });
    }
}

%end

#pragma mark - 5. Siri & Intents Entitlement Fix (Full Safe Mock)

@implementation WAFakeVocabulary

+ (instancetype)sharedInstance {
    static WAFakeVocabulary *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[WAFakeVocabulary alloc] init];
    });
    return instance;
}

- (void)setVocabulary:(id)arg1 ofType:(NSInteger)arg2 {
    WATweakLog(@"[Siri] Fake setVocabulary:ofType: called -> safely ignored");
}

- (void)setVocabularyStrings:(id)arg1 ofType:(NSInteger)arg2 {
    WATweakLog(@"[Siri] Fake setVocabularyStrings:ofType: called -> safely ignored");
}

- (void)removeAllVocabularyStrings {
    WATweakLog(@"[Siri] Fake removeAllVocabularyStrings called -> safely ignored");
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    return [NSMethodSignature signatureWithObjCTypes:"v@:@q"];
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    // Safe no-op forwarder
}

@end

%hook INPreferences

+ (NSInteger)siriAuthorizationStatus {
    return 2; // INSiriAuthorizationStatusDenied -> tells WhatsApp Siri is disabled
}

+ (void)requestSiriAuthorization:(void (^)(NSInteger status))handler {
    if (handler) {
        dispatch_async(dispatch_get_main_queue(), ^{
            handler(2);
        });
    }
}

+ (id)siriLanguageCode {
    return @"en-US";
}

- (void)_verifyEntitlements {
    // Suppress entitlement throw
}

- (instancetype)init {
    return self;
}

%end

%hook INVocabulary

+ (id)sharedVocabulary {
    return [WAFakeVocabulary sharedInstance];
}

- (instancetype)init {
    return (id)[WAFakeVocabulary sharedInstance];
}

- (void)setVocabulary:(id)arg1 ofType:(NSInteger)arg2 {
    WATweakLog(@"[Siri] INVocabulary setVocabulary:ofType: -> ignored");
}

- (void)setVocabularyStrings:(id)arg1 ofType:(NSInteger)arg2 {
    WATweakLog(@"[Siri] INVocabulary setVocabularyStrings:ofType: -> ignored");
}

- (void)removeAllVocabularyStrings {
    WATweakLog(@"[Siri] INVocabulary removeAllVocabularyStrings -> ignored");
}

%end

%hook _INVocabulary

+ (id)sharedVocabulary {
    return [WAFakeVocabulary sharedInstance];
}

- (instancetype)init {
    return (id)[WAFakeVocabulary sharedInstance];
}

- (void)setVocabulary:(id)arg1 ofType:(NSInteger)arg2 {
    WATweakLog(@"[Siri] _INVocabulary setVocabulary:ofType: -> ignored");
}

- (void)setVocabularyStrings:(id)arg1 ofType:(NSInteger)arg2 {
    WATweakLog(@"[Siri] _INVocabulary setVocabularyStrings:ofType: -> ignored");
}

- (void)removeAllVocabularyStrings {
    WATweakLog(@"[Siri] _INVocabulary removeAllVocabularyStrings -> ignored");
}

%end

%hook INInteraction

- (void)donateInteractionWithCompletion:(void (^)(NSError *error))completion {
    if (completion) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(nil);
        });
    }
}

%end

#pragma mark - 6. Bundle Identifier Spoofing for Anti-Tamper

%hook NSBundle

- (NSString *)bundleIdentifier {
    Dl_info info;
    NSArray *address = [NSThread callStackReturnAddresses];
    if (address.count > 2 && dladdr((void *)[address[2] longLongValue], &info) != 0) {
        NSString *path = [NSString stringWithUTF8String:info.dli_fname];
        if ([path hasPrefix:NSBundle.mainBundle.bundlePath]) {
            return @"net.whatsapp.WhatsApp";
        }
    }
    return %orig;
}

- (id)objectForInfoDictionaryKey:(NSString *)key {
    if ([key isEqualToString:@"CFBundleIdentifier"]) {
        return @"net.whatsapp.WhatsApp";
    }
    if ([key isEqualToString:@"CFBundleDisplayName"] || [key isEqualToString:@"CFBundleName"]) {
        return @"WhatsApp";
    }
    return %orig;
}

%end

#pragma mark - 7. Contacts Authorization & Prefill Protection

%hook CNContactStore

+ (CNAuthorizationStatus)authorizationStatusForEntityType:(CNEntityType)entityType {
    WATweakLog(@"CNContactStore authorizationStatusForEntityType -> reporting Denied for sandbox safety");
    return CNAuthorizationStatusDenied;
}

- (void)requestAccessForEntityType:(CNEntityType)entityType completionHandler:(void (^)(BOOL granted, NSError *error))completionHandler {
    WATweakLog(@"CNContactStore requestAccessForEntityType -> safely reporting NO to prevent AddressBook sandbox crash");
    if (completionHandler) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(NO, nil);
        });
    }
}

- (id)unifiedMeContactWithKeysToFetch:(id)keys error:(NSError **)error {
    WATweakLog(@"CNContactStore unifiedMeContactWithKeysToFetch -> nil (sandbox safe)");
    if (error) *error = nil;
    return nil;
}

- (id)unifiedContactsMatchingPredicate:(id)predicate keysToFetch:(id)keys error:(NSError **)error {
    WATweakLog(@"CNContactStore unifiedContactsMatchingPredicate -> empty (sandbox safe)");
    if (error) *error = nil;
    return @[];
}

%end

#pragma mark - 8. Profile Setup Safeguards

%hook WAProfileViewController

- (void)viewDidLoad {
    %orig;
    WATweakLog(@"[ProfileVC] viewDidLoad completed");
}

- (void)savePushNameIfValid {
    WATweakLog(@"[ProfileVC] savePushNameIfValid called!");
    @try {
        %orig;
        WATweakLog(@"[ProfileVC] savePushNameIfValid executed successfully!");
    } @catch (NSException *ex) {
        WATweakLog(@"[ProfileVC] EXCEPTION in savePushNameIfValid: %@ reason: %@", [ex name], [ex reason]);
    }
}

%end

%hook WAVerificationProfileController

- (void)viewDidLoad {
    %orig;
    WATweakLog(@"[VerificationProfileController] viewDidLoad completed");
}

%end

#pragma mark - 9. Notification Permissions Fix for LiveContainer

%hook UNUserNotificationCenter

- (void)requestAuthorizationWithOptions:(UNAuthorizationOptions)options completionHandler:(void (^)(BOOL granted, NSError *error))completionHandler {
    WATweakLog(@"Intercepted UNUserNotificationCenter requestAuthorizationWithOptions -> immediately granting YES");
    if (completionHandler) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(YES, nil);
        });
    }
}

%end

%hook UNNotificationSettings

- (UNAuthorizationStatus)authorizationStatus {
    return UNAuthorizationStatusAuthorized;
}

- (UNNotificationSetting)alertSetting {
    return UNNotificationSettingEnabled;
}

- (UNNotificationSetting)soundSetting {
    return UNNotificationSettingEnabled;
}

- (UNNotificationSetting)badgeSetting {
    return UNNotificationSettingEnabled;
}

- (UNNotificationSetting)notificationCenterSetting {
    return UNNotificationSettingEnabled;
}

- (UNNotificationSetting)lockScreenSetting {
    return UNNotificationSettingEnabled;
}

%end

#pragma mark - 10. Camera & Photos Authorization Fix for LiveContainer

%hook AVCaptureDevice

+ (AVAuthorizationStatus)authorizationStatusForMediaType:(AVMediaType)mediaType {
    AVAuthorizationStatus status = %orig;
    if (status == AVAuthorizationStatusNotDetermined) {
        return AVAuthorizationStatusAuthorized;
    }
    return status;
}

+ (void)requestAccessForMediaType:(AVMediaType)mediaType completionHandler:(void (^)(BOOL granted))handler {
    if (handler) {
        dispatch_async(dispatch_get_main_queue(), ^{
            handler(YES);
        });
    }
}

%end

%hook PHPhotoLibrary

+ (PHAuthorizationStatus)authorizationStatus {
    PHAuthorizationStatus status = %orig;
    if (status == PHAuthorizationStatusNotDetermined) {
        return PHAuthorizationStatusAuthorized;
    }
    return status;
}

+ (PHAuthorizationStatus)authorizationStatusForAccessLevel:(PHAccessLevel)accessLevel {
    PHAuthorizationStatus status = %orig;
    if (status == PHAuthorizationStatusNotDetermined) {
        return PHAuthorizationStatusAuthorized;
    }
    return status;
}

+ (void)requestAuthorization:(void (^)(PHAuthorizationStatus status))handler {
    if (handler) {
        dispatch_async(dispatch_get_main_queue(), ^{
            handler(PHAuthorizationStatusAuthorized);
        });
    }
}

+ (void)requestAuthorizationForAccessLevel:(PHAccessLevel)accessLevel handler:(void (^)(PHAuthorizationStatus status))handler {
    if (handler) {
        dispatch_async(dispatch_get_main_queue(), ^{
            handler(PHAuthorizationStatusAuthorized);
        });
    }
}

%end

#pragma mark - 11. In-App Media Picker Enforcement (LiveContainer Remote PHPicker Fix)

%hook WAABProperties

- (BOOL)ios_media_picker_use_system_for_library {
    return NO;
}

- (BOOL)ios_media_picker_use_system_for_authorization_authorized {
    return NO;
}

- (BOOL)ios_media_picker_use_system_for_authorization_not_determined {
    return NO;
}

- (BOOL)ios_media_picker_use_system_for_authorization_limited {
    return NO;
}

- (BOOL)ios_media_picker_use_system_for_authorization_restricted {
    return NO;
}

- (BOOL)ios_media_picker_use_system_for_authorization_denied {
    return NO;
}

- (BOOL)ios_media_picker_use_system_hide_toolbar {
    return NO;
}

%end

#pragma mark - 12. WhatsApp Contextualize Permissions Primer Bypass

%hook WAContextualizePermissionsHelper

+ (BOOL)isPermissionPrimerEnabledWithUserContext:(id)arg1 {
    return NO;
}

+ (BOOL)isPermissionPrimerV2EnabledWithUserContext:(id)arg1 {
    return NO;
}

+ (BOOL)isContactsPrimerEnabledWithUserContext:(id)arg1 {
    return NO;
}

%end

%hook _TtC26WAContextualizePermissions48ContextualizePermissionsBasePrimerViewController

- (void)startLoadingState {
    %orig;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        @try {
            if ([self respondsToSelector:@selector(endLoadingStateWithCompletion:)]) {
                [self endLoadingStateWithCompletion:^{}];
            }
        } @catch (NSException *e) {}
    });
}

%end

#pragma mark - 11. App Group Redirection (LiveContainer sandbox fix)

%hook NSFileManager

- (NSURL *)containerURLForSecurityApplicationGroupIdentifier:(NSString *)groupIdentifier {
    if (groupIdentifier && groupIdentifier.length > 0) {
        if (!fakeGroupContainerURL) {
            fakeGroupContainerURL = [NSURL fileURLWithPath:[NSHomeDirectory() stringByAppendingPathComponent:@"Documents/FakeGroupContainers"] isDirectory:YES];
        }
        NSURL *fakeURL = [fakeGroupContainerURL URLByAppendingPathComponent:groupIdentifier];
        createDirectoryIfNotExists(fakeURL);
        createDirectoryIfNotExists([fakeURL URLByAppendingPathComponent:@"Library"]);
        createDirectoryIfNotExists([fakeURL URLByAppendingPathComponent:@"Library/Caches"]);
        createDirectoryIfNotExists([fakeURL URLByAppendingPathComponent:@"Documents"]);
        return fakeURL;
    }
    return %orig;
}

%end

#pragma mark - Constructor

%ctor {
    @autoreleasepool {
        installCrashHandler();
        WATweakLog(@"SideloadFix initializing in pid=%d", getpid());

        fakeGroupContainerURL = [NSURL fileURLWithPath:[NSHomeDirectory() stringByAppendingPathComponent:@"Documents/FakeGroupContainers"] isDirectory:YES];
        createDirectoryIfNotExists(fakeGroupContainerURL);

        loadKeychainAccessGroup();

        rebind_symbols(
            (struct rebinding[]){
                {"SecItemAdd", (void*)hook_SecItemAdd, (void**)&orig_SecItemAdd},
                {"SecItemCopyMatching", (void*)hook_SecItemCopyMatching, (void**)&orig_SecItemCopyMatching},
                {"SecItemUpdate", (void*)hook_SecItemUpdate, (void**)&orig_SecItemUpdate},
                {"SecItemDelete", (void*)hook_SecItemDelete, (void**)&orig_SecItemDelete},
                {"SecTaskCopyValueForEntitlement", (void*)hook_SecTaskCopyValueForEntitlement, (void**)&orig_SecTaskCopyValueForEntitlement},
                {"SecTaskCopyValuesForEntitlements", (void*)hook_SecTaskCopyValuesForEntitlements, (void**)&orig_SecTaskCopyValuesForEntitlements},
            },
            6
        );

        %init;
        WATweakLog(@"SideloadFix initialized and %%init completed successfully.");
    }
}
