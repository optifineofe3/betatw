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

%hook WAStaticTableViewController

- (void)addSection:(id)section {
    if (!section) return;
    if (WATweakGetBool(kHideMetaTrash, YES)) {
        @try {
            NSString *secCls = NSStringFromClass([section class]);
            if ([secCls containsString:@"FOA"] || [secCls containsString:@"Meta"] || [secCls containsString:@"AccountsCenter"]) {
                return;
            }
            if ([section respondsToSelector:@selector(headerTitle)]) {
                NSString *h = [section performSelector:@selector(headerTitle)];
                if (isMetaTrashString(h)) return;
            }
            if ([section respondsToSelector:@selector(footerTitle)]) {
                NSString *f = [section performSelector:@selector(footerTitle)];
                if (isMetaTrashString(f)) return;
            }
        } @catch (NSException *e) {}
    }
    %orig(section);
}

%end

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

- (id)makeAccountsCenterSection {
    if (WATweakGetBool(kHideMetaTrash, YES)) {
        return nil;
    }
    return %orig;
}

- (id)makeAlsoFromMetaSection {
    if (WATweakGetBool(kHideMetaTrash, YES)) {
        return nil;
    }
    return %orig;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    %orig;
    
    // Inspect cell text for Help / Help and Feedback or Meta Trash
    NSString *cellText = cell.textLabel.text ?: @"";
    if (cellText.length == 0) {
        cellText = findTextRecursively(cell.contentView) ?: @"";
    }
    
    // Hide Meta trash rows if any slipped through
    if (WATweakGetBool(kHideMetaTrash, YES) && isMetaTrashString(cellText)) {
        cell.hidden = YES;
        cell.contentView.hidden = YES;
        cell.clipsToBounds = YES;
        return;
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
                if (tv.tableFooterView) {
                    NSString *footerCls = NSStringFromClass([tv.tableFooterView class]);
                    if ([footerCls containsString:@"FOA"] || [footerCls containsString:@"Meta"] || [footerCls containsString:@"Bridge"] || [footerCls containsString:@"HScroll"]) {
                        tv.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, CGFLOAT_MIN)];
                    }
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

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    %orig;
    if (WATweakGetBool(kHideMetaTrash, YES)) {
        NSString *cellText = cell.textLabel.text ?: findTextRecursively(cell.contentView);
        if (isMetaTrashString(cellText)) {
            cell.hidden = YES;
            cell.contentView.hidden = YES;
            cell.clipsToBounds = YES;
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

%hook _TtC17WAFOABridgesViews36WAFOAHScrollCollectionViewController

- (void)loadView {
    if (WATweakGetBool(kHideMetaTrash, YES)) {
        UIView *v = [[UIView alloc] initWithFrame:CGRectZero];
        v.hidden = YES;
        v.alpha = 0.0;
        v.userInteractionEnabled = NO;
        self.view = v;
        return;
    }
    %orig;
}

- (void)viewDidLoad {
    if (WATweakGetBool(kHideMetaTrash, YES)) {
        self.view.hidden = YES;
        self.view.alpha = 0.0;
        self.view.userInteractionEnabled = NO;
        [self.view removeFromSuperview];
        return;
    }
    %orig;
}

- (void)viewWillAppear:(BOOL)animated {
    if (WATweakGetBool(kHideMetaTrash, YES)) {
        self.view.hidden = YES;
        self.view.alpha = 0.0;
        self.view.userInteractionEnabled = NO;
        [self.view removeFromSuperview];
        return;
    }
    %orig;
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
