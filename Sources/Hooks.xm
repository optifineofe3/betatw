#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import "Headers.h"
#import "Constants.h"
#import "UI/WAExtra.h"

#pragma mark - 1. Media Quality (Uncompressed Photos & Videos)

%hook WAMultiSendMediaItemQuality

+ (id)chatQuality {
    if (WATweakGetBool(kUncompressedPhotos, YES)) {
        if ([self respondsToSelector:@selector(fullQuality)]) {
            return [self fullQuality];
        } else if ([self respondsToSelector:@selector(documentImageQuality)]) {
            return [self documentImageQuality];
        }
    }
    return %orig;
}

+ (id)defaultChatQuality {
    if (WATweakGetBool(kUncompressedPhotos, YES)) {
        if ([self respondsToSelector:@selector(fullQuality)]) {
            return [self fullQuality];
        } else if ([self respondsToSelector:@selector(documentImageQuality)]) {
            return [self documentImageQuality];
        }
    }
    return %orig;
}

- (NSUInteger)imageMaximumEdge {
    if (WATweakGetBool(kUncompressedPhotos, YES)) {
        return 99999;
    }
    return %orig;
}

- (CGFloat)imageQuality {
    if (WATweakGetBool(kUncompressedPhotos, YES)) {
        return 1.0;
    }
    return %orig;
}

- (NSUInteger)videoMaximumWidth {
    if (WATweakGetBool(kUncompressedVideos, YES)) {
        return 3840; // 4K support
    }
    return %orig;
}

- (NSUInteger)videoMaximumHeight {
    if (WATweakGetBool(kUncompressedVideos, YES)) {
        return 3840;
    }
    return %orig;
}

- (NSUInteger)videoMaximumBitrate {
    if (WATweakGetBool(kUncompressedVideos, YES)) {
        return 50000000; // 50 Mbps max bitrate
    }
    return %orig;
}

%end

%hook UITTranscodeConfig

- (CGFloat)maxCompressionQuality {
    if (WATweakGetBool(kUncompressedPhotos, YES)) {
        return 1.0;
    }
    return %orig;
}

- (CGFloat)minCompressionQuality {
    if (WATweakGetBool(kUncompressedPhotos, YES)) {
        return 1.0;
    }
    return %orig;
}

%end

%hook WAJPEGProcessor

+ (id)encodeFromUrlWithInputImageUrl:(id)arg1 outputImageUrl:(id)arg2 targetSize:(CGSize)arg3 imageQuality:(CGFloat)arg4 peakMemoryUseBytes:(NSUInteger)arg5 isHDImage:(BOOL)arg6 pjpegScans:(id)arg7 uitConfig:(id)arg8 abProperties:(id)arg9 progressCallback:(id)arg10 parseError:(id)arg11 {
    if (WATweakGetBool(kUncompressedPhotos, YES)) {
        return %orig(arg1, arg2, arg3, 1.0, arg5, YES, arg7, arg8, arg9, arg10, arg11);
    }
    return %orig;
}

%end

#pragma mark - 2. Ghost Mode (Online, Typing, Last Seen)

%hook XMPPPresenceControllerMain

- (void)reallySendPresenceWithNickname:(id)arg1 presence:(id)arg2 {
    if (WATweakGetBool(kDisableOnline, NO)) {
        return;
    }
    %orig;
}

- (void)sendPresence {
    if (WATweakGetBool(kDisableOnline, NO)) {
        return;
    }
    %orig;
}

- (void)sendPresenceWithNickname:(id)arg1 {
    if (WATweakGetBool(kDisableOnline, NO)) {
        return;
    }
    %orig;
}

- (void)sendPresenceWithNickname:(id)arg1 deviceAvailable:(BOOL)arg2 {
    if (WATweakGetBool(kDisableOnline, NO)) {
        return;
    }
    %orig;
}

%end

%hook XMPPConnectionMain

- (void)sendChatState:(id)arg1 toJID:(id)arg2 {
    if (WATweakGetBool(kDisableTyping, NO)) {
        return;
    }
    %orig;
}

%end

#pragma mark - 3. Read Receipts (Blue Ticks)

%hook XMPPConnectionMain

+ (BOOL)shouldSendReadReceiptForMessage:(id)arg1 userContext:(id)arg2 {
    if (WATweakGetBool(kDisableReadReceipts, NO)) {
        return NO;
    }
    return %orig;
}

- (void)sendReadReceiptsForMessagesIfNeeded:(id)arg1 {
    if (WATweakGetBool(kDisableReadReceipts, NO)) {
        return;
    }
    %orig;
}

%end

%hook WAChatManager

- (void)markChatSessions:(id)arg1 read:(BOOL)arg2 sendReadReceipts:(BOOL)arg3 error:(id *)arg4 {
    if (WATweakGetBool(kDisableReadReceipts, NO)) {
        arg3 = NO;
    }
    %orig(arg1, arg2, arg3, arg4);
}

- (void)sendReadReceiptsForMessagesBeforeAndIncludingMessage:(id)arg1 inChatSession:(id)arg2 isMarkedByUser:(BOOL)arg3 {
    if (WATweakGetBool(kDisableReadReceipts, NO) && !arg3) {
        return;
    }
    %orig;
}

%end

#pragma mark - 4. Status / Stories Stealth Viewing

%hook WAStatusXMPPService

- (void)sendReadReceiptsForStatuses:(id)arg1 {
    if (WATweakGetBool(kDisableStatusReceipts, NO)) {
        return;
    }
    %orig;
}

%end

%hook WAChatManager

- (void)markStatusAsSeen:(id)arg1 sendReadReceipts:(BOOL)arg2 skipUpdateChatSession:(BOOL)arg3 {
    if (WATweakGetBool(kDisableStatusReceipts, NO)) {
        arg2 = NO;
    }
    %orig(arg1, arg2, arg3);
}

%end

#pragma mark - 5. Anti-Revoke (Preserve Deleted Messages)

%hook WAChatViewController

- (void)chatStorageDidRevokeMessages:(id)arg1 {
    if (WATweakGetBool(kAntiRevoke, YES)) {
        // Suppress message removal from UI
        return;
    }
    %orig;
}

- (void)chatStorageWillRevokeMessages:(id)arg1 {
    if (WATweakGetBool(kAntiRevoke, YES)) {
        return;
    }
    %orig;
}

%end

%hook _TtC22WAChatMessagesVCStrict28WAChatMessagesViewController

- (void)chatStorageDidRevokeMessages:(id)arg1 {
    if (WATweakGetBool(kAntiRevoke, YES)) {
        return;
    }
    %orig;
}

- (void)chatStorageWillRevokeMessages:(id)arg1 {
    if (WATweakGetBool(kAntiRevoke, YES)) {
        return;
    }
    %orig;
}

%end

#pragma mark - 6. Anti-Self-Destruct (View-Once Bypass)

%hook WAMessage

- (BOOL)isViewOnceOpened {
    if (WATweakGetBool(kUnlimitedViewOnce, YES)) {
        return NO;
    }
    return %orig;
}

- (void)markViewOnceMessageExpiredIfPossible {
    if (WATweakGetBool(kUnlimitedViewOnce, YES)) {
        return;
    }
    %orig;
}

- (int64_t)viewOnceCount {
    if (WATweakGetBool(kUnlimitedViewOnce, YES)) {
        return 0;
    }
    return %orig;
}

%end

#pragma mark - 7. Screenshot Detection & Protection Bypass

%hook WhatsAppAppDelegate

- (void)applicationUserDidTakeScreenshot:(id)arg1 {
    if (WATweakGetBool(kDisableScreenshotDetection, YES)) {
        return;
    }
    %orig;
}

%end

%hook WAViewOnceMessageViewController

- (void)userDidTakeScreenshot:(id)arg1 {
    if (WATweakGetBool(kDisableScreenshotDetection, YES)) {
        return;
    }
    %orig;
}

%end

%hook WAGroupIconViewController

- (void)addScreenshotProtectionIfNeeded {
    if (WATweakGetBool(kDisableScreenshotDetection, YES)) {
        return;
    }
    %orig;
}

- (void)addScreenRecordingProtectionIfNeeded {
    if (WATweakGetBool(kDisableScreenshotDetection, YES)) {
        return;
    }
    %orig;
}

%end

%hook _TtC23WAViewOnceMessageViewerP33_7691D041A7C67D05AF843B2696D5309037ViewOnceDisplayChatMessagesController

- (BOOL)pausesPlaybackForScreenRecording {
    if (WATweakGetBool(kDisableScreenRecordingPause, YES)) {
        return NO;
    }
    return %orig;
}

%end

#pragma mark - 8. Tweak Menu Trigger (Long-press on Help and Feedback)

static NSString *findTextRecursively(UIView *view) {
    if ([view respondsToSelector:@selector(text)]) {
        NSString *t = [view performSelector:@selector(text)];
        if ([t isKindOfClass:[NSString class]] && t.length > 0) {
            return t;
        }
    }
    for (UIView *sub in view.subviews) {
        NSString *found = findTextRecursively(sub);
        if (found.length > 0) {
            return found;
        }
    }
    return nil;
}

%hook WASettingsViewController

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    %orig;
    
    // Inspect cell text for Help / Help and Feedback
    NSString *cellText = cell.textLabel.text ?: @"";
    if (cellText.length == 0) {
        cellText = findTextRecursively(cell.contentView) ?: @"";
    }
    
    BOOL isHelp = [cellText rangeOfString:@"Help" options:NSCaseInsensitiveSearch].location != NSNotFound ||
                  [cellText rangeOfString:@"Помощь" options:NSCaseInsensitiveSearch].location != NSNotFound ||
                  [cellText rangeOfString:@"Feedback" options:NSCaseInsensitiveSearch].location != NSNotFound ||
                  [cellText rangeOfString:@"Справка" options:NSCaseInsensitiveSearch].location != NSNotFound;
    
    if (isHelp) {
        BOOL alreadyAttached = NO;
        for (UIGestureRecognizer *gr in cell.gestureRecognizers) {
            if ([objc_getAssociatedObject(gr, "isWATweakGesture") boolValue]) {
                alreadyAttached = YES;
                break;
            }
        }
        if (!alreadyAttached) {
            UILongPressGestureRecognizer *lp = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(watweak_openSettingsFromLongPress:)];
            lp.minimumPressDuration = 0.5;
            objc_setAssociatedObject(lp, "isWATweakGesture", @(YES), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            [cell addGestureRecognizer:lp];
        }
    }
}

%new
- (void)watweak_openSettingsFromLongPress:(UILongPressGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        UIImpactFeedbackGenerator *feedback = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
        [feedback prepare];
        [feedback impactOccurred];
        
        WAExtra *tweakVC = [[WAExtra alloc] init];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:tweakVC];
        nav.modalPresentationStyle = UIModalPresentationPageSheet;
        [self presentViewController:nav animated:YES completion:nil];
    }
}

%end
