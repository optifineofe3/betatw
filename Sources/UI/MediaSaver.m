#import "MediaSaver.h"
#import <Photos/Photos.h>
#import <AVFoundation/AVFoundation.h>
#import <objc/runtime.h>

@interface NSObject (MediaSaverVideoCheck)
- (BOOL)isVideo;
- (NSUInteger)messageType;
@end

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
    if ([cls containsString:@"Picker"] ||
        [cls containsString:@"Camera"] ||
        [cls containsString:@"Document"] ||
        [cls containsString:@"Contact"] ||
        [cls containsString:@"Poll"] ||
        [cls containsString:@"Sheet"] ||
        [cls containsString:@"Alert"]) {
        return NO;
    }
    if ([cls containsString:@"ViewOnce"] ||
        [cls containsString:@"MediaBrowser"] ||
        [cls containsString:@"StatusViewer"] ||
        [cls containsString:@"PictureContainer"] ||
        [cls containsString:@"MediaViewer"] ||
        [cls containsString:@"MediaContentDisplay"]) {
        return YES;
    }
    return NO;
}

+ (void)attachToController:(UIViewController *)controller {
    if (!controller || !controller.isViewLoaded) return;
    if (![self isMediaViewerController:controller]) return;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!controller || !controller.isViewLoaded) return;
        if (![self isMediaViewerController:controller]) return;
        
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
        
        CGFloat btnSize = 42.0;
        CGRect bounds = view.bounds;
        if (bounds.size.width < 50 || bounds.size.height < 50) {
            bounds = [UIScreen mainScreen].bounds;
        }
        
        CGFloat bottomMargin = 120.0;
        if (@available(iOS 11.0, *)) {
            if (view.safeAreaInsets.bottom > 0) {
                bottomMargin = view.safeAreaInsets.bottom + 85.0;
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
        btn.backgroundColor = [UIColor colorWithRed:0.06 green:0.06 blue:0.08 alpha:0.90];
        btn.tintColor = [UIColor whiteColor];
        btn.layer.cornerRadius = 21.0;
        btn.layer.borderWidth = 0.0;
        btn.layer.borderColor = nil;
        btn.layer.shadowColor = [UIColor blackColor].CGColor;
        btn.layer.shadowOpacity = 0.40;
        btn.layer.shadowOffset = CGSizeMake(0, 2);
        btn.layer.shadowRadius = 6.0;
        btn.layer.zPosition = 999999;
        btn.clipsToBounds = NO;
        
        [btn setImage:downloadIconImage() forState:UIControlStateNormal];
        [btn addTarget:[MediaSaver shared] action:@selector(handleButtonTap:) forControlEvents:UIControlEventTouchUpInside];
        
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:[MediaSaver shared] action:@selector(handleButtonPan:)];
        pan.maximumNumberOfTouches = 1;
        [btn addGestureRecognizer:pan];
        
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
    UIView *btn = [controller.view viewWithTag:998811] ?: [controller.view.window viewWithTag:998811];
    if (!btn) return;
    
    if (btn.alpha <= 0.05) {
        [btn removeFromSuperview];
        return;
    }
    
    if (animated) {
        [UIView animateWithDuration:0.20 delay:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
            btn.alpha = 0.0;
            btn.transform = CGAffineTransformMakeScale(0.85, 0.85);
        } completion:^(BOOL finished) {
            [btn removeFromSuperview];
        }];
    } else {
        btn.alpha = 0.0;
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

- (void)handleButtonPan:(UIPanGestureRecognizer *)pan {
    UIView *btn = pan.view;
    if (!btn || !btn.superview) return;
    
    if (pan.state == UIGestureRecognizerStateBegan) {
        [UIView animateWithDuration:0.15 animations:^{
            btn.transform = CGAffineTransformMakeScale(1.08, 1.08);
        }];
    }
    
    CGPoint translation = [pan translationInView:btn.superview];
    CGPoint newCenter = CGPointMake(btn.center.x + translation.x, btn.center.y + translation.y);
    
    CGRect bounds = btn.superview.bounds;
    CGFloat halfW = btn.bounds.size.width / 2.0;
    CGFloat halfH = btn.bounds.size.height / 2.0;
    CGFloat minX = halfW + 10.0;
    CGFloat maxX = bounds.size.width - halfW - 10.0;
    CGFloat minY = halfH + 44.0;
    CGFloat maxY = bounds.size.height - halfH - 25.0;
    
    newCenter.x = MAX(minX, MIN(maxX, newCenter.x));
    newCenter.y = MAX(minY, MIN(maxY, newCenter.y));
    
    btn.center = newCenter;
    [pan setTranslation:CGPointZero inView:btn.superview];
    
    if (pan.state == UIGestureRecognizerStateEnded || pan.state == UIGestureRecognizerStateCancelled) {
        [UIView animateWithDuration:0.15 animations:^{
            btn.transform = CGAffineTransformIdentity;
        }];
    }
}

static id safeInvokeGetter(id obj, NSString *selectorName) {
    if (!obj || !selectorName) return nil;
    if ((uintptr_t)obj < 0x10000) return nil;
    @try {
        SEL sel = NSSelectorFromString(selectorName);
        if (![obj respondsToSelector:sel]) return nil;
        NSMethodSignature *sig = [obj methodSignatureForSelector:sel];
        if (!sig || [sig numberOfArguments] != 2) return nil;
        const char *retType = [sig methodReturnType];
        if (!retType || retType[0] != '@') return nil;
        
        NSInvocation *inv = [NSInvocation invocationWithMethodSignature:sig];
        [inv setTarget:obj];
        [inv setSelector:sel];
        [inv invoke];
        void *retVal = NULL;
        [inv getReturnValue:&retVal];
        if (!retVal || (uintptr_t)retVal < 0x10000) return nil;
        return (__bridge id)retVal;
    } @catch (NSException *e) {
        return nil;
    }
}

static BOOL safeInvokeBool(id obj, NSString *selectorName) {
    if (!obj || !selectorName) return NO;
    if ((uintptr_t)obj < 0x10000) return NO;
    @try {
        SEL sel = NSSelectorFromString(selectorName);
        if (![obj respondsToSelector:sel]) return NO;
        NSMethodSignature *sig = [obj methodSignatureForSelector:sel];
        if (!sig || [sig numberOfArguments] != 2) return NO;
        const char *retType = [sig methodReturnType];
        if (!retType) return NO;
        if (retType[0] == 'c' || retType[0] == 'B' || retType[0] == 'i' || retType[0] == 'q' || retType[0] == 's') {
            NSInvocation *inv = [NSInvocation invocationWithMethodSignature:sig];
            [inv setTarget:obj];
            [inv setSelector:sel];
            [inv invoke];
            long long val = 0;
            [inv getReturnValue:&val];
            return val != 0;
        }
        return NO;
    } @catch (NSException *e) {
        return NO;
    }
}

static NSUInteger safeInvokeInteger(id obj, NSString *selectorName) {
    if (!obj || !selectorName) return 0;
    if ((uintptr_t)obj < 0x10000) return 0;
    @try {
        SEL sel = NSSelectorFromString(selectorName);
        if (![obj respondsToSelector:sel]) return 0;
        NSMethodSignature *sig = [obj methodSignatureForSelector:sel];
        if (!sig || [sig numberOfArguments] != 2) return 0;
        const char *retType = [sig methodReturnType];
        if (!retType) return 0;
        if (retType[0] == 'i' || retType[0] == 'q' || retType[0] == 'I' || retType[0] == 'Q' || retType[0] == 'l' || retType[0] == 'L' || retType[0] == 's' || retType[0] == 'c' || retType[0] == 'B') {
            NSInvocation *inv = [NSInvocation invocationWithMethodSignature:sig];
            [inv setTarget:obj];
            [inv setSelector:sel];
            [inv invoke];
            NSUInteger val = 0;
            [inv getReturnValue:&val];
            return val;
        }
        return 0;
    } @catch (NSException *e) {
        return 0;
    }
}

NSDate *watweak_safeGetDate(id obj, SEL sel) {
    if (!obj || !sel) return nil;
    if ((uintptr_t)obj < 0x10000) return nil;
    @try {
        if (![obj respondsToSelector:sel]) return nil;
        NSMethodSignature *sig = [obj methodSignatureForSelector:sel];
        if (!sig || [sig numberOfArguments] != 2) return nil;
        const char *retType = [sig methodReturnType];
        if (!retType) return nil;
        
        NSInvocation *inv = [NSInvocation invocationWithMethodSignature:sig];
        [inv setTarget:obj];
        [inv setSelector:sel];
        [inv invoke];
        
        char t = retType[0];
        if (t == '@') {
            void *retVal = NULL;
            [inv getReturnValue:&retVal];
            if (!retVal || (uintptr_t)retVal < 0x10000) return nil;
            id objRet = (__bridge id)retVal;
            if ([objRet isKindOfClass:[NSDate class]]) {
                return (NSDate *)objRet;
            } else if ([objRet isKindOfClass:[NSNumber class]]) {
                double val = [(NSNumber *)objRet doubleValue];
                if (val > 0.0) {
                    if (val > 1000000000000.0) val /= 1000.0;
                    return [NSDate dateWithTimeIntervalSince1970:val];
                }
            }
            return nil;
        } else if (t == 'd') {
            double val = 0.0;
            [inv getReturnValue:&val];
            if (val > 0.0) {
                if (val > 1000000000000.0) val /= 1000.0;
                return [NSDate dateWithTimeIntervalSince1970:val];
            }
        } else if (t == 'f') {
            float val = 0.0f;
            [inv getReturnValue:&val];
            if (val > 0.0f) {
                return [NSDate dateWithTimeIntervalSince1970:(double)val];
            }
        } else if (t == 'q' || t == 'Q' || t == 'i' || t == 'I' || t == 'l' || t == 'L') {
            long long val = 0;
            [inv getReturnValue:&val];
            if (val > 0) {
                double dVal = (double)val;
                if (dVal > 1000000000000.0) dVal /= 1000.0;
                return [NSDate dateWithTimeIntervalSince1970:dVal];
            }
        }
    } @catch (NSException *e) {}
    return nil;
}

NSString *watweak_safeGetString(id obj, SEL sel) {
    if (!obj || !sel) return nil;
    if ((uintptr_t)obj < 0x10000) return nil;
    @try {
        if (![obj respondsToSelector:sel]) return nil;
        NSMethodSignature *sig = [obj methodSignatureForSelector:sel];
        if (!sig || [sig numberOfArguments] != 2) return nil;
        const char *retType = [sig methodReturnType];
        if (!retType || retType[0] != '@') return nil;
        
        NSInvocation *inv = [NSInvocation invocationWithMethodSignature:sig];
        [inv setTarget:obj];
        [inv setSelector:sel];
        [inv invoke];
        void *retVal = NULL;
        [inv getReturnValue:&retVal];
        if (!retVal || (uintptr_t)retVal < 0x10000) return nil;
        id objRet = (__bridge id)retVal;
        if ([objRet isKindOfClass:[NSString class]]) {
            return (NSString *)objRet;
        }
    } @catch (NSException *e) {}
    return nil;
}

BOOL watweak_safeGetBool(id obj, SEL sel) {
    if (!obj || !sel) return NO;
    if ((uintptr_t)obj < 0x10000) return NO;
    @try {
        if (![obj respondsToSelector:sel]) return NO;
        NSMethodSignature *sig = [obj methodSignatureForSelector:sel];
        if (!sig || [sig numberOfArguments] != 2) return NO;
        const char *retType = [sig methodReturnType];
        if (!retType) return NO;
        
        char t = retType[0];
        if (t == 'c' || t == 'B' || t == 'i' || t == 'q' || t == 's' || t == 'I' || t == 'Q' || t == 'l' || t == 'L') {
            NSInvocation *inv = [NSInvocation invocationWithMethodSignature:sig];
            [inv setTarget:obj];
            [inv setSelector:sel];
            [inv invoke];
            long long val = 0;
            [inv getReturnValue:&val];
            return val != 0;
        } else if (t == '@') {
            NSInvocation *inv = [NSInvocation invocationWithMethodSignature:sig];
            [inv setTarget:obj];
            [inv setSelector:sel];
            [inv invoke];
            void *retVal = NULL;
            [inv getReturnValue:&retVal];
            if (!retVal || (uintptr_t)retVal < 0x10000) return NO;
            id objRet = (__bridge id)retVal;
            if ([objRet isKindOfClass:[NSNumber class]]) {
                return [(NSNumber *)objRet boolValue];
            }
            return objRet != nil;
        }
    } @catch (NSException *e) {}
    return NO;
}

static NSString *extractVideoPathFromAnyObject(id obj) {
    if (!obj) return nil;
    if ((uintptr_t)obj < 0x10000) return nil;
    
    @try {
        // Check known URL and path getters / properties
        NSArray *selectors = @[
            @"assetURL", @"_assetURL",
            @"cachedMediaActivityItemURL", @"_cachedMediaActivityItemURL",
            @"mediaFilePath", @"_mediaFilePath",
            @"plaintextFilePath", @"_plaintextFilePath",
            @"videoURL", @"fileURL", @"mediaURL", @"contentURL", @"streamingURL",
            @"wa_fileURL", @"mediaLocalPath", @"path", @"fullPath", @"filePath", @"originalMediaLocalPath"
        ];
        
        for (NSString *sel in selectors) {
            id val = safeInvokeGetter(obj, sel);
            if (!val) {
                @try { val = [obj valueForKey:sel]; } @catch (NSException *e) {}
            }
            if (val) {
                if ([val isKindOfClass:[NSURL class]]) {
                    NSURL *u = (NSURL *)val;
                    if (u.path) {
                        NSString *resolved = resolveExistingFilePath(u.path);
                        if (resolved) {
                            NSString *ext = [[resolved pathExtension] lowercaseString];
                            if ([ext isEqualToString:@"mp4"] || [ext isEqualToString:@"mov"] || [ext isEqualToString:@"m4v"]) {
                                return resolved;
                            }
                        }
                    }
                } else if ([val isKindOfClass:[NSString class]]) {
                    NSString *resolved = resolveExistingFilePath((NSString *)val);
                    if (resolved) {
                        NSString *ext = [[resolved pathExtension] lowercaseString];
                        if ([ext isEqualToString:@"mp4"] || [ext isEqualToString:@"mov"] || [ext isEqualToString:@"m4v"]) {
                            return resolved;
                        }
                    }
                }
            }
        }
        
        // Check AVAsset / AVURLAsset
        for (NSString *sel in @[@"asset", @"_asset"]) {
            id asset = safeInvokeGetter(obj, sel);
            if (!asset) {
                @try { asset = [obj valueForKey:sel]; } @catch (NSException *e) {}
            }
            if (asset && [asset isKindOfClass:[AVAsset class]]) {
                if ([asset isKindOfClass:[AVURLAsset class]]) {
                    NSURL *u = [(AVURLAsset *)asset URL];
                    if (u.path) {
                        NSString *resolved = resolveExistingFilePath(u.path);
                        if (resolved) return resolved;
                    }
                }
                id uObj = safeInvokeGetter(asset, @"URL");
                if (uObj && [uObj isKindOfClass:[NSURL class]]) {
                    NSString *resolved = resolveExistingFilePath(((NSURL *)uObj).path);
                    if (resolved) return resolved;
                }
            }
        }
        
        // Check AVPlayerItem
        for (NSString *sel in @[@"currentItem", @"playerItem", @"_playerItem"]) {
            id item = safeInvokeGetter(obj, sel);
            if (!item) {
                @try { item = [obj valueForKey:sel]; } @catch (NSException *e) {}
            }
            if (item && [item isKindOfClass:[AVPlayerItem class]]) {
                id asset = safeInvokeGetter(item, @"asset");
                if (asset) {
                    if ([asset isKindOfClass:[AVURLAsset class]]) {
                        NSURL *u = [(AVURLAsset *)asset URL];
                        if (u.path) {
                            NSString *resolved = resolveExistingFilePath(u.path);
                            if (resolved) return resolved;
                        }
                    }
                    id uObj = safeInvokeGetter(asset, @"URL");
                    if (uObj && [uObj isKindOfClass:[NSURL class]]) {
                        NSString *resolved = resolveExistingFilePath(((NSURL *)uObj).path);
                        if (resolved) return resolved;
                    }
                }
            }
        }
        
        // Check sub-player objects
        for (NSString *sel in @[@"mediaPlayer", @"_mediaPlayer", @"playerView", @"_playerView", @"player", @"_player", @"playbackController", @"videoPlayer"]) {
            id sub = safeInvokeGetter(obj, sel);
            if (!sub) {
                @try { sub = [obj valueForKey:sel]; } @catch (NSException *e) {}
            }
            if (sub && sub != obj) {
                NSString *p = extractVideoPathFromAnyObject(sub);
                if (p) return p;
            }
        }
    } @catch (NSException *e) {}
    
    return nil;
}

static NSString *findVideoPathInViewHierarchyHelper(UIView *view, NSHashTable *visited, int depth) {
    if (!view || depth > 10) return nil;
    if ([visited containsObject:view]) return nil;
    [visited addObject:view];
    
    @try {
        // 1. Direct object inspection
        NSString *p = extractVideoPathFromAnyObject(view);
        if (p) return p;
        
        // 2. Layer inspection
        if (view.layer) {
            p = extractVideoPathFromAnyObject(view.layer);
            if (p) return p;
            NSArray *sublayers = [view.layer.sublayers copy];
            for (CALayer *sub in sublayers) {
                p = extractVideoPathFromAnyObject(sub);
                if (p) return p;
            }
        }
        
        // 3. Ivars inspection of custom cells and player views
        unsigned int count = 0;
        Ivar *ivars = class_copyIvarList([view class], &count);
        if (ivars) {
            for (unsigned int i = 0; i < count; i++) {
                const char *name = ivar_getName(ivars[i]);
                const char *type = ivar_getTypeEncoding(ivars[i]);
                if (!type || (type[0] != '@' && type[0] != '#')) continue;
                
                if (name && (strstr(name, "player") || strstr(name, "Player") ||
                             strstr(name, "asset") || strstr(name, "Asset") ||
                             strstr(name, "video") || strstr(name, "Video") ||
                             strstr(name, "media") || strstr(name, "Media"))) {
                    id val = object_getIvar(view, ivars[i]);
                    if (val && val != view && ![visited containsObject:val]) {
                        [visited addObject:val];
                        p = extractVideoPathFromAnyObject(val);
                        if (p) {
                            free(ivars);
                            return p;
                        }
                    }
                }
            }
            free(ivars);
        }
        
        // 4. Subviews recursion
        NSArray *subviews = [view.subviews copy];
        for (UIView *sub in subviews) {
            p = findVideoPathInViewHierarchyHelper(sub, visited, depth + 1);
            if (p) return p;
        }
    } @catch (NSException *e) {}
    
    return nil;
}

static NSString *findVideoPathInViewHierarchy(UIView *view) {
    if (!view) return nil;
    NSHashTable *visited = [NSHashTable weakObjectsHashTable];
    return findVideoPathInViewHierarchyHelper(view, visited, 0);
}

static NSString *findVideoPathInControllerHierarchyHelper(UIViewController *ctrl, NSHashTable *visited, int depth) {
    if (!ctrl || depth > 8) return nil;
    if ([visited containsObject:ctrl]) return nil;
    [visited addObject:ctrl];
    
    @try {
        // 1. Controller itself
        NSString *p = extractVideoPathFromAnyObject(ctrl);
        if (p) return p;
        
        // 2. Controller ivars (e.g. protectedViewController, message, player)
        unsigned int count = 0;
        Ivar *ivars = class_copyIvarList([ctrl class], &count);
        if (ivars) {
            for (unsigned int i = 0; i < count; i++) {
                const char *name = ivar_getName(ivars[i]);
                const char *type = ivar_getTypeEncoding(ivars[i]);
                if (!type || (type[0] != '@' && type[0] != '#')) continue;
                
                if (name && (strstr(name, "player") || strstr(name, "Player") ||
                             strstr(name, "video") || strstr(name, "Video") ||
                             strstr(name, "protectedViewController") ||
                             strstr(name, "message") || strstr(name, "Message"))) {
                    id val = object_getIvar(ctrl, ivars[i]);
                    if (val && val != ctrl && ![visited containsObject:val]) {
                        [visited addObject:val];
                        p = extractVideoPathFromAnyObject(val);
                        if (p) {
                            free(ivars);
                            return p;
                        }
                        if ([val isKindOfClass:[UIViewController class]]) {
                            p = findVideoPathInControllerHierarchyHelper((UIViewController *)val, visited, depth + 1);
                            if (p) {
                                free(ivars);
                                return p;
                            }
                        }
                    }
                }
            }
            free(ivars);
        }
        
        // 3. View hierarchy
        if (ctrl.isViewLoaded) {
            p = findVideoPathInViewHierarchy(ctrl.view);
            if (p) return p;
        }
        
        // 4. Child view controllers
        NSArray *children = [ctrl.childViewControllers copy];
        for (UIViewController *child in children) {
            p = findVideoPathInControllerHierarchyHelper(child, visited, depth + 1);
            if (p) return p;
        }
        
        // 5. Parent view controller
        if (ctrl.parentViewController && ![visited containsObject:ctrl.parentViewController]) {
            [visited addObject:ctrl.parentViewController];
            p = extractVideoPathFromAnyObject(ctrl.parentViewController);
            if (p) return p;
        }
    } @catch (NSException *e) {}
    
    return nil;
}

static NSString *findVideoPathInControllerHierarchy(UIViewController *ctrl) {
    if (!ctrl) return nil;
    NSHashTable *visited = [NSHashTable weakObjectsHashTable];
    return findVideoPathInControllerHierarchyHelper(ctrl, visited, 0);
}

static NSString *findRecentVideoFile(void) {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSMutableArray *dirs = [NSMutableArray array];
    
    NSString *tmp = NSTemporaryDirectory();
    if (tmp) [dirs addObject:tmp];
    
    NSString *caches = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
    if (caches) {
        [dirs addObject:caches];
        [dirs addObject:[caches stringByAppendingPathComponent:@"Media"]];
    }
    
    NSString *docs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    if (docs) {
        [dirs addObject:[docs stringByAppendingPathComponent:@"Media"]];
    }
    
    NSString *lib = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES).firstObject;
    if (lib) {
        [dirs addObject:[lib stringByAppendingPathComponent:@"Media"]];
    }
    
    NSString *bestPath = nil;
    NSDate *newestDate = [NSDate dateWithTimeIntervalSinceNow:-900]; // last 15 minutes
    
    for (NSString *dir in dirs) {
        if (![fm fileExistsAtPath:dir]) continue;
        NSDirectoryEnumerator *enumerator = [fm enumeratorAtPath:dir];
        NSString *file;
        while ((file = [enumerator nextObject])) {
            NSString *ext = [[file pathExtension] lowercaseString];
            if ([ext isEqualToString:@"mp4"] || [ext isEqualToString:@"mov"] || [ext isEqualToString:@"m4v"]) {
                NSString *full = [dir stringByAppendingPathComponent:file];
                NSDictionary *attrs = [fm attributesOfItemAtPath:full error:nil];
                NSDate *mod = attrs[NSFileModificationDate];
                if (mod && [mod compare:newestDate] == NSOrderedDescending) {
                    newestDate = mod;
                    bestPath = full;
                }
            }
        }
    }
    return bestPath;
}

static BOOL isVideoContext(UIViewController *ctrl, id msg) {
    if (msg) {
        if (safeInvokeBool(msg, @"isVideo")) return YES;
        NSUInteger type = safeInvokeInteger(msg, @"messageType");
        if (type == 3 || type == 4) return YES;
        
        id mi = safeInvokeGetter(msg, @"mediaItem");
        if (mi) {
            if (safeInvokeBool(mi, @"isVideo")) return YES;
            for (NSString *sel in @[@"mediaFilePath", @"plaintextFilePath", @"videoLocalPath"]) {
                id p = safeInvokeGetter(mi, sel);
                if ([p isKindOfClass:[NSString class]]) {
                    NSString *ext = [[p pathExtension] lowercaseString];
                    if ([ext isEqualToString:@"mp4"] || [ext isEqualToString:@"mov"] || [ext isEqualToString:@"m4v"]) {
                        return YES;
                    }
                }
            }
        }
    }
    
    if (ctrl && ctrl.isViewLoaded) {
        NSString *cls = NSStringFromClass([ctrl class]);
        if ([cls containsString:@"Video"]) return YES;
    }
    
    return NO;
}

static void scanViewsRecursivelyHelper(UIView *v, NSHashTable *visited, int depth, void (^imageBlock)(UIImage *), void (^layerBlock)(CGImageRef)) {
    if (!v || depth > 10) return;
    if ([visited containsObject:v]) return;
    [visited addObject:v];
    
    @try {
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
        NSArray *subviews = [v.subviews copy];
        for (UIView *sub in subviews) {
            scanViewsRecursivelyHelper(sub, visited, depth + 1, imageBlock, layerBlock);
        }
    } @catch (NSException *e) {}
}

static void scanViewsRecursively(UIView *v, void (^imageBlock)(UIImage *), void (^layerBlock)(CGImageRef)) {
    if (!v) return;
    NSHashTable *visited = [NSHashTable weakObjectsHashTable];
    scanViewsRecursivelyHelper(v, visited, 0, imageBlock, layerBlock);
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
    if ([rawPath hasPrefix:@"file://"]) {
        NSURL *u = [NSURL URLWithString:rawPath];
        if (u.path) rawPath = u.path;
    }
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:rawPath]) return rawPath;
    
    // Check Documents directory
    NSString *docs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    if (docs) {
        NSString *cand = [docs stringByAppendingPathComponent:rawPath];
        if ([fm fileExistsAtPath:cand]) return cand;
        NSString *lastComp = [rawPath lastPathComponent];
        cand = [docs stringByAppendingPathComponent:lastComp];
        if ([fm fileExistsAtPath:cand]) return cand;
    }
    // Check Library directory
    NSString *lib = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES).firstObject;
    if (lib) {
        NSString *cand = [lib stringByAppendingPathComponent:rawPath];
        if ([fm fileExistsAtPath:cand]) return cand;
        NSString *lastComp = [rawPath lastPathComponent];
        cand = [lib stringByAppendingPathComponent:lastComp];
        if ([fm fileExistsAtPath:cand]) return cand;
    }
    // Check Caches directory
    NSString *caches = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
    if (caches) {
        NSString *cand = [caches stringByAppendingPathComponent:rawPath];
        if ([fm fileExistsAtPath:cand]) return cand;
        NSString *lastComp = [rawPath lastPathComponent];
        cand = [caches stringByAppendingPathComponent:lastComp];
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
    
    id msg = findMessageInController(controller);
    BOOL isVideo = isVideoContext(controller, msg);
    
    // --- 1. SEARCH FOR VIDEO FILE ---
    NSString *videoPath = nil;
    
    // Check message and mediaItem directly
    if (msg) {
        videoPath = extractVideoPathFromAnyObject(msg);
        if (!videoPath) {
            id mi = safeInvokeGetter(msg, @"mediaItem");
            if (mi) {
                videoPath = extractVideoPathFromAnyObject(mi);
            }
        }
    }
    
    // Check controller and view hierarchies
    if (!videoPath) {
        videoPath = findVideoPathInControllerHierarchy(controller);
    }
    
    // Check recent video in filesystem if in video context
    if (!videoPath && isVideo) {
        videoPath = findRecentVideoFile();
    }
    
    // If video found -> SAVE VIDEO
    if (videoPath) {
        [self saveVideoToPhotos:videoPath];
        return;
    }
    
    // If this WAS a video context, but no video file could be extracted, do NOT save a placeholder thumbnail photo!
    if (isVideo) {
        NSString *recent = findRecentVideoFile();
        if (recent) {
            [self saveVideoToPhotos:recent];
            return;
        }
        [self showToast:@"Video file still loading or not found" success:NO];
        return;
    }
    
    // --- 2. SEARCH FOR PHOTO (Image context only) ---
    @try {
        if (msg) {
            id mi = safeInvokeGetter(msg, @"mediaItem");
            if (mi) {
                for (NSString *sel in @[@"mediaLocalPath", @"mediaFilePath", @"fullPath", @"path", @"filePath"]) {
                    id pathObj = safeInvokeGetter(mi, sel);
                    NSString *resolved = resolveExistingFilePath(pathObj);
                    if (resolved) {
                        NSString *ext = [[resolved pathExtension] lowercaseString];
                        if ([ext isEqualToString:@"jpg"] || [ext isEqualToString:@"jpeg"] || [ext isEqualToString:@"png"]) {
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
        
        id media = findMediaInController(controller);
        if (media) {
            for (NSString *sel in @[@"mediaLocalPath", @"mediaFilePath", @"fullPath", @"path", @"filePath"]) {
                id pathObj = safeInvokeGetter(media, sel);
                NSString *resolved = resolveExistingFilePath(pathObj);
                if (resolved) {
                    NSString *ext = [[resolved pathExtension] lowercaseString];
                    if ([ext isEqualToString:@"jpg"] || [ext isEqualToString:@"jpeg"] || [ext isEqualToString:@"png"]) {
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
    
    // Find image in view hierarchy
    UIImage *image = [self findImageInView:controller.view];
    if (image) {
        [self saveImageToPhotos:image];
        return;
    }
    
    // Fallback: snapshot view
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

#pragma mark - Edit History Overlay & Tap Handling

- (void)handleEditBadgeTap:(UITapGestureRecognizer *)gesture {
    UIView *badge = gesture.view;
    if (!badge) return;

    [UIView animateWithDuration:0.1 animations:^{
        badge.transform = CGAffineTransformMakeScale(0.90, 0.90);
    } completion:^(BOOL finished) {
        (void)finished;
        [UIView animateWithDuration:0.1 animations:^{
            badge.transform = CGAffineTransformIdentity;
        }];
    }];

    UIWindow *window = badge.window;
    if (!window) {
        for (UIWindow *w in [UIApplication sharedApplication].windows) {
            if (w.isKeyWindow) { window = w; break; }
        }
        if (!window && [UIApplication sharedApplication].windows.count > 0) {
            window = [UIApplication sharedApplication].windows.firstObject;
        }
    }
    if (!window) return;

    CGRect anchorFrame = CGRectZero;
    @try {
        anchorFrame = [badge convertRect:badge.bounds toView:window];
    } @catch (NSException *e) {
        anchorFrame = CGRectMake((window.bounds.size.width - 60.0) / 2.0, (window.bounds.size.height - 30.0) / 2.0, 60.0, 30.0);
    }

    NSDictionary *badgeData = objc_getAssociatedObject(badge, "WATweakBadgeData");
    if (!badgeData) {
        // Safe fallback for compatibility
        id message = objc_getAssociatedObject(badge, "WATweakBadgeMsg");
        [MediaSaver showEditHistoryForMessage:message badgeFrame:anchorFrame inWindow:window];
        return;
    }

    [MediaSaver showEditHistoryWithData:badgeData anchorFrame:anchorFrame inWindow:window];
}

+ (void)showEditHistoryForMessage:(id)message bFrame:(CGRect)bFrame cell:(UIView *)cell {
    UIWindow *window = nil;
    for (UIWindow *w in [UIApplication sharedApplication].windows) {
        if (w.isKeyWindow) { window = w; break; }
    }
    if (!window && [UIApplication sharedApplication].windows.count > 0) {
        window = [UIApplication sharedApplication].windows.firstObject;
    }
    if (!window) return;

    CGRect anchor = CGRectZero;
    if (cell && !CGRectIsEmpty(bFrame)) {
        @try {
            anchor = [cell convertRect:bFrame toView:window];
        } @catch (NSException *e) {}
    }
    if (CGRectIsEmpty(anchor)) {
        anchor = CGRectMake(window.bounds.size.width / 2.0 - 40, window.bounds.size.height / 2.0 - 20, 80, 40);
    }
    [self showEditHistoryForMessage:message badgeFrame:anchor inWindow:window];
}

+ (void)showEditHistoryForMessage:(id)message badgeFrame:(CGRect)badgeFrame inWindow:(UIWindow *)targetWindow {
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    @try {
        NSString *sid = watweak_getStanzaIdFromMessage(message);
        if (sid) {
            NSString *orig = watweak_getOriginalTextForStanzaID(sid);
            if (orig) data[@"origText"] = orig;
            NSDate *ed = watweak_getEditDateForStanzaID(sid);
            if (ed) data[@"editDate"] = ed;
            NSArray *chain = watweak_getEditChainForStanzaID(sid);
            if (chain && chain.count > 0) data[@"chain"] = chain;
        }
        NSString *cur = watweak_safeGetString(message, @selector(text));
        if (cur) data[@"currentText"] = cur;

        NSDate *md = watweak_safeGetDate(message, @selector(messageDate));
        if (md) data[@"origDate"] = md;

        if (!data[@"editDate"]) {
            NSDate *ed = watweak_safeGetDate(message, @selector(latestEditTimestamp));
            if (!ed) ed = watweak_safeGetDate(message, @selector(lastEditTimestamp));
            if (ed) data[@"editDate"] = ed;
        }
    } @catch (NSException *e) {}

    [self showEditHistoryWithData:data anchorFrame:badgeFrame inWindow:targetWindow];
}

+ (void)showEditHistoryWithData:(NSDictionary *)data anchorFrame:(CGRect)anchorFrame inWindow:(UIWindow *)targetWindow {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *window = targetWindow;
        if (!window) {
            for (UIWindow *w in [UIApplication sharedApplication].windows) {
                if (w.isKeyWindow) { window = w; break; }
            }
            if (!window && [UIApplication sharedApplication].windows.count > 0) {
                window = [UIApplication sharedApplication].windows.firstObject;
            }
        }
        if (!window) return;

        UIView *oldOverlay = [window viewWithTag:998898];
        if (oldOverlay) {
            [oldOverlay removeFromSuperview];
        }

        NSArray *rawChain = data[@"chain"];
        NSString *origText = data[@"origText"];
        NSString *currentText = data[@"currentText"];
        NSDate *origDate = data[@"origDate"];
        NSDate *editDate = data[@"editDate"];

        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        df.dateFormat = @"HH:mm:ss";

        NSMutableArray<NSMutableDictionary *> *chain = [NSMutableArray array];
        if ([rawChain isKindOfClass:[NSArray class]] && rawChain.count > 0) {
            for (id item in rawChain) {
                if ([item isKindOfClass:[NSDictionary class]]) {
                    [chain addObject:[item mutableCopy]];
                }
            }
        }

        // If chain is empty or incomplete, construct from origText and currentText
        if (chain.count == 0) {
            if (origText && origText.length > 0) {
                [chain addObject:[@{
                    @"text": origText,
                    @"date": origDate ?: (editDate ? [NSDate dateWithTimeInterval:-60 sinceDate:editDate] : [NSDate dateWithTimeIntervalSinceNow:-60])
                } mutableCopy]];
            }
            if (currentText && currentText.length > 0 && ![currentText isEqualToString:origText]) {
                [chain addObject:[@{
                    @"text": currentText,
                    @"date": editDate ?: [NSDate date]
                } mutableCopy]];
            }
        } else {
            // Ensure first item matches original text if known and not already first
            if (origText && origText.length > 0 && ![origText hasPrefix:@"("]) {
                NSString *firstText = chain.firstObject[@"text"];
                if (![firstText isEqualToString:origText]) {
                    NSDate *firstDate = [chain.firstObject[@"date"] isKindOfClass:[NSDate class]] ? chain.firstObject[@"date"] : (editDate ?: [NSDate date]);
                    [chain insertObject:[@{
                        @"text": origText,
                        @"date": origDate ?: [NSDate dateWithTimeInterval:-60 sinceDate:firstDate]
                    } mutableCopy] atIndex:0];
                }
            }
            // Ensure last item matches currentText if known and not already last
            if (currentText && currentText.length > 0) {
                NSString *lastText = chain.lastObject[@"text"];
                if (![lastText isEqualToString:currentText]) {
                    [chain addObject:[@{
                        @"text": currentText,
                        @"date": editDate ?: [NSDate date]
                    } mutableCopy]];
                }
            }
        }

        // Fallback if still empty
        if (chain.count == 0) {
            [chain addObject:[@{
                @"text": currentText ?: (origText ?: @"(Original message text was not captured during this session)"),
                @"date": editDate ?: (origDate ?: [NSDate date])
            } mutableCopy]];
        }

        // Build display history entries matching Telegram sequence:
        // Original message -> Edit 1 -> Edit 2 -> ... -> Current edited message
        NSMutableArray *history = [NSMutableArray array];
        NSUInteger total = chain.count;

        for (NSUInteger idx = 0; idx < total; idx++) {
            NSDictionary *item = chain[idx];
            NSString *bodyStr = item[@"text"] ?: @"";
            
            // Resolve real timestamp:
            NSDate *itemDate = item[@"date"];
            if (![itemDate isKindOfClass:[NSDate class]]) {
                if (idx == 0) {
                    itemDate = origDate ?: (editDate ? [NSDate dateWithTimeInterval:-60 * (total - 1) sinceDate:editDate] : [NSDate dateWithTimeIntervalSinceNow:-60]);
                } else if (idx == total - 1) {
                    itemDate = editDate ?: [NSDate date];
                } else {
                    NSTimeInterval step = 30.0;
                    NSDate *base = editDate ?: [NSDate date];
                    itemDate = [NSDate dateWithTimeInterval:-step * (total - 1 - idx) sinceDate:base];
                }
            }
            NSString *timeBadge = [NSString stringWithFormat:@"[%@]", [df stringFromDate:itemDate]];

            NSString *labelStr = nil;
            if (idx == 0) {
                labelStr = (total > 1) ? @"Original message" : @"Message text";
            } else if (idx == total - 1 && total > 1) {
                labelStr = @"Current edited message";
            } else if (total > 2) {
                labelStr = [NSString stringWithFormat:@"Edit %lu", (unsigned long)idx];
            } else {
                labelStr = @"Edited message";
            }

            [history addObject:@{
                @"badge": timeBadge,
                @"label": labelStr,
                @"text": bodyStr
            }];
        }

        UIView *backdrop = [[UIView alloc] initWithFrame:window.bounds];
        backdrop.tag = 998898;
        backdrop.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.35];
        backdrop.alpha = 0.0;
        backdrop.userInteractionEnabled = YES;

        UITapGestureRecognizer *dismissTap = [[UITapGestureRecognizer alloc] initWithTarget:[MediaSaver shared] action:@selector(dismissEditHistoryOverlay)];
        dismissTap.delegate = [MediaSaver shared];
        [backdrop addGestureRecognizer:dismissTap];

        CGFloat screenW = window.bounds.size.width;
        CGFloat screenH = window.bounds.size.height;

        CGFloat cardW = screenW - 36.0;
        if (cardW > 340.0) cardW = 340.0;
        if (cardW < 220.0) cardW = 220.0;

        CGFloat contentH = 28.0;
        for (NSDictionary *entry in history) {
            NSString *txt = entry[@"text"] ?: @"";
            CGSize s = [txt boundingRectWithSize:CGSizeMake(cardW - 28.0, 300) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:13.0]} context:nil].size;
            contentH += 18.0 + MAX(s.height, 16.0) + 14.0;
        }
        CGFloat maxH = screenH * 0.60;
        if (contentH > maxH) contentH = maxH;
        if (contentH < 50.0) contentH = 50.0;

        CGFloat cardX = anchorFrame.origin.x;
        if (cardX + cardW > screenW - 12.0) cardX = screenW - cardW - 12.0;
        if (cardX < 12.0) cardX = 12.0;

        CGFloat cardY = anchorFrame.origin.y - contentH - 8.0;
        if (cardY < 60.0) {
            cardY = CGRectGetMaxY(anchorFrame) + 8.0;
        }
        if (cardY + contentH > screenH - 40.0) {
            cardY = screenH - contentH - 40.0;
        }

        UIView *card = [[UIView alloc] initWithFrame:CGRectMake(cardX, cardY, cardW, contentH)];
        card.backgroundColor = [UIColor colorWithWhite:0.08 alpha:0.97];
        card.layer.cornerRadius = 14.0;
        card.layer.masksToBounds = YES;
        card.transform = CGAffineTransformMakeScale(0.92, 0.92);

        UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, cardW, contentH)];
        scrollView.showsVerticalScrollIndicator = YES;
        scrollView.alwaysBounceVertical = NO;

        CGFloat currY = 14.0;
        for (NSDictionary *entry in history) {
            NSString *badgeStr = entry[@"badge"] ?: @"";
            NSString *labelStr = entry[@"label"] ?: @"";
            NSString *bodyStr = entry[@"text"] ?: @"";

            UILabel *badgeLbl = [[UILabel alloc] initWithFrame:CGRectMake(14, currY, cardW - 28, 14)];
            badgeLbl.font = [UIFont monospacedDigitSystemFontOfSize:11.0 weight:UIFontWeightMedium];
            badgeLbl.textColor = [UIColor colorWithWhite:0.65 alpha:1.0];
            badgeLbl.text = [NSString stringWithFormat:@"%@  %@", badgeStr, labelStr];
            [scrollView addSubview:badgeLbl];
            currY += 18.0;

            CGSize bodySize = [bodyStr boundingRectWithSize:CGSizeMake(cardW - 28.0, 300) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:13.0]} context:nil].size;
            CGFloat textH = MAX(bodySize.height, 16.0);

            UILabel *bodyLbl = [[UILabel alloc] initWithFrame:CGRectMake(14, currY, cardW - 28, textH)];
            bodyLbl.font = [UIFont systemFontOfSize:13.0];
            bodyLbl.textColor = [UIColor whiteColor];
            bodyLbl.numberOfLines = 0;
            bodyLbl.text = bodyStr;
            bodyLbl.userInteractionEnabled = YES;

            UITapGestureRecognizer *rowTap = [[UITapGestureRecognizer alloc] initWithTarget:[MediaSaver shared] action:@selector(handleHistoryCopyTap:)];
            objc_setAssociatedObject(rowTap, "WATweakCopyText", bodyStr, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            [bodyLbl addGestureRecognizer:rowTap];

            [scrollView addSubview:bodyLbl];
            currY += textH + 14.0;
        }
        scrollView.contentSize = CGSizeMake(cardW, currY);
        [card addSubview:scrollView];

        [backdrop addSubview:card];
        [window addSubview:backdrop];

        [UIView animateWithDuration:0.25 delay:0.0 usingSpringWithDamping:0.85 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
            backdrop.alpha = 1.0;
            card.transform = CGAffineTransformIdentity;
        } completion:nil];
    });
}

- (void)handleHistoryCopyTap:(UITapGestureRecognizer *)gesture {
    NSString *txt = objc_getAssociatedObject(gesture, "WATweakCopyText");
    if (txt && txt.length > 0) {
        [UIPasteboard generalPasteboard].string = txt;
        [MediaSaver showToast:@"Text copied!" success:YES];
    }
}

- (void)dismissEditHistoryOverlay {
    UIWindow *window = nil;
    for (UIWindow *w in [UIApplication sharedApplication].windows) {
        if (w.isKeyWindow) { window = w; break; }
    }
    if (!window && [UIApplication sharedApplication].windows.count > 0) {
        window = [UIApplication sharedApplication].windows.firstObject;
    }
    if (!window) return;
    UIView *overlay = [window viewWithTag:998898];
    if (overlay) {
        [UIView animateWithDuration:0.20 animations:^{
            overlay.alpha = 0.0;
        } completion:^(BOOL finished) {
            (void)finished;
            [overlay removeFromSuperview];
        }];
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if (gestureRecognizer.view && gestureRecognizer.view.tag == 998898) {
        return (touch.view == gestureRecognizer.view);
    }
    return YES;
}

@end
