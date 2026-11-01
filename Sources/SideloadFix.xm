#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <UserNotifications/UserNotifications.h>
#import <Contacts/Contacts.h>
#import <Security/Security.h>
#import <Intents/Intents.h>
#import <objc/runtime.h>
#import "Headers.h"
#import "fishhook.h"

static NSURL *fakeGroupContainerURL = nil;
static NSString *keychainAccessGroup = nil;

static OSStatus (*orig_SecItemDelete)(CFDictionaryRef);
static OSStatus (*orig_SecItemAdd)(CFDictionaryRef, CFTypeRef*);
static OSStatus (*orig_SecItemUpdate)(CFDictionaryRef, CFDictionaryRef);
static OSStatus (*orig_SecItemCopyMatching)(CFDictionaryRef, CFTypeRef*);
static CFTypeRef (*orig_SecTaskCopyValueForEntitlement)(void *task, CFStringRef entitlement, CFErrorRef *error) = NULL;

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

static CFTypeRef hook_SecTaskCopyValueForEntitlement(void *task, CFStringRef entitlement, CFErrorRef *error) {
    if (entitlement) {
        if (CFEqual(entitlement, CFSTR("com.apple.developer.siri"))) {
            return (CFTypeRef)CFRetain(kCFBooleanTrue);
        }
    }
    if (orig_SecTaskCopyValueForEntitlement) {
        return orig_SecTaskCopyValueForEntitlement(task, entitlement, error);
    }
    return NULL;
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

#pragma mark - Mock Siri Vocabulary

@implementation WAFakeVocabulary

- (void)setVocabularyStrings:(id)arg1 ofType:(NSInteger)arg2 {}
- (void)setVocabulary:(id)arg1 ofType:(NSInteger)arg2 {}
- (void)removeAllVocabularyStrings {}

- (BOOL)respondsToSelector:(SEL)aSelector {
    return YES;
}

- (BOOL)isKindOfClass:(Class)aClass {
    if (aClass == [INVocabulary class] || [NSStringFromClass(aClass) containsString:@"Vocabulary"]) {
        return YES;
    }
    return [super isKindOfClass:aClass];
}

- (id)forwardingTargetForSelector:(SEL)aSelector {
    return nil;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    NSMethodSignature *sig = [super methodSignatureForSelector:aSelector];
    if (!sig) {
        sig = [NSMethodSignature signatureWithObjCTypes:"@@:"];
    }
    return sig;
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    void *nullPtr = NULL;
    if (anInvocation.methodSignature.methodReturnLength > 0) {
        [anInvocation setReturnValue:&nullPtr];
    }
}

@end

#pragma mark - Siri & Intents Entitlement Fix (LiveContainer / Sideloading)

%hook INVocabulary

+ (id)sharedVocabulary {
    static WAFakeVocabulary *fake = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        fake = [[WAFakeVocabulary alloc] init];
    });
    return fake;
}

- (id)init {
    return (id)[[WAFakeVocabulary alloc] init];
}

- (void)setVocabularyStrings:(id)arg1 ofType:(INVocabularyStringType)arg2 {
    // no-op: prevents Siri entitlement check exception
}

%new
- (void)setVocabulary:(id)arg1 ofType:(NSInteger)arg2 {
    // no-op
}

- (void)removeAllVocabularyStrings {
    // no-op
}

%end

%hook INPreferences

+ (INSiriAuthorizationStatus)siriAuthorizationStatus {
    return INSiriAuthorizationStatusAuthorized;
}

+ (void)requestSiriAuthorization:(void (^)(INSiriAuthorizationStatus status))handler {
    if (handler) {
        dispatch_async(dispatch_get_main_queue(), ^{
            handler(INSiriAuthorizationStatusAuthorized);
        });
    }
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
                {"SecTaskCopyValueForEntitlement", (void*)hook_SecTaskCopyValueForEntitlement, (void**)&orig_SecTaskCopyValueForEntitlement},
            },
            5
        );

        // Dynamic hook for private _INVocabulary if present
        Class _inVocabCls = objc_getClass("_INVocabulary");
        if (_inVocabCls) {
            Method mShared = class_getClassMethod(_inVocabCls, @selector(sharedVocabulary));
            if (mShared) {
                method_setImplementation(mShared, imp_implementationWithBlock(^{
                    static WAFakeVocabulary *fake = nil;
                    static dispatch_once_t onceToken;
                    dispatch_once(&onceToken, ^{
                        fake = [[WAFakeVocabulary alloc] init];
                    });
                    return fake;
                }));
            }
            Method mInit = class_getInstanceMethod(_inVocabCls, @selector(init));
            if (mInit) {
                method_setImplementation(mInit, imp_implementationWithBlock(^(id self) {
                    return [[WAFakeVocabulary alloc] init];
                }));
            }
        }

        // Swizzle WhatsApp internal methods that donate Siri vocabulary
        unsigned int classCount = 0;
        Class *classes = objc_copyClassList(&classCount);
        if (classes) {
            SEL sel1 = sel_registerName("__registerSiriVocabulary");
            SEL sel2 = sel_registerName("registerSiriVocabularyIfNeeded");
            IMP noopImp = imp_implementationWithBlock(^(id self) {});

            for (unsigned int i = 0; i < classCount; i++) {
                Class cls = classes[i];
                Method m1 = class_getInstanceMethod(cls, sel1);
                if (m1) {
                    method_setImplementation(m1, noopImp);
                }
                Method m2 = class_getInstanceMethod(cls, sel2);
                if (m2) {
                    method_setImplementation(m2, noopImp);
                }
            }
            free(classes);
        }
    }
}
