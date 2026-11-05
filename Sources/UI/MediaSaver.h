#import <UIKit/UIKit.h>

#ifdef __cplusplus
extern "C" {
#endif

NSString *watweak_getStanzaIdFromMessage(id msg);
NSString *watweak_getOriginalTextForStanzaID(NSString *sid);
NSDate *watweak_getEditDateForStanzaID(NSString *sid);
void watweak_saveOriginalTextForStanzaID(NSString *sid, NSString *origText, NSDate *editDate);
void watweak_cacheInitialTextForStanzaID(NSString *sid, NSString *text);

#ifdef __cplusplus
}
#endif

@interface MediaSaver : NSObject <UIGestureRecognizerDelegate>

+ (instancetype)shared;
+ (BOOL)isMediaViewerController:(UIViewController *)controller;
+ (void)attachToController:(UIViewController *)controller;
+ (void)detachFromController:(UIViewController *)controller animated:(BOOL)animated;
+ (void)saveMediaFromController:(UIViewController *)controller;
+ (void)saveVideoToPhotos:(NSString *)videoPath;
+ (void)saveImageToPhotos:(UIImage *)image;
+ (void)showToast:(NSString *)message success:(BOOL)success;

+ (void)showEditHistoryForMessage:(id)message badgeFrame:(CGRect)badgeFrame inWindow:(UIWindow *)window;
+ (void)showEditHistoryForMessage:(id)message bFrame:(CGRect)bFrame cell:(UIView *)cell;
- (void)handleEditBadgeTap:(UITapGestureRecognizer *)gesture;
- (void)dismissEditHistoryOverlay;
- (void)handleHistoryCopyTap:(UITapGestureRecognizer *)gesture;

- (void)handleButtonTap:(id)sender;
- (void)handleButtonPan:(UIPanGestureRecognizer *)pan;

@end
