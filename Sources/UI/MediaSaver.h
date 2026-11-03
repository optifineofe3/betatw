#import <UIKit/UIKit.h>

@interface MediaSaver : NSObject <UIGestureRecognizerDelegate>

+ (instancetype)shared;
+ (BOOL)isMediaViewerController:(UIViewController *)controller;
+ (void)attachToController:(UIViewController *)controller;
+ (void)detachFromController:(UIViewController *)controller animated:(BOOL)animated;
+ (void)saveMediaFromController:(UIViewController *)controller;
+ (void)saveVideoToPhotos:(NSString *)videoPath;
+ (void)saveImageToPhotos:(UIImage *)image;
+ (void)showToast:(NSString *)message success:(BOOL)success;

- (void)handleButtonTap:(id)sender;

@end
