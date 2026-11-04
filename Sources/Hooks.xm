#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import "Headers.h"
#import "Constants.h"
#import "UI/WAExtra.h"
#import "UI/MediaSaver.h"

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

- (void)reallySendPresenceWithNickname:(NSString *)arg1 presence:(NSUInteger)arg2 {
    if (WATweakGetBool(kDisableOnline, NO)) {
        return;
    }
    %orig(arg1, arg2);
}

- (void)sendPresence {
    if (WATweakGetBool(kDisableOnline, NO)) {
        return;
    }
    %orig;
}

- (void)sendPresenceWithNickname:(NSString *)arg1 {
    if (WATweakGetBool(kDisableOnline, NO)) {
        return;
    }
    %orig(arg1);
}

- (void)sendPresenceWithNickname:(NSString *)arg1 deviceAvailable:(BOOL)arg2 {
    if (WATweakGetBool(kDisableOnline, NO)) {
        return;
    }
    %orig(arg1, arg2);
}

%end

%hook WAChatViewController

- (void)changeOutgoingChatState:(NSUInteger)arg1 forChatJID:(id)arg2 {
    if (WATweakGetBool(kDisableTyping, NO)) {
        return;
    }
    %orig(arg1, arg2);
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

static inline BOOL WAMessageIsFromMe(id msg) {
    if (!msg) return NO;
    @try {
        if ([msg respondsToSelector:@selector(isFromMe)]) {
            return [msg isFromMe];
        }
        SEL fromMeSel = sel_registerName("fromMe");
        if ([msg respondsToSelector:fromMeSel]) {
            BOOL (*impl)(id, SEL) = (BOOL (*)(id, SEL))[msg methodForSelector:fromMeSel];
            if (impl) return impl(msg, fromMeSel);
        }
    } @catch (NSException *e) {}
    return NO;
}

static BOOL HasOutgoingRevokedMessages(id arg1) {
    if (!arg1) return YES;
    @try {
        if ([arg1 isKindOfClass:[NSArray class]]) {
            for (id item in (NSArray *)arg1) {
                if (WAMessageIsFromMe(item)) return YES;
            }
            return NO;
        }
        if ([arg1 isKindOfClass:[NSSet class]]) {
            for (id item in (NSSet *)arg1) {
                if (WAMessageIsFromMe(item)) return YES;
            }
            return NO;
        }
        if ([arg1 isKindOfClass:[NSNotification class]]) {
            NSDictionary *ui = [(NSNotification *)arg1 userInfo];
            if (ui) {
                for (id key in ui) {
                    id val = ui[key];
                    if ([val isKindOfClass:[NSArray class]]) {
                        for (id item in (NSArray *)val) {
                            if (WAMessageIsFromMe(item)) return YES;
                        }
                    } else if ([val isKindOfClass:[NSSet class]]) {
                        for (id item in (NSSet *)val) {
                            if (WAMessageIsFromMe(item)) return YES;
                        }
                    }
                }
            }
            return NO;
        }
    } @catch (NSException *e) {}
    return YES;
}

%hook WAChatStorage

- (void)revokeIncomingMessage:(id)message triggeredByMessageWithID:(id)messageID onDate:(id)date outOfOrder:(BOOL)outOfOrder revokedByAdminUserJID:(id)adminJID deferAction:(id)deferAction {
    if (WATweakGetBool(kAntiRevoke, YES)) {
        if (WAMessageIsFromMe(message)) {
            @try {
                %orig;
            } @catch (NSException *e) {
                WATweakLog(@"Exception in revokeIncomingMessage %%orig for outgoing: %@", e);
            }
            return;
        }
        WATweakLog(@"Suppressed revokeIncomingMessage for message: %@", message);
        @try {
            if ([message respondsToSelector:@selector(text)]) {
                NSString *txt = [message text];
                if (txt && txt.length > 0 && ![txt hasPrefix:@"[DEL] "]) {
                    if ([message respondsToSelector:@selector(setText:)]) {
                        [message setText:[NSString stringWithFormat:@"[DEL] %@", txt]];
                    }
                }
            }
        } @catch (NSException *e) {
            WATweakLog(@"Exception in revokeIncomingMessage: %@", e);
        }
        return;
    }
    %orig;
}

- (void)internalRevokeMessages:(NSArray *)messages triggeredByMessageWithID:(id)messageID onDate:(id)date outgoing:(BOOL)outgoing revokedByAdminUserJID:(id)adminJID botPluginMessagesToDelete:(id)botMsgs beginTransactions:(BOOL)begin commitTransactions:(BOOL)commit {
    if (WATweakGetBool(kAntiRevoke, YES) && !outgoing) {
        WATweakLog(@"Suppressed internalRevokeMessages for incoming messages");
        @try {
            for (id msg in messages) {
                if ([msg respondsToSelector:@selector(text)]) {
                    NSString *txt = [msg text];
                    if (txt && txt.length > 0 && ![txt hasPrefix:@"[DEL] "]) {
                        if ([msg respondsToSelector:@selector(setText:)]) {
                            [msg setText:[NSString stringWithFormat:@"[DEL] %@", txt]];
                        }
                    }
                }
            }
        } @catch (NSException *e) {
            WATweakLog(@"Exception in internalRevokeMessages: %@", e);
        }
        return;
    }
    @try {
        %orig;
    } @catch (NSException *e) {
        WATweakLog(@"Exception in internalRevokeMessages %%orig: %@ (%@)", e.name, e.reason);
    }
}

- (void)deleteExpiredViewOnceContent:(id)messages completion:(id)completion {
    if (WATweakGetBool(kUnlimitedViewOnce, YES)) {
        WATweakLog(@"Prevented deleteExpiredViewOnceContent");
        if (completion) {
            void (^block)(BOOL) = (void (^)(BOOL))completion;
            block(NO);
        }
        return;
    }
    %orig;
}

%end

%hook WAMessage

- (BOOL)isRevoked {
    if (WATweakGetBool(kAntiRevoke, YES)) {
        if (WAMessageIsFromMe(self)) {
            return %orig;
        }
        return NO;
    }
    return %orig;
}

- (BOOL)isRevokedByAdmin {
    if (WATweakGetBool(kAntiRevoke, YES)) {
        if (WAMessageIsFromMe(self)) {
            return %orig;
        }
        return NO;
    }
    return %orig;
}

- (BOOL)isMessageRevoked {
    if (WATweakGetBool(kAntiRevoke, YES)) {
        if (WAMessageIsFromMe(self)) {
            return %orig;
        }
        return NO;
    }
    return %orig;
}

- (BOOL)isViewOnceOpened {
    if (WATweakGetBool(kUnlimitedViewOnce, YES)) {
        return NO;
    }
    return %orig;
}

- (BOOL)isViewOnceExpired {
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

%hook _TtC25WAMessageSliceViewsStatus30StatusComponentMessageSnapshot

- (BOOL)isMessageRevoked {
    if (WATweakGetBool(kAntiRevoke, YES)) {
        @try {
            if ([self respondsToSelector:@selector(message)]) {
                id msg = [self performSelector:@selector(message)];
                if (WAMessageIsFromMe(msg)) {
                    return %orig;
                }
            }
            if ([self respondsToSelector:@selector(isFromMe)]) {
                BOOL (*impl)(id, SEL) = (BOOL (*)(id, SEL))[self methodForSelector:@selector(isFromMe)];
                if (impl && impl(self, @selector(isFromMe))) {
                    return %orig;
                }
            }
        } @catch (NSException *e) {}
        return NO;
    }
    return %orig;
}

%end

%hook _TtC24WAMessageStatusProviding23MessageStatusDescriptor

- (BOOL)snippetHideIfRevoked {
    if (WATweakGetBool(kAntiRevoke, YES)) {
        @try {
            if ([self respondsToSelector:@selector(message)]) {
                id msg = [self performSelector:@selector(message)];
                if (WAMessageIsFromMe(msg)) {
                    return %orig;
                }
            }
            if ([self respondsToSelector:@selector(isFromMe)]) {
                BOOL (*impl)(id, SEL) = (BOOL (*)(id, SEL))[self methodForSelector:@selector(isFromMe)];
                if (impl && impl(self, @selector(isFromMe))) {
                    return %orig;
                }
            }
        } @catch (NSException *e) {}
        return NO;
    }
    return %orig;
}

%end

%hook WAChatViewController

- (void)chatStorageDidRevokeMessages:(id)arg1 {
    if (WATweakGetBool(kAntiRevoke, YES) && !HasOutgoingRevokedMessages(arg1)) {
        return;
    }
    @try {
        %orig;
    } @catch (NSException *e) {
        WATweakLog(@"Exception in WAChatViewController chatStorageDidRevokeMessages: %@", e);
    }
}

- (void)chatStorageWillRevokeMessages:(id)arg1 {
    if (WATweakGetBool(kAntiRevoke, YES) && !HasOutgoingRevokedMessages(arg1)) {
        return;
    }
    @try {
        %orig;
    } @catch (NSException *e) {
        WATweakLog(@"Exception in WAChatViewController chatStorageWillRevokeMessages: %@", e);
    }
}

%end

%hook _TtC22WAChatMessagesVCStrict28WAChatMessagesViewController

- (void)chatStorageDidRevokeMessages:(id)arg1 {
    if (WATweakGetBool(kAntiRevoke, YES) && !HasOutgoingRevokedMessages(arg1)) {
        return;
    }
    @try {
        %orig;
    } @catch (NSException *e) {
        WATweakLog(@"Exception in WAChatMessagesViewController chatStorageDidRevokeMessages: %@", e);
    }
}

- (void)chatStorageWillRevokeMessages:(id)arg1 {
    if (WATweakGetBool(kAntiRevoke, YES) && !HasOutgoingRevokedMessages(arg1)) {
        return;
    }
    @try {
        %orig;
    } @catch (NSException *e) {
        WATweakLog(@"Exception in WAChatMessagesViewController chatStorageWillRevokeMessages: %@", e);
    }
}

- (void)presentExpiredViewOnceAlertViewForMessage:(id)arg1 {
    if (WATweakGetBool(kUnlimitedViewOnce, YES)) {
        return;
    }
    %orig;
}

%end

#pragma mark - 6. Media Viewers & MediaSaver Floating Button

%hook _TtC25WAMediaBrowserControllers30MediaBrowserTestViewController

- (void)viewDidAppear:(BOOL)animated {
    %orig;
    [MediaSaver attachToController:self];
}

- (void)viewDidLayoutSubviews {
    %orig;
    UIView *btn = [self.view viewWithTag:998811];
    if (btn) {
        [self.view bringSubviewToFront:btn];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    %orig;
    [MediaSaver detachFromController:self animated:animated];
}

%end

%hook WAViewOnceMessageViewController

- (void)viewDidAppear:(BOOL)animated {
    %orig;
    [MediaSaver attachToController:self];
}

- (void)viewDidLayoutSubviews {
    %orig;
    UIView *btn = [self.view viewWithTag:998811];
    if (btn) {
        [self.view bringSubviewToFront:btn];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    %orig;
    [MediaSaver detachFromController:self animated:animated];
}

- (void)userDidTakeScreenshot:(id)arg1 {
    if (WATweakGetBool(kDisableScreenshotDetection, YES)) {
        return;
    }
    %orig;
}

%end

%hook _TtC23WAViewOnceMessageViewer43ViewOnceMessageContentDisplayViewController

- (void)viewDidAppear:(BOOL)animated {
    %orig;
    [MediaSaver attachToController:self];
}

- (void)viewDidLayoutSubviews {
    %orig;
    UIView *btn = [self.view viewWithTag:998811];
    if (btn) {
        [self.view bringSubviewToFront:btn];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    %orig;
    [MediaSaver detachFromController:self animated:animated];
}

- (void)wa_applicationDidEnterBackground {
    if (WATweakGetBool(kDisableScreenshotDetection, YES)) {
        return;
    }
    %orig;
}

%end

%hook WAGenericMediaBrowserViewController

- (void)viewDidAppear:(BOOL)animated {
    %orig;
    [MediaSaver attachToController:self];
}

- (void)viewDidLayoutSubviews {
    %orig;
    UIView *btn = [self.view viewWithTag:998811];
    if (btn) {
        [self.view bringSubviewToFront:btn];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    %orig;
    [MediaSaver detachFromController:self animated:animated];
}

- (void)verifyScreenshotProtection {
    if (WATweakGetBool(kDisableScreenshotDetection, YES)) {
        return;
    }
    %orig;
}

- (void)showScreenshotBlockedToast {
    if (WATweakGetBool(kDisableScreenshotDetection, YES)) {
        return;
    }
    %orig;
}

- (void)userDidTakeScreenshot:(id)arg1 {
    if (WATweakGetBool(kDisableScreenshotDetection, YES)) {
        return;
    }
    %orig;
}

%end

%hook WAMediaBrowserViewController

- (void)viewDidAppear:(BOOL)animated {
    %orig;
    [MediaSaver attachToController:self];
}

- (void)viewDidLayoutSubviews {
    %orig;
    UIView *btn = [self.view viewWithTag:998811];
    if (btn) {
        [self.view bringSubviewToFront:btn];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    %orig;
    [MediaSaver detachFromController:self animated:animated];
}

- (void)userDidTakeScreenshot:(id)arg1 {
    if (WATweakGetBool(kDisableScreenshotDetection, YES)) {
        return;
    }
    %orig;
}

%end

%hook WAStatusViewerViewController

- (void)viewDidAppear:(BOOL)animated {
    %orig;
    [MediaSaver attachToController:self];
}

- (void)viewDidLayoutSubviews {
    %orig;
    UIView *btn = [self.view viewWithTag:998811];
    if (btn) {
        [self.view bringSubviewToFront:btn];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    %orig;
    [MediaSaver detachFromController:self animated:animated];
}

- (void)viewerDidTakeScreenshot:(id)arg1 {
    if (WATweakGetBool(kDisableScreenshotDetection, YES)) {
        return;
    }
    %orig;
}

%end

%hook WAPictureContainerViewControllerV3

- (void)viewDidAppear:(BOOL)animated {
    %orig;
    [MediaSaver attachToController:self];
}

- (void)viewDidLayoutSubviews {
    %orig;
    UIView *btn = [self.view viewWithTag:998811];
    if (btn) {
        [self.view bringSubviewToFront:btn];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    %orig;
    [MediaSaver detachFromController:self animated:animated];
}

- (void)installProfilePictureScreenshotProtectionIfNeeded {
    if (WATweakGetBool(kDisableScreenshotDetection, YES)) {
        return;
    }
    %orig;
}

- (BOOL)profilePictureScreenshotProtectionInstalled {
    if (WATweakGetBool(kDisableScreenshotDetection, YES)) {
        return NO;
    }
    return %orig;
}

- (void)profilePictureUserDidTakeScreenshot:(id)arg1 {
    if (WATweakGetBool(kDisableScreenshotDetection, YES)) {
        return;
    }
    %orig;
}

%end

%hook UIViewController

- (void)viewDidAppear:(BOOL)animated {
    %orig;
    if ([MediaSaver isMediaViewerController:self]) {
        [MediaSaver attachToController:self];
    }
}

%end

#pragma mark - 7. Screenshot Detection & Protection Bypass

%hook WABlockScreenshotViewProvider

- (id)initWithIsProtected:(BOOL)arg1 {
    self = %orig(arg1);
    if (WATweakGetBool(kDisableScreenshotDetection, YES)) {
        if (self) {
            [self setIsProtected:NO];
        }
    }
    return self;
}

- (BOOL)isProtected {
    if (WATweakGetBool(kDisableScreenshotDetection, YES)) {
        return NO;
    }
    return %orig;
}

- (void)setIsProtected:(BOOL)arg1 {
    if (WATweakGetBool(kDisableScreenshotDetection, YES)) {
        %orig(NO);
        return;
    }
    %orig;
}

- (BOOL)isOsCompatibleForDescriptionView {
    if (WATweakGetBool(kDisableScreenshotDetection, YES)) {
        return NO;
    }
    return %orig;
}

- (void)addSnapshotView:(id)arg1 {
    if (WATweakGetBool(kDisableScreenshotDetection, YES)) {
        return;
    }
    %orig;
}

%end

%hook WABlockScreenshotDescriptionView

- (id)initWithConfiguration:(id)config {
    self = %orig;
    if (WATweakGetBool(kDisableScreenshotDetection, YES)) {
        if (self) {
            self.hidden = YES;
            self.alpha = 0.0;
            self.userInteractionEnabled = NO;
        }
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = %orig(frame);
    if (WATweakGetBool(kDisableScreenshotDetection, YES)) {
        if (self) {
            self.hidden = YES;
            self.alpha = 0.0;
            self.userInteractionEnabled = NO;
        }
    }
    return self;
}

- (void)layoutSubviews {
    %orig;
    if (WATweakGetBool(kDisableScreenshotDetection, YES)) {
        self.hidden = YES;
        self.alpha = 0.0;
        self.userInteractionEnabled = NO;
    }
}

- (void)didMoveToWindow {
    %orig;
    if (WATweakGetBool(kDisableScreenshotDetection, YES)) {
        self.hidden = YES;
        self.alpha = 0.0;
        self.userInteractionEnabled = NO;
    }
}

- (void)didMoveToSuperview {
    %orig;
    if (WATweakGetBool(kDisableScreenshotDetection, YES)) {
        self.hidden = YES;
        self.alpha = 0.0;
        self.userInteractionEnabled = NO;
    }
}

%end

%hook WhatsAppAppDelegate

- (void)applicationUserDidTakeScreenshot:(id)arg1 {
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

%hook UITextField

- (void)setSecureTextEntry:(BOOL)enabled {
    if (enabled && WATweakGetBool(kDisableScreenshotDetection, YES)) {
        %orig(NO);
        return;
    }
    %orig;
}

%end

%hook UIView

- (void)_setSecureContents:(BOOL)secure {
    if (WATweakGetBool(kDisableScreenshotDetection, YES)) {
        return;
    }
    %orig;
}

%end

%hook NSNotificationCenter

- (void)postNotificationName:(NSNotificationName)aName object:(id)anObject userInfo:(NSDictionary *)aUserInfo {
    if ([aName isEqualToString:UIApplicationUserDidTakeScreenshotNotification] && WATweakGetBool(kDisableScreenshotDetection, YES)) {
        return;
    }
    %orig(aName, anObject, aUserInfo);
}

- (void)postNotification:(NSNotification *)notification {
    if ([notification.name isEqualToString:UIApplicationUserDidTakeScreenshotNotification] && WATweakGetBool(kDisableScreenshotDetection, YES)) {
        return;
    }
    %orig(notification);
}

%end

%hook UIScreen

- (BOOL)isCaptured {
    if (WATweakGetBool(kDisableScreenRecordingPause, YES)) {
        return NO;
    }
    return %orig;
}

%end

#pragma mark - 8. Tweak Menu Trigger (Long-press on Help and Feedback) & Clean UI

static NSString *findTextRecursively(UIView *view) {
    if ([view isKindOfClass:[UILabel class]]) {
        NSString *t = [(UILabel *)view text];
        if (t.length > 0) {
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

static BOOL isMetaTrashString(NSString *str) {
    if (!str || str.length == 0) return NO;
    NSString *s = [str lowercaseString];
    if ([s containsString:@"subscription"] || [s containsString:@"подписк"]) return YES;
    if ([s containsString:@"account center"] || [s containsString:@"accounts center"] ||
        [s containsString:@"центр аккаунтов"] || [s containsString:@"центр учетных записей"]) return YES;
    if ([s containsString:@"also from meta"] || [s containsString:@"from meta"] || [s containsString:@"от meta"]) return YES;
    return NO;
}

static BOOL isMetaTrashRow(id row) {
    if (!row) return NO;
    @try {
        if ([row respondsToSelector:@selector(text)]) {
            id t = [row performSelector:@selector(text)];
            if ([t isKindOfClass:[NSString class]] && isMetaTrashString((NSString *)t)) return YES;
        }
        if ([row respondsToSelector:@selector(detailText)]) {
            id d = [row performSelector:@selector(detailText)];
            if ([d isKindOfClass:[NSString class]] && isMetaTrashString((NSString *)d)) return YES;
        }
        NSString *rowCls = NSStringFromClass([row class]);
        if ([rowCls containsString:@"FOA"] || [rowCls containsString:@"Bookmark"] || [rowCls containsString:@"AccountsCenter"]) return YES;
    } @catch (NSException *e) {}
    return NO;
}

static BOOL isMetaTrashSection(id section) {
    if (!section) return NO;
    @try {
        NSString *secCls = NSStringFromClass([section class]);
        if ([secCls containsString:@"FOA"] || [secCls containsString:@"AccountsCenter"]) return YES;
        if ([section respondsToSelector:@selector(headerTitle)]) {
            id h = [section performSelector:@selector(headerTitle)];
            if ([h isKindOfClass:[NSString class]] && isMetaTrashString((NSString *)h)) return YES;
        }
        if ([section respondsToSelector:@selector(footerTitle)]) {
            id f = [section performSelector:@selector(footerTitle)];
            if ([f isKindOfClass:[NSString class]] && isMetaTrashString((NSString *)f)) return YES;
        }
        if ([section respondsToSelector:@selector(rows)]) {
            NSArray *rows = [section performSelector:@selector(rows)];
            if ([rows isKindOfClass:[NSArray class]] && rows.count > 0) {
                BOOL allTrash = YES;
                for (id r in rows) {
                    if (!isMetaTrashRow(r)) {
                        allTrash = NO;
                        break;
                    }
                }
                if (allTrash) return YES;
            }
        }
    } @catch (NSException *e) {}
    return NO;
}

static void recursivelyHideMetaAI(UIView *view) {
    if (!view) return;
    @try {
        NSString *clsName = NSStringFromClass([view class]);
        if ([clsName containsString:@"FloatingActionButton"] ||
            [clsName containsString:@"MetaAI"] ||
            [clsName containsString:@"WAAIViews"] ||
            [clsName containsString:@"AIHeader"] ||
            [clsName containsString:@"AIBadge"]) {
            view.hidden = YES;
            view.alpha = 0.0;
            view.userInteractionEnabled = NO;
            [view removeFromSuperview];
            return;
        }
        
        if ([view isKindOfClass:[UILabel class]]) {
            NSString *txt = [(UILabel *)view text] ?: @"";
            if ([txt rangeOfString:@"Meta AI" options:NSCaseInsensitiveSearch].location != NSNotFound) {
                view.hidden = YES;
                view.alpha = 0.0;
                view.userInteractionEnabled = NO;
            }
        }
        
        NSString *acc = view.accessibilityLabel ?: @"";
        if ([acc rangeOfString:@"Meta AI" options:NSCaseInsensitiveSearch].location != NSNotFound) {
            view.hidden = YES;
            view.alpha = 0.0;
            view.userInteractionEnabled = NO;
        }
        
        for (UIView *sub in [view.subviews copy]) {
            recursivelyHideMetaAI(sub);
        }
    } @catch (NSException *e) {}
}

static void watweak_filterChatListNavBarButtons(UIViewController *vc) {
    if (!vc || !WATweakGetBool(kHideMetaAI, YES)) return;
    @try {
        NSMutableArray *filtered = [NSMutableArray array];
        for (UIBarButtonItem *item in vc.navigationItem.rightBarButtonItems) {
            BOOL isMetaAI = NO;
            SEL act = item.action;
            NSString *selName = act ? NSStringFromSelector(act) : @"";
            if ([selName containsString:@"metaAI"] || [selName containsString:@"MetaAI"]) {
                isMetaAI = YES;
            }
            NSString *label = item.accessibilityLabel ?: @"";
            if ([label rangeOfString:@"Meta AI" options:NSCaseInsensitiveSearch].location != NSNotFound) {
                isMetaAI = YES;
            }
            if (item.customView) {
                NSString *cvCls = NSStringFromClass([item.customView class]);
                if ([cvCls containsString:@"MetaAI"] || [cvCls containsString:@"AI"]) {
                    isMetaAI = YES;
                }
            }
            if (!isMetaAI) {
                [filtered addObject:item];
            }
        }
        if (filtered.count != vc.navigationItem.rightBarButtonItems.count) {
            vc.navigationItem.rightBarButtonItems = filtered;
        }
    } @catch (NSException *e) {}
}

%hook WASettingsViewController

- (void)addSubscriptionsRowIfEligibleToSection:(id)arg1 {
    if (WATweakGetBool(kHideMetaTrash, YES)) {
        return;
    }
    %orig;
}

- (void)addSubscriptionsRowToSection:(id)arg1 {
    if (WATweakGetBool(kHideMetaTrash, YES)) {
        return;
    }
    %orig;
}

- (BOOL)isSubscriptionsRowPresentInTable {
    if (WATweakGetBool(kHideMetaTrash, YES)) {
        return NO;
    }
    return %orig;
}

- (BOOL)isSubscriptionsRowOffered {
    if (WATweakGetBool(kHideMetaTrash, YES)) {
        return NO;
    }
    return %orig;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (WATweakGetBool(kHideMetaTrash, YES)) {
        @try {
            id row = [self rowAtIndexPath:indexPath];
            if (isMetaTrashRow(row)) return 0.001f;
            id sec = [self sectionAtIndex:indexPath.section];
            if (isMetaTrashSection(sec)) return 0.001f;
        } @catch (NSException *e) {}
    }
    return %orig;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (WATweakGetBool(kHideMetaTrash, YES)) {
        @try {
            id sec = [self sectionAtIndex:section];
            if (isMetaTrashSection(sec)) return 0.001f;
        } @catch (NSException *e) {}
    }
    return %orig;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (WATweakGetBool(kHideMetaTrash, YES)) {
        @try {
            id sec = [self sectionAtIndex:section];
            if (isMetaTrashSection(sec)) return 0.001f;
            NSArray *secs = [self sections];
            if (secs && section >= (NSInteger)secs.count - 1) {
                return 0.001f;
            }
        } @catch (NSException *e) {}
    }
    return %orig;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (WATweakGetBool(kHideMetaTrash, YES)) {
        @try {
            id sec = [self sectionAtIndex:section];
            if (isMetaTrashSection(sec)) {
                return [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0.001f)];
            }
        } @catch (NSException *e) {}
    }
    return %orig;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if (WATweakGetBool(kHideMetaTrash, YES)) {
        @try {
            id sec = [self sectionAtIndex:section];
            if (isMetaTrashSection(sec)) {
                return [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0.001f)];
            }
            NSArray *secs = [self sections];
            if (secs && section >= (NSInteger)secs.count - 1) {
                return [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0.001f)];
            }
        } @catch (NSException *e) {}
    }
    return %orig;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (WATweakGetBool(kHideMetaTrash, YES)) {
        @try {
            id row = [self rowAtIndexPath:indexPath];
            if (isMetaTrashRow(row)) {
                [tableView deselectRowAtIndexPath:indexPath animated:NO];
                return;
            }
            id sec = [self sectionAtIndex:indexPath.section];
            if (isMetaTrashSection(sec)) {
                [tableView deselectRowAtIndexPath:indexPath animated:NO];
                return;
            }
        } @catch (NSException *e) {}
    }
    %orig;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    %orig;
    
    // Inspect cell text for Help / Help and Feedback or Meta Trash
    NSString *cellText = cell.textLabel.text ?: @"";
    if (cellText.length == 0) {
        cellText = findTextRecursively(cell.contentView) ?: @"";
    }
    
    // Hide Meta trash rows if any slipped through
    BOOL isTrash = NO;
    if (WATweakGetBool(kHideMetaTrash, YES)) {
        if (isMetaTrashString(cellText)) {
            isTrash = YES;
        } else {
            NSString *cellCls = NSStringFromClass([cell class]);
            if ([cellCls containsString:@"FOA"] || [cellCls containsString:@"Bookmark"] || [cellCls containsString:@"AccountsCenter"]) {
                isTrash = YES;
            } else {
                @try {
                    id row = [self rowAtIndexPath:indexPath];
                    if (isMetaTrashRow(row)) isTrash = YES;
                    else {
                        id sec = [self sectionAtIndex:indexPath.section];
                        if (isMetaTrashSection(sec)) isTrash = YES;
                    }
                } @catch (NSException *e) {}
            }
        }
    }
    
    if (isTrash) {
        cell.hidden = YES;
        cell.contentView.hidden = YES;
        cell.clipsToBounds = YES;
        cell.alpha = 0.0;
        cell.userInteractionEnabled = NO;
        return;
    }
    
    // Ensure Lists has rounded top corners
    if ([cellText rangeOfString:@"Lists" options:NSCaseInsensitiveSearch].location != NSNotFound ||
        [cellText rangeOfString:@"Списки" options:NSCaseInsensitiveSearch].location != NSNotFound) {
        NSInteger totalRows = 0;
        @try {
            totalRows = [tableView numberOfRowsInSection:indexPath.section];
        } @catch (NSException *e) {}
        
        if (totalRows <= 1) {
            cell.layer.cornerRadius = 12.0;
            cell.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner | kCALayerMinXMaxYCorner | kCALayerMaxXMaxYCorner;
        } else {
            cell.layer.cornerRadius = 12.0;
            cell.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
        }
        cell.layer.masksToBounds = YES;
        cell.clipsToBounds = YES;
    }
    
    // Help / Feedback long-press gesture for opening tweak menu
    BOOL isHelp = [cellText rangeOfString:@"Help" options:NSCaseInsensitiveSearch].location != NSNotFound ||
                  [cellText rangeOfString:@"Feedback" options:NSCaseInsensitiveSearch].location != NSNotFound;
    
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

- (void)viewWillAppear:(BOOL)animated {
    %orig;
    if (WATweakGetBool(kHideMetaTrash, YES)) {
        @try {
            if ([self respondsToSelector:@selector(tableView)]) {
                UITableView *tv = [self tableView];
                if (tv.tableFooterView && tv.tableFooterView.frame.size.height > 0.1) {
                    tv.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tv.bounds.size.width, 0.001f)];
                }
            }
        } @catch (NSException *e) {}
    }
}

- (void)viewDidLayoutSubviews {
    %orig;
    if (WATweakGetBool(kHideMetaTrash, YES)) {
        @try {
            if ([self respondsToSelector:@selector(tableView)]) {
                UITableView *tv = [self tableView];
                if (tv.tableFooterView && tv.tableFooterView.frame.size.height > 0.1) {
                    tv.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tv.bounds.size.width, 0.001f)];
                }
            }
        } @catch (NSException *e) {}
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

%hook WAProfileViewController

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    %orig;
    if (WATweakGetBool(kHideMetaTrash, YES)) {
        NSString *cellText = cell.textLabel.text ?: findTextRecursively(cell.contentView);
        if (isMetaTrashString(cellText)) {
            cell.hidden = YES;
            cell.contentView.hidden = YES;
            cell.clipsToBounds = YES;
            cell.alpha = 0.0;
            cell.userInteractionEnabled = NO;
        }
    }
}

%end

#pragma mark - 9. Clean UI & Anti-Meta AI

%hook WATabBarController

- (void)addAIFABIfNeeded {
    if (WATweakGetBool(kHideMetaAI, YES)) {
        return;
    }
    %orig;
}

- (void)updateAIFABStateIfNeeded {
    if (WATweakGetBool(kHideMetaAI, YES)) {
        return;
    }
    %orig;
}

- (void)updateAIFabStateIfTabChanged {
    if (WATweakGetBool(kHideMetaAI, YES)) {
        return;
    }
    %orig;
}

- (void)updateAIFABStateForShouldSelect:(id)arg1 {
    if (WATweakGetBool(kHideMetaAI, YES)) {
        return;
    }
    %orig(arg1);
}

- (void)updateAIFABVisibility {
    if (WATweakGetBool(kHideMetaAI, YES)) {
        return;
    }
    %orig;
}

- (void)updateAIFABBottomConstraintIfNeeded {
    if (WATweakGetBool(kHideMetaAI, YES)) {
        return;
    }
    %orig;
}

- (void)viewWillAppear:(BOOL)animated {
    %orig;
    if (WATweakGetBool(kHideMetaAI, YES)) {
        @try {
            for (UIViewController *child in self.childViewControllers) {
                NSString *cls = NSStringFromClass([child class]);
                if ([cls containsString:@"FloatingActionButton"] || [cls containsString:@"AIFAB"]) {
                    child.view.hidden = YES;
                    child.view.alpha = 0.0;
                    child.view.userInteractionEnabled = NO;
                    [child.view removeFromSuperview];
                }
            }
        } @catch (NSException *e) {}
    }
}

- (void)viewDidAppear:(BOOL)animated {
    %orig;
    if (WATweakGetBool(kHideMetaAI, YES)) {
        @try {
            for (UIViewController *child in self.childViewControllers) {
                NSString *cls = NSStringFromClass([child class]);
                if ([cls containsString:@"FloatingActionButton"] || [cls containsString:@"AIFAB"]) {
                    child.view.hidden = YES;
                    child.view.alpha = 0.0;
                    child.view.userInteractionEnabled = NO;
                    [child.view removeFromSuperview];
                }
            }
        } @catch (NSException *e) {}
    }
}

%end

%hook _TtC9WAAIViews34FloatingActionButtonViewController

- (void)loadView {
    if (WATweakGetBool(kHideMetaAI, YES)) {
        UIView *dummy = [[UIView alloc] initWithFrame:CGRectZero];
        dummy.hidden = YES;
        dummy.alpha = 0.0;
        dummy.userInteractionEnabled = NO;
        self.view = dummy;
        return;
    }
    %orig;
}

- (void)viewDidLoad {
    if (WATweakGetBool(kHideMetaAI, YES)) {
        self.view.hidden = YES;
        self.view.alpha = 0.0;
        self.view.userInteractionEnabled = NO;
        self.view.frame = CGRectZero;
        [self.view removeFromSuperview];
        return;
    }
    %orig;
}

- (void)viewWillAppear:(BOOL)animated {
    if (WATweakGetBool(kHideMetaAI, YES)) {
        self.view.hidden = YES;
        self.view.alpha = 0.0;
        self.view.userInteractionEnabled = NO;
        self.view.frame = CGRectZero;
        [self.view removeFromSuperview];
        return;
    }
    %orig;
}

- (void)viewDidAppear:(BOOL)animated {
    if (WATweakGetBool(kHideMetaAI, YES)) {
        self.view.hidden = YES;
        self.view.alpha = 0.0;
        self.view.userInteractionEnabled = NO;
        self.view.frame = CGRectZero;
        [self.view removeFromSuperview];
        return;
    }
    %orig;
}

- (void)viewDidLayoutSubviews {
    if (WATweakGetBool(kHideMetaAI, YES)) {
        self.view.hidden = YES;
        self.view.alpha = 0.0;
        self.view.userInteractionEnabled = NO;
        [self.view removeFromSuperview];
        return;
    }
    %orig;
}

%end

%hook _TtC9WAAIViews29FloatingActionButtonViewModel

- (BOOL)isFloatingActionButtonVisible {
    if (WATweakGetBool(kHideMetaAI, YES)) {
        return NO;
    }
    return %orig;
}

%end

%hook _TtC25WAChatListViewControllers39ChatListAIFloatingActionButtonViewModel

- (BOOL)isFloatingActionButtonVisible {
    if (WATweakGetBool(kHideMetaAI, YES)) {
        return NO;
    }
    return %orig;
}

%end

%hook WAChatListViewController

- (BOOL)metaAIFloatingButtonEnabled {
    if (WATweakGetBool(kHideMetaAI, YES)) {
        return NO;
    }
    return %orig;
}

- (BOOL)metaAIFloatingButtonRefactorEnabled {
    if (WATweakGetBool(kHideMetaAI, YES)) {
        return NO;
    }
    return %orig;
}

- (BOOL)isMetaAIInTabEnabled {
    if (WATweakGetBool(kHideMetaAI, YES)) {
        return NO;
    }
    return %orig;
}

- (id)navBarMetaAIButton {
    if (WATweakGetBool(kHideMetaAI, YES)) {
        return nil;
    }
    return %orig;
}

- (id)chatListNavigationMetaAIButton {
    if (WATweakGetBool(kHideMetaAI, YES)) {
        return nil;
    }
    return %orig;
}

- (BOOL)chatListNavigationMetaAIFloatingButtonEnabled {
    if (WATweakGetBool(kHideMetaAI, YES)) {
        return NO;
    }
    return %orig;
}

- (BOOL)isChatListMetaAIEntryPointEnabled {
    if (WATweakGetBool(kHideMetaAI, YES)) {
        return NO;
    }
    return %orig;
}

- (void)addMetaAIFloatingButtonAsSubviewIfNeeded {
    if (WATweakGetBool(kHideMetaAI, YES)) {
        return;
    }
    %orig;
}

- (void)setupMetaAIFloatingButton {
    if (WATweakGetBool(kHideMetaAI, YES)) {
        return;
    }
    %orig;
}

- (void)viewDidLoad {
    %orig;
    if (WATweakGetBool(kHideMetaAI, YES)) {
        watweak_filterChatListNavBarButtons(self);
        recursivelyHideMetaAI(self.view);
    }
}

- (void)viewWillAppear:(BOOL)animated {
    %orig;
    if (WATweakGetBool(kHideMetaAI, YES)) {
        watweak_filterChatListNavBarButtons(self);
        if ([self respondsToSelector:@selector(metaAIFloatingButton)]) {
            UIView *btn = [self metaAIFloatingButton];
            if ([btn isKindOfClass:[UIView class]]) {
                btn.hidden = YES;
                btn.alpha = 0.0;
                btn.userInteractionEnabled = NO;
                [btn removeFromSuperview];
            }
        }
        recursivelyHideMetaAI(self.view);
    }
}

- (void)viewDidAppear:(BOOL)animated {
    %orig;
    if (WATweakGetBool(kHideMetaAI, YES)) {
        watweak_filterChatListNavBarButtons(self);
        recursivelyHideMetaAI(self.view);
    }
}

- (void)viewDidLayoutSubviews {
    %orig;
    if (WATweakGetBool(kHideMetaAI, YES)) {
        watweak_filterChatListNavBarButtons(self);
        if ([self respondsToSelector:@selector(metaAIFloatingButton)]) {
            UIView *btn = [self metaAIFloatingButton];
            if ([btn isKindOfClass:[UIView class]]) {
                btn.hidden = YES;
                btn.alpha = 0.0;
                btn.userInteractionEnabled = NO;
                [btn removeFromSuperview];
            }
        }
        recursivelyHideMetaAI(self.view);
    }
}

- (void)updateRightBarButtonItems {
    %orig;
    if (WATweakGetBool(kHideMetaAI, YES)) {
        watweak_filterChatListNavBarButtons(self);
    }
}

- (void)updateNavigationBarButtons {
    %orig;
    if (WATweakGetBool(kHideMetaAI, YES)) {
        watweak_filterChatListNavBarButtons(self);
    }
}

%end

%hook WAMetaAIHeaderView

- (id)initWithFrame:(CGRect)frame {
    if (WATweakGetBool(kHideMetaAI, YES)) {
        self = %orig(CGRectZero);
        if (self) {
            self.hidden = YES;
            self.alpha = 0.0;
            self.userInteractionEnabled = NO;
        }
        return self;
    }
    return %orig;
}

- (void)didMoveToWindow {
    %orig;
    if (WATweakGetBool(kHideMetaAI, YES)) {
        self.hidden = YES;
        self.alpha = 0.0;
        self.userInteractionEnabled = NO;
        self.frame = CGRectZero;
    }
}

- (void)didMoveToSuperview {
    %orig;
    if (WATweakGetBool(kHideMetaAI, YES)) {
        self.hidden = YES;
        self.alpha = 0.0;
        self.userInteractionEnabled = NO;
        self.frame = CGRectZero;
    }
}

%end

%hook WASearchControllerViewController

- (void)viewDidLoad {
    %orig;
    if (WATweakGetBool(kHideMetaAI, YES)) {
        recursivelyHideMetaAI(self.view);
    }
}

- (void)viewWillAppear:(BOOL)animated {
    %orig;
    if (WATweakGetBool(kHideMetaAI, YES)) {
        recursivelyHideMetaAI(self.view);
    }
}

- (void)viewDidLayoutSubviews {
    %orig;
    if (WATweakGetBool(kHideMetaAI, YES)) {
        recursivelyHideMetaAI(self.view);
    }
}

%end

#pragma mark - 10. Privacy & Telemetry Blocking

static BOOL isTelemetryURL(NSURL *url) {
    if (!url) return NO;
    NSString *host = [[url host] lowercaseString] ?: @"";
    NSString *path = [[url path] lowercaseString] ?: @"";
    
    // Whitelist core WhatsApp communication endpoints
    if ([host containsString:@"whatsapp.net"] || [host containsString:@"whatsapp.com"]) {
        if (![path containsString:@"crash_reports"] && 
            ![path containsString:@"/falco"] && 
            ![path containsString:@"logging"]) {
            return NO;
        }
    }
    
    // Meta / Facebook analytics, tracking & FOA bridges
    if ([host containsString:@"graph.facebook.com"] ||
        [host containsString:@"graph.instagram.com"] ||
        [host containsString:@"edge-mqtt.facebook.com"] ||
        [host containsString:@"meta.privacy-gateway.cloudflare.com"] ||
        [host containsString:@"teellm.meta.com"] ||
        [path containsString:@"logging_client_events"] ||
        [path containsString:@"/falco"]) {
        return YES;
    }
    
    // Google Analytics / Firebase / Crashlytics
    if ([host containsString:@"app-measurement.com"] ||
        [host containsString:@"google-analytics.com"] ||
        [host containsString:@"crashlytics.com"] ||
        [host containsString:@"firebaseinstallations.googleapis.com"] ||
        [host containsString:@"firebaselogging.googleapis.com"]) {
        return YES;
    }
    
    // Crash and client event telemetry endpoints
    if ([path containsString:@"crash_reports"] || [path containsString:@"client_event"]) {
        return YES;
    }
    
    return NO;
}

@interface WATweakTelemetryBlockerProtocol : NSURLProtocol
@end

@implementation WATweakTelemetryBlockerProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    if (!WATweakGetBool(kDisableTelemetry, YES)) {
        return NO;
    }
    return isTelemetryURL(request.URL);
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}

- (void)startLoading {
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:self.request.URL
                                                              statusCode:200
                                                             HTTPVersion:@"HTTP/1.1"
                                                            headerFields:@{@"Content-Length": @"0"}];
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    [self.client URLProtocolDidFinishLoading:self];
}

- (void)stopLoading {
}

@end

%hook NSURLSessionConfiguration

- (NSArray<Class> *)protocolClasses {
    NSArray *orig = %orig;
    if (WATweakGetBool(kDisableTelemetry, YES)) {
        NSMutableArray *arr = [orig mutableCopy] ?: [NSMutableArray array];
        if (![arr containsObject:[WATweakTelemetryBlockerProtocol class]]) {
            [arr insertObject:[WATweakTelemetryBlockerProtocol class] atIndex:0];
        }
        return arr;
    }
    return orig;
}

%end

%hook WAFieldStats

- (void)logEvent:(id)arg1 {
    if (WATweakGetBool(kDisableTelemetry, YES)) {
        return;
    }
    %orig;
}

- (void)logEvent:(id)arg1 weight:(NSInteger)arg2 {
    if (WATweakGetBool(kDisableTelemetry, YES)) {
        return;
    }
    %orig;
}

- (void)logEvent:(id)arg1 weight:(NSInteger)arg2 eventObject:(id)arg3 {
    if (WATweakGetBool(kDisableTelemetry, YES)) {
        return;
    }
    %orig;
}

- (void)logEvent:(id)arg1 samplingRate:(id)arg2 {
    if (WATweakGetBool(kDisableTelemetry, YES)) {
        return;
    }
    %orig;
}

- (void)uploadStatsWithCompletion:(id)completion {
    if (WATweakGetBool(kDisableTelemetry, YES)) {
        if (completion) {
            void (^block)(BOOL) = (void (^)(BOOL))completion;
            block(YES);
        }
        return;
    }
    %orig;
}

%end

%hook WALogUploader

- (void)uploadCrashLogsForAllDirectories {
    if (WATweakGetBool(kDisableTelemetry, YES)) {
        return;
    }
    %orig;
}

- (void)uploadCriticalAndStallLogsForAllDirectories {
    if (WATweakGetBool(kDisableTelemetry, YES)) {
        return;
    }
    %orig;
}

- (void)uploadLogs:(id)arg1 {
    if (WATweakGetBool(kDisableTelemetry, YES)) {
        return;
    }
    %orig;
}

- (void)uploadLog:(id)arg1 logUploadRequest:(id)arg2 withCompletion:(id)arg3 {
    if (WATweakGetBool(kDisableTelemetry, YES)) {
        if (arg3) {
            void (^block)(BOOL, NSError *) = (void (^)(BOOL, NSError *))arg3;
            block(YES, nil);
        }
        return;
    }
    %orig;
}

%end

%ctor {
    @autoreleasepool {
        [NSURLProtocol registerClass:[WATweakTelemetryBlockerProtocol class]];
    }
}
