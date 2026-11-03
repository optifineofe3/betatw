#import "MediaSaver.h"
#import <Photos/Photos.h>
#import <AVFoundation/AVFoundation.h>
#import <objc/runtime.h>

@interface MediaSaverButton : UIButton
@property (nonatomic, weak) UIViewController *targetController;
@end

@implementation MediaSaverButton
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    CGRect expanded = CGRectInset(self.bounds, -12.0, -12.0);
    return CGRectContainsPoint(expanded, point);
}
@end

@implementation MediaSaver

+ (instancetype)shared {
    static MediaSaver *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[MediaSaver alloc] init];
    });
    return instance;
}

static UIImage *downloadIconImage(void) {
    static UIImage *icon = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (@available(iOS 13.0, *)) {
            UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:17 weight:UIImageSymbolWeightBold];
            icon = [UIImage systemImageNamed:@"arrow.down.to.line" withConfiguration:config];
            if (icon) {
                icon = [icon imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                return;
            }
        }
        
        CGSize size = CGSizeMake(24, 24);
        UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);
        [[UIColor whiteColor] setStroke];
        
        UIBezierPath *stem = [UIBezierPath bezierPath];
        [stem moveToPoint:CGPointMake(12, 3)];
        [stem addLineToPoint:CGPointMake(12, 14)];
        stem.lineWidth = 2.5;
        stem.lineCapStyle = kCGLineCapRound;
        [stem stroke];
        
        UIBezierPath *head = [UIBezierPath bezierPath];
        [head moveToPoint:CGPointMake(7, 10)];
        [head addLineToPoint:CGPointMake(12, 15)];
        [head addLineToPoint:CGPointMake(17, 10)];
        head.lineWidth = 2.5;
        head.lineCapStyle = kCGLineCapRound;
        head.lineJoinStyle = kCGLineJoinRound;
        [head stroke];
        
        UIBezierPath *tray = [UIBezierPath bezierPath];
        [tray moveToPoint:CGPointMake(5, 20)];
        [tray addLineToPoint:CGPointMake(19, 20)];
        tray.lineWidth = 2.5;
        tray.lineCapStyle = kCGLineCapRound;
        [tray stroke];
        
        icon = [UIGraphicsGetImageFromCurrentImageContext() imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        UIGraphicsEndImageContext();
    });
    return icon;
}

+ (BOOL)isMediaViewerController:(UIViewController *)controller {
    if (!controller) return NO;
    NSString *cls = NSStringFromClass([controller class]);
    if ([cls containsString:@"ViewOnce"] ||
        [cls containsString:@"MediaBrowser"] ||
        [cls containsString:@"StatusViewer"] ||
        [cls containsString:@"PictureContainer"] ||
        [cls containsString:@"MediaViewer"] ||
        [cls containsString:@"PhotoViewController"] ||
        [cls containsString:@"VideoViewController"] ||
        [cls containsString:@"MediaContentDisplay"]) {
        return YES;
    }
    return NO;
}

+ (void)attachToController:(UIViewController *)controller {
    if (!controller || !controller.isViewLoaded) return;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!controller || !controller.isViewLoaded) return;
        
        UIView *view = controller.view;
        if (!view) return;
        
        // Check if already added
        UIView *existingBtn = [view viewWithTag:998811];
        if (existingBtn) {
            existingBtn.hidden = NO;
            existingBtn.alpha = 1.0;
            existingBtn.layer.zPosition = 999999;
            [view bringSubviewToFront:existingBtn];
            return;
        }
        
        CGFloat btnSize = 46.0;
        CGRect bounds = view.bounds;
        if (bounds.size.width < 50 || bounds.size.height < 50) {
            bounds = [UIScreen mainScreen].bounds;
        }
        
        CGFloat bottomMargin = 60.0;
        if (@available(iOS 11.0, *)) {
            if (view.safeAreaInsets.bottom > 0) {
                bottomMargin = view.safeAreaInsets.bottom + 20.0;
            }
        }
        
        CGRect initialFrame = CGRectMake(bounds.size.width - btnSize - 18.0,
                                         bounds.size.height - bottomMargin - btnSize,
                                         btnSize,
                                         btnSize);
        
        MediaSaverButton *btn = [MediaSaverButton buttonWithType:UIButtonTypeCustom];
        btn.tag = 998811;
        btn.frame = initialFrame;
        btn.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
        btn.targetController = controller;
        btn.backgroundColor = [UIColor colorWithRed:0.08 green:0.08 blue:0.10 alpha:0.88];
        btn.tintColor = [UIColor whiteColor];
        btn.layer.cornerRadius = btnSize / 2.0;
        btn.layer.shadowColor = [UIColor blackColor].CGColor;
        btn.layer.shadowOpacity = 0.45;
        btn.layer.shadowOffset = CGSizeMake(0, 3);
        btn.layer.shadowRadius = 6.0;
        btn.layer.zPosition = 999999;
        btn.clipsToBounds = NO;
        
        [btn setImage:downloadIconImage() forState:UIControlStateNormal];
        [btn addTarget:[MediaSaver shared] action:@selector(handleButtonTap:) forControlEvents:UIControlEventTouchUpInside];
        
        btn.alpha = 0.0;
        btn.transform = CGAffineTransformMakeScale(0.85, 0.85);
        
        [view addSubview:btn];
        [view bringSubviewToFront:btn];
        
        [UIView animateWithDuration:0.25 delay:0.05 options:UIViewAnimationOptionCurveEaseOut animations:^{
            btn.alpha = 1.0;
            btn.transform = CGAffineTransformIdentity;
        } completion:nil];
    });
}

+ (void)detachFromController:(UIViewController *)controller animated:(BOOL)animated {
    if (!controller || !controller.isViewLoaded) return;
    UIView *btn = [controller.view viewWithTag:998811];
    if (!btn) return;
    
    if (animated) {
        [UIView animateWithDuration:0.15 animations:^{
            btn.alpha = 0.0;
            btn.transform = CGAffineTransformMakeScale(0.85, 0.85);
        } completion:^(BOOL finished) {
            [btn removeFromSuperview];
        }];
    } else {
        [btn removeFromSuperview];
    }
}

- (void)handleButtonTap:(id)sender {
    MediaSaverButton *btn = (MediaSaverButton *)sender;
    UIViewController *ctrl = btn.targetController;
    if (!ctrl) {
        UIResponder *r = btn;
        while (r && ![r isKindOfClass:[UIViewController class]]) {
            r = r.nextResponder;
        }
        ctrl = (UIViewController *)r;
    }
    
    UIImpactFeedbackGenerator *feedback = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
    [feedback impactOccurred];
    
    if (ctrl) {
        [MediaSaver saveMediaFromController:ctrl];
    }
}

static id safeInvokeGetter(id obj, NSString *selectorName) {
    if (!obj || !selectorName) return nil;
    SEL sel = NSSelectorFromString(selectorName);
    if ([obj respondsToSelector:sel]) {
        IMP imp = [obj methodForSelector:sel];
        id (*func)(id, SEL) = (id (*)(id, SEL))imp;
        return func(obj, sel);
    }
    return nil;
}

static NSString *extractPathFromPlayerLayer(CALayer *layer) {
    if (!layer) return nil;
    @try {
        id player = safeInvokeGetter(layer, @"player");
        if (player) {
            id item = safeInvokeGetter(player, @"currentItem");
            if (item) {
                id asset = safeInvokeGetter(item, @"asset");
                if (asset) {
                    id urlObj = safeInvokeGetter(asset, @"URL");
                    if (urlObj && [urlObj isKindOfClass:[NSURL class]]) {
                        NSURL *url = (NSURL *)urlObj;
                        if (url.isFileURL && url.path) {
                            return url.path;
                        }
                    }
                }
            }
        }
    } @catch (NSException *e) {}
    return nil;
}

static NSString *findVideoPathInView(UIView *view) {
    if (!view) return nil;
    
    NSString *path = extractPathFromPlayerLayer(view.layer);
    if (path && [[NSFileManager defaultManager] fileExistsAtPath:path]) return path;
    
    for (CALayer *sub in view.layer.sublayers) {
        path = extractPathFromPlayerLayer(sub);
        if (path && [[NSFileManager defaultManager] fileExistsAtPath:path]) return path;
    }
    
    for (UIView *subview in view.subviews) {
        path = findVideoPathInView(subview);
        if (path) return path;
    }
    return nil;
}

static void scanViewsRecursively(UIView *v, void (^imageBlock)(UIImage *), void (^layerBlock)(CGImageRef)) {
    if (!v) return;
    if ([v isKindOfClass:[UIImageView class]]) {
        UIImage *img = [(UIImageView *)v image];
        if (img) imageBlock(img);
    }
    if (v.layer && v.layer.contents) {
        id contents = v.layer.contents;
        if (CFGetTypeID((__bridge CFTypeRef)contents) == CGImageGetTypeID()) {
            layerBlock((__bridge CGImageRef)contents);
        }
    }
    for (UIView *sub in v.subviews) {
        scanViewsRecursively(sub, imageBlock, layerBlock);
    }
}

+ (UIImage *)findImageInView:(UIView *)view {
    if (!view) return nil;
    
    __block UIImage *largestImage = nil;
    __block size_t largestArea = 0;
    
    void (^checkImage)(UIImage *) = ^(UIImage *img) {
        if (!img) return;
        size_t area = (size_t)(img.size.width * img.size.height * (img.scale > 0 ? img.scale : 1.0));
        if (area > largestArea && img.size.width >= 50 && img.size.height >= 50) {
            largestArea = area;
            largestImage = img;
        }
    };
    
    void (^checkLayerContents)(CGImageRef) = ^(CGImageRef cg) {
        if (!cg) return;
        size_t w = CGImageGetWidth(cg);
        size_t h = CGImageGetHeight(cg);
        if (w * h > largestArea && w >= 50 && h >= 50) {
            largestArea = w * h;
            largestImage = [UIImage imageWithCGImage:cg scale:[UIScreen mainScreen].scale orientation:UIImageOrientationUp];
        }
    };
    
    scanViewsRecursively(view, checkImage, checkLayerContents);
    return largestImage;
}

+ (UIImage *)snapshotView:(UIView *)view {
    if (!view) return nil;
    CGSize size = view.bounds.size;
    if (size.width <= 10 || size.height <= 10) return nil;
    
    UIImage *snap = nil;
    @try {
        UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);
        [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:NO];
        snap = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    } @catch (NSException *e) {}
    return snap;
}

static NSString *resolveExistingFilePath(NSString *rawPath) {
    if (!rawPath || ![rawPath isKindOfClass:[NSString class]] || rawPath.length == 0) return nil;
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:rawPath]) return rawPath;
    
    // Check Documents directory
    NSString *docs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    if (docs) {
        NSString *cand = [docs stringByAppendingPathComponent:rawPath];
        if ([fm fileExistsAtPath:cand]) return cand;
    }
    // Check Library directory
    NSString *lib = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES).firstObject;
    if (lib) {
        NSString *cand = [lib stringByAppendingPathComponent:rawPath];
        if ([fm fileExistsAtPath:cand]) return cand;
    }
    // Check tmp directory
    NSString *tmp = NSTemporaryDirectory();
    if (tmp) {
        NSString *cand = [tmp stringByAppendingPathComponent:rawPath];
        if ([fm fileExistsAtPath:cand]) return cand;
        NSString *lastComp = [rawPath lastPathComponent];
        cand = [tmp stringByAppendingPathComponent:lastComp];
        if ([fm fileExistsAtPath:cand]) return cand;
    }
    return nil;
}

static id findMessageInController(UIViewController *ctrl) {
    if (!ctrl) return nil;
    for (NSString *sel in @[@"message", @"lastVisibleMessageMedia"]) {
        id msg = safeInvokeGetter(ctrl, sel);
        if (msg) return msg;
    }
    if (ctrl.parentViewController) {
        for (NSString *sel in @[@"message", @"lastVisibleMessageMedia"]) {
            id msg = safeInvokeGetter(ctrl.parentViewController, sel);
            if (msg) return msg;
        }
    }
    for (UIViewController *child in ctrl.childViewControllers) {
        for (NSString *sel in @[@"message", @"lastVisibleMessageMedia"]) {
            id msg = safeInvokeGetter(child, sel);
            if (msg) return msg;
        }
    }
    return nil;
}

static id findMediaInController(UIViewController *ctrl) {
    if (!ctrl) return nil;
    for (NSString *sel in @[@"currentMedia", @"_currentMediaBeforeReload", @"_initialMedia", @"initialMedia", @"media", @"lastVisibleMessageMedia"]) {
        id m = safeInvokeGetter(ctrl, sel);
        if (m) return m;
    }
    if (ctrl.parentViewController) {
        for (NSString *sel in @[@"currentMedia", @"_currentMediaBeforeReload", @"_initialMedia", @"initialMedia", @"media", @"lastVisibleMessageMedia"]) {
            id m = safeInvokeGetter(ctrl.parentViewController, sel);
            if (m) return m;
        }
    }
    for (UIViewController *child in ctrl.childViewControllers) {
        for (NSString *sel in @[@"currentMedia", @"_currentMediaBeforeReload", @"_initialMedia", @"initialMedia", @"media", @"lastVisibleMessageMedia"]) {
            id m = safeInvokeGetter(child, sel);
            if (m) return m;
        }
    }
    return nil;
}

+ (void)saveMediaFromController:(UIViewController *)controller {
    if (!controller || !controller.isViewLoaded) {
        [self showToast:@"Unable to find media" success:NO];
        return;
    }
    
    // 0. Check message and media item directly (View-Once & chat messages)
    @try {
        id msg = findMessageInController(controller);
        if (msg) {
            id mi = safeInvokeGetter(msg, @"mediaItem");
            if (mi) {
                for (NSString *sel in @[@"mediaLocalPath", @"fullPath", @"path", @"filePath"]) {
                    id pathObj = safeInvokeGetter(mi, sel);
                    NSString *resolved = resolveExistingFilePath(pathObj);
                    if (resolved) {
                        NSString *ext = [[resolved pathExtension] lowercaseString];
                        if ([ext isEqualToString:@"mp4"] || [ext isEqualToString:@"mov"] || [ext isEqualToString:@"m4v"]) {
                            [self saveVideoToPhotos:resolved];
                            return;
                        } else if ([ext isEqualToString:@"jpg"] || [ext isEqualToString:@"jpeg"] || [ext isEqualToString:@"png"]) {
                            UIImage *img = [UIImage imageWithContentsOfFile:resolved];
                            if (img) {
                                [self saveImageToPhotos:img];
                                return;
                            }
                        }
                    }
                }
            }
        }
        
        // 0b. Check media object in browser controllers
        id media = findMediaInController(controller);
        if (media) {
            for (NSString *sel in @[@"mediaLocalPath", @"fullPath", @"path", @"filePath"]) {
                id pathObj = safeInvokeGetter(media, sel);
                NSString *resolved = resolveExistingFilePath(pathObj);
                if (resolved) {
                    NSString *ext = [[resolved pathExtension] lowercaseString];
                    if ([ext isEqualToString:@"mp4"] || [ext isEqualToString:@"mov"] || [ext isEqualToString:@"m4v"]) {
                        [self saveVideoToPhotos:resolved];
                        return;
                    } else if ([ext isEqualToString:@"jpg"] || [ext isEqualToString:@"jpeg"] || [ext isEqualToString:@"png"]) {
                        UIImage *img = [UIImage imageWithContentsOfFile:resolved];
                        if (img) {
                            [self saveImageToPhotos:img];
                            return;
                        }
                    }
                }
            }
            id imgObj = safeInvokeGetter(media, @"image");
            if ([imgObj isKindOfClass:[UIImage class]]) {
                [self saveImageToPhotos:(UIImage *)imgObj];
                return;
            }
        }
    } @catch (NSException *e) {}
    
    // 1. Try finding video first in view hierarchy
    NSString *videoPath = findVideoPathInView(controller.view);
    NSString *resolvedVideo = resolveExistingFilePath(videoPath);
    if (resolvedVideo) {
        [self saveVideoToPhotos:resolvedVideo];
        return;
    }
    
    // 2. Try finding image in view hierarchy
    UIImage *image = [self findImageInView:controller.view];
    if (image) {
        [self saveImageToPhotos:image];
        return;
    }
    
    // 3. Fallback: snapshot view
    UIImage *snap = [self snapshotView:controller.view];
    if (snap) {
        [self saveImageToPhotos:snap];
        return;
    }
    
    [self showToast:@"Unable to extract media" success:NO];
}

+ (void)saveImageToPhotos:(UIImage *)image {
    if (!image) {
        [self showToast:@"No image found" success:NO];
        return;
    }
    
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        if (status == PHAuthorizationStatusAuthorized || status == PHAuthorizationStatusLimited) {
            [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                [PHAssetChangeRequest creationRequestForAssetFromImage:image];
            } completionHandler:^(BOOL success, NSError * _Nullable error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (success) {
                        [MediaSaver showToast:@"Photo saved to Camera Roll" success:YES];
                    } else {
                        [MediaSaver showToast:@"Failed to save photo" success:NO];
                    }
                });
            }];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [MediaSaver showToast:@"Photo Library permission denied" success:NO];
            });
        }
    }];
}

+ (void)saveVideoToPhotos:(NSString *)videoPath {
    if (!videoPath || ![[NSFileManager defaultManager] fileExistsAtPath:videoPath]) {
        [self showToast:@"Video file not found" success:NO];
        return;
    }
    
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        if (status == PHAuthorizationStatusAuthorized || status == PHAuthorizationStatusLimited) {
            [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:[NSURL fileURLWithPath:videoPath]];
            } completionHandler:^(BOOL success, NSError * _Nullable error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (success) {
                        [MediaSaver showToast:@"Video saved to Camera Roll" success:YES];
                    } else {
                        [MediaSaver showToast:@"Failed to save video" success:NO];
                    }
                });
            }];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [MediaSaver showToast:@"Photo Library permission denied" success:NO];
            });
        }
    }];
}

+ (void)showToast:(NSString *)message success:(BOOL)success {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *window = nil;
        for (UIWindow *w in [UIApplication sharedApplication].windows) {
            if (w.isKeyWindow) { window = w; break; }
        }
        if (!window && [UIApplication sharedApplication].windows.count > 0) {
            window = [UIApplication sharedApplication].windows.firstObject;
        }
        if (!window) return;
        
        UIView *existing = [window viewWithTag:998899];
        if (existing) [existing removeFromSuperview];
        
        UIView *toast = [[UIView alloc] init];
        toast.tag = 998899;
        toast.backgroundColor = [UIColor colorWithRed:0.08 green:0.08 blue:0.10 alpha:0.94];
        toast.layer.cornerRadius = 18.0;
        toast.clipsToBounds = YES;
        toast.layer.zPosition = 99999;
        toast.translatesAutoresizingMaskIntoConstraints = NO;
        
        UIImageView *iconView = [[UIImageView alloc] init];
        iconView.translatesAutoresizingMaskIntoConstraints = NO;
        iconView.tintColor = success ? [UIColor colorWithRed:0.20 green:0.80 blue:0.40 alpha:1.0] : [UIColor colorWithRed:1.0 green:0.35 blue:0.35 alpha:1.0];
        
        if (@available(iOS 13.0, *)) {
            NSString *iconName = success ? @"checkmark.circle.fill" : @"xmark.circle.fill";
            iconView.image = [UIImage systemImageNamed:iconName];
        }
        
        UILabel *label = [[UILabel alloc] init];
        label.translatesAutoresizingMaskIntoConstraints = NO;
        label.text = message;
        label.textColor = [UIColor whiteColor];
        label.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
        label.numberOfLines = 1;
        
        [toast addSubview:iconView];
        [toast addSubview:label];
        [window addSubview:toast];
        
        [NSLayoutConstraint activateConstraints:@[
            [toast.topAnchor constraintEqualToAnchor:window.safeAreaLayoutGuide.topAnchor constant:12],
            [toast.centerXAnchor constraintEqualToAnchor:window.centerXAnchor],
            [toast.heightAnchor constraintEqualToConstant:36],
            
            [iconView.leadingAnchor constraintEqualToAnchor:toast.leadingAnchor constant:12],
            [iconView.centerYAnchor constraintEqualToAnchor:toast.centerYAnchor],
            [iconView.widthAnchor constraintEqualToConstant:20],
            [iconView.heightAnchor constraintEqualToConstant:20],
            
            [label.leadingAnchor constraintEqualToAnchor:iconView.trailingAnchor constant:8],
            [label.trailingAnchor constraintEqualToAnchor:toast.trailingAnchor constant:-14],
            [label.centerYAnchor constraintEqualToAnchor:toast.centerYAnchor]
        ]];
        
        toast.alpha = 0.0;
        toast.transform = CGAffineTransformMakeTranslation(0, -15);
        
        [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            toast.alpha = 1.0;
            toast.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.3 delay:2.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
                toast.alpha = 0.0;
                toast.transform = CGAffineTransformMakeTranslation(0, -15);
            } completion:^(BOOL fin) {
                [toast removeFromSuperview];
            }];
        }];
    });
}

@end
