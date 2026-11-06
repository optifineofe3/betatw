#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import "Constants.h"
#import "Headers.h"

static inline BOOL shouldFixFilePicker(void) {
    return WATweakGetBool(FILE_PICKER_FIX_KEY, YES);
}

static NSURL *copyURLToSandbox(NSURL *url) {
    if (!url) return nil;
    if ([url.path containsString:FILE_PICKER_PATH]) return url;

    NSString *customFolderName = [NSString stringWithFormat:@"watweak-%@", [[NSUUID UUID] UUIDString]];
    NSString *uglyHackPath = [NSTemporaryDirectory() stringByAppendingPathComponent:FILE_PICKER_PATH];
    NSString *ourPath = [uglyHackPath stringByAppendingPathComponent:customFolderName];

    NSFileManager *manager = [NSFileManager defaultManager];
    if (![manager fileExistsAtPath:ourPath]) {
        [manager createDirectoryAtPath:ourPath withIntermediateDirectories:YES attributes:nil error:nil];
    }

    NSString *fileName = [url lastPathComponent];
    if (!fileName || fileName.length == 0) {
        fileName = @"media_file";
    }
    NSString *destPath = [ourPath stringByAppendingPathComponent:fileName];
    NSURL *destURL = [NSURL fileURLWithPath:destPath];

    NSError *err = nil;
    if ([manager fileExistsAtPath:destPath]) {
        [manager removeItemAtPath:destPath error:nil];
    }
    BOOL copied = [manager copyItemAtURL:url toURL:destURL error:&err];
    if (!copied) {
        // Fallback to reading and writing data
        NSData *data = [NSData dataWithContentsOfURL:url];
        if (data) {
            [data writeToURL:destURL atomically:YES];
        } else {
            return url;
        }
    }
    return destURL;
}

static void (*orig_didPickDocumentsAtURLs)(id, SEL, id, NSArray<NSURL *> *) = NULL;
static void watweak_didPickDocumentsAtURLs(id self, SEL _cmd, id picker, NSArray<NSURL *> *urls) {
    if (!shouldFixFilePicker()) {
        if (orig_didPickDocumentsAtURLs) {
            orig_didPickDocumentsAtURLs(self, _cmd, picker, urls);
        }
        return;
    }

    NSMutableArray<NSURL *> *sandboxedURLs = [NSMutableArray array];
    for (NSURL *u in urls) {
        NSURL *copied = copyURLToSandbox(u);
        if (copied) {
            [sandboxedURLs addObject:copied];
        }
    }

    if (orig_didPickDocumentsAtURLs) {
        orig_didPickDocumentsAtURLs(self, _cmd, picker, sandboxedURLs.count > 0 ? sandboxedURLs : urls);
    }
}

static void (*orig_didPickDocumentAtURL)(id, SEL, id, NSURL *) = NULL;
static void watweak_didPickDocumentAtURL(id self, SEL _cmd, id picker, NSURL *url) {
    if (!shouldFixFilePicker()) {
        if (orig_didPickDocumentAtURL) {
            orig_didPickDocumentAtURL(self, _cmd, picker, url);
        }
        return;
    }

    NSURL *copied = copyURLToSandbox(url);
    if (orig_didPickDocumentAtURL) {
        orig_didPickDocumentAtURL(self, _cmd, picker, copied ?: url);
    }
}

static void swizzleDelegateClassIfNeeded(Class cls) {
    if (!cls) return;
    static NSMutableSet *swizzledClasses = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        swizzledClasses = [NSMutableSet set];
    });

    NSString *clsName = NSStringFromClass(cls);
    if ([swizzledClasses containsObject:clsName]) return;
    [swizzledClasses addObject:clsName];

    SEL selURLs = @selector(documentPicker:didPickDocumentsAtURLs:);
    Method mURLs = class_getInstanceMethod(cls, selURLs);
    if (mURLs) {
        orig_didPickDocumentsAtURLs = (void (*)(id, SEL, id, NSArray<NSURL *> *))method_getImplementation(mURLs);
        method_setImplementation(mURLs, (IMP)watweak_didPickDocumentsAtURLs);
    }

    SEL selURL = @selector(documentPicker:didPickDocumentAtURL:);
    Method mURL = class_getInstanceMethod(cls, selURL);
    if (mURL) {
        orig_didPickDocumentAtURL = (void (*)(id, SEL, id, NSURL *))method_getImplementation(mURL);
        method_setImplementation(mURL, (IMP)watweak_didPickDocumentAtURL);
    }
}

static void (*orig_didFinishPickingMediaWithInfo)(id, SEL, id, NSDictionary *) = NULL;
static void watweak_didFinishPickingMediaWithInfo(id self, SEL _cmd, id picker, NSDictionary *info) {
    if (!shouldFixFilePicker() || !info) {
        if (orig_didFinishPickingMediaWithInfo) {
            orig_didFinishPickingMediaWithInfo(self, _cmd, picker, info);
        }
        return;
    }

    NSMutableDictionary *mutInfo = [info mutableCopy];
    for (NSString *key in @[@"UIImagePickerControllerImageURL", @"UIImagePickerControllerMediaURL", @"UIImagePickerControllerReferenceURL"]) {
        id val = info[key];
        if ([val isKindOfClass:[NSURL class]]) {
            NSURL *copied = copyURLToSandbox((NSURL *)val);
            if (copied) {
                mutInfo[key] = copied;
            }
        }
    }

    if (orig_didFinishPickingMediaWithInfo) {
        orig_didFinishPickingMediaWithInfo(self, _cmd, picker, [mutInfo copy]);
    }
}

static void swizzleImagePickerDelegateClassIfNeeded(Class cls) {
    if (!cls) return;
    static NSMutableSet *swizzledImageClasses = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        swizzledImageClasses = [NSMutableSet set];
    });

    NSString *clsName = NSStringFromClass(cls);
    if ([swizzledImageClasses containsObject:clsName]) return;
    [swizzledImageClasses addObject:clsName];

    SEL sel = @selector(imagePickerController:didFinishPickingMediaWithInfo:);
    Method m = class_getInstanceMethod(cls, sel);
    if (m) {
        orig_didFinishPickingMediaWithInfo = (void (*)(id, SEL, id, NSDictionary *))method_getImplementation(m);
        method_setImplementation(m, (IMP)watweak_didFinishPickingMediaWithInfo);
    }
}

%hook UIDocumentPickerViewController

- (id)initForOpeningContentTypes:(id)types asCopy:(BOOL)copy {
    if (!shouldFixFilePicker()) {
        return %orig;
    }
    return %orig(types, YES);
}

- (id)initWithDocumentTypes:(id)types inMode:(NSUInteger)mode {
    if (!shouldFixFilePicker()) {
        return %orig;
    }
    return %orig(types, 0); // UIDocumentPickerModeImport (copy mode)
}

- (void)setDelegate:(id<UIDocumentPickerDelegate>)delegate {
    if (delegate && shouldFixFilePicker()) {
        swizzleDelegateClassIfNeeded([(id)delegate class]);
    }
    %orig;
}

%end

%hook UIImagePickerController

- (void)setDelegate:(id<UINavigationControllerDelegate, UIImagePickerControllerDelegate>)delegate {
    if (delegate && shouldFixFilePicker()) {
        swizzleImagePickerDelegateClassIfNeeded([(id)delegate class]);
    }
    %orig;
}

%end

%hook NSURL

- (BOOL)startAccessingSecurityScopedResource {
    if (!shouldFixFilePicker()) {
        return %orig;
    }

    if ([self isFileURL]) {
        NSString *p = self.path;
        if (p && [[NSFileManager defaultManager] fileExistsAtPath:p]) {
            return YES;
        }
    }
    return %orig;
}

- (void)stopAccessingSecurityScopedResource {
    if (!shouldFixFilePicker()) {
        %orig;
        return;
    }
    if ([self isFileURL]) {
        return;
    }
    %orig;
}

%end

%ctor {
    @autoreleasepool {
        %init;
    }
}
