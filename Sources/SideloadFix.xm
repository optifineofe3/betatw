#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <UserNotifications/UserNotifications.h>
#import <Contacts/Contacts.h>
#import <Security/Security.h>
#import <objc/runtime.h>
#import "Headers.h"
#import "fishhook.h"

static NSURL *fakeGroupContainerURL = nil;
static NSString *keychainAccessGroup = nil;

static OSStatus (*orig_SecItemDelete)(CFDictionaryRef);
static OSStatus (*orig_SecItemAdd)(CFDictionaryRef, CFTypeRef*);
static OSStatus (*orig_SecItemUpdate)(CFDictionaryRef, CFDictionaryRef);
static OSStatus (*orig_SecItemCopyMatching)(CFDictionaryRef, CFTypeRef*);

static CFDictionaryRef sanitizedQuery(CFDictionaryRef query) {
    if (!query) return NULL;
    if (!CFDictionaryContainsKey(query, kSecAttrAccessGroup)) {
        return (CFDictionaryRef)CFRetain(query);
    }

    CFMutableDictionaryRef mutableQuery = CFDictionaryCreateMutableCopy(kCFAllocatorDefault, 0, query);
    if (keychainAccessGroup && keychainAccessGroup.length > 0) {
        CFDictionarySetValue(mutableQuery, kSecAttrAccessGroup, (__bridge void*)keychainAccessGroup);
    } else {
        CFDictionaryRemoveValue(mutableQuery, kSecAttrAccessGroup);
    }
    return mutableQuery;
}

static OSStatus hook_SecItemAdd(CFDictionaryRef attributes, CFTypeRef* result) {
    CFDictionaryRef cleanAttrs = sanitizedQuery(attributes);
    OSStatus status = orig_SecItemAdd(cleanAttrs ? cleanAttrs : attributes, result);
    if (cleanAttrs) CFRelease(cleanAttrs);
    return status;
}

static OSStatus hook_SecItemCopyMatching(CFDictionaryRef query, CFTypeRef* result) {
    CFDictionaryRef cleanQuery = sanitizedQuery(query);
    OSStatus status = orig_SecItemCopyMatching(cleanQuery ? cleanQuery : query, result);
    if (cleanQuery) CFRelease(cleanQuery);
    return status;
}

static OSStatus hook_SecItemUpdate(CFDictionaryRef query, CFDictionaryRef attributesToUpdate) {
    CFDictionaryRef cleanQuery = sanitizedQuery(query);
    CFDictionaryRef cleanAttrs = sanitizedQuery(attributesToUpdate);
    OSStatus status = orig_SecItemUpdate(cleanQuery ? cleanQuery : query, cleanAttrs ? cleanAttrs : attributesToUpdate);
    if (cleanQuery) CFRelease(cleanQuery);
    if (cleanAttrs) CFRelease(cleanAttrs);
    return status;
}

static OSStatus hook_SecItemDelete(CFDictionaryRef query) {
    CFDictionaryRef cleanQuery = sanitizedQuery(query);
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

static void loadKeychainAccessGroup() {
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
    }
}

#pragma mark - Notification Permissions Fix for LiveContainer / Sideloading

%hook UNUserNotificationCenter

- (void)requestAuthorizationWithOptions:(UNAuthorizationOptions)options completionHandler:(void (^)(BOOL granted, NSError *error))completionHandler {
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

#pragma mark - WhatsApp Contextualize Permissions Primer Bypass

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
    // Fallback: if SpringBoard notification response hangs in container, end loading state
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if ([self respondsToSelector:@selector(endLoadingStateWithCompletion:)]) {
            [self endLoadingStateWithCompletion:nil];
        }
    });
}

%end

#pragma mark - Contacts Authorization Fix

%hook CNContactStore

- (void)requestAccessForEntityType:(CNEntityType)entityType completionHandler:(void (^)(BOOL granted, NSError *error))completionHandler {
    if (completionHandler) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(YES, nil);
        });
    }
}

+ (CNAuthorizationStatus)authorizationStatusForEntityType:(CNEntityType)entityType {
    return CNAuthorizationStatusAuthorized;
}

%end

#pragma mark - App Group Redirection (LiveContainer sandbox fix)

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
        fakeGroupContainerURL = [NSURL fileURLWithPath:[NSHomeDirectory() stringByAppendingPathComponent:@"Documents/FakeGroupContainers"] isDirectory:YES];
        createDirectoryIfNotExists(fakeGroupContainerURL);

        loadKeychainAccessGroup();

        rebind_symbols(
            (struct rebinding[]){
                {"SecItemAdd", (void*)hook_SecItemAdd, (void**)&orig_SecItemAdd},
                {"SecItemCopyMatching", (void*)hook_SecItemCopyMatching, (void**)&orig_SecItemCopyMatching},
                {"SecItemUpdate", (void*)hook_SecItemUpdate, (void**)&orig_SecItemUpdate},
                {"SecItemDelete", (void*)hook_SecItemDelete, (void**)&orig_SecItemDelete},
            },
            4
        );
    }
}
