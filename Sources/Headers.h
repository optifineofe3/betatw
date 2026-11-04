#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <Intents/Intents.h>
#import <Contacts/Contacts.h>
#import <Security/Security.h>
#import "Logger.h"

@interface WAMultiSendMediaItemQuality : NSObject
+ (id)fullQuality;
+ (id)documentImageQuality;
+ (id)chatQuality;
+ (id)defaultChatQuality;
+ (id)hdQuality;
+ (NSUInteger)maximumValidImageEdge;
- (CGFloat)imageQuality;
- (NSUInteger)imageMaximumEdge;
- (NSUInteger)imageMaximumFileSize;
- (NSUInteger)videoMaximumWidth;
- (NSUInteger)videoMaximumHeight;
- (NSUInteger)videoMaximumBitrate;
@end

@interface UITTranscodeConfig : NSObject
- (CGFloat)maxCompressionQuality;
- (CGFloat)minCompressionQuality;
- (void)setMaxCompressionQuality:(CGFloat)quality;
- (void)setMinCompressionQuality:(CGFloat)quality;
@end

@interface WAJPEGProcessor : NSObject
+ (id)encodeFromUrlWithInputImageUrl:(id)arg1 outputImageUrl:(id)arg2 targetSize:(CGSize)arg3 imageQuality:(CGFloat)arg4 peakMemoryUseBytes:(NSUInteger)arg5 isHDImage:(BOOL)arg6 pjpegScans:(id)arg7 uitConfig:(id)arg8 abProperties:(id)arg9 progressCallback:(id)arg10 parseError:(id)arg11;
@end

@interface XMPPPresenceControllerMain : NSObject
- (void)sendPresence;
- (void)sendPresenceWithNickname:(NSString *)nickname;
- (void)reallySendPresenceWithNickname:(NSString *)nickname presence:(NSUInteger)presence;
- (void)sendPresenceWithNickname:(NSString *)nickname deviceAvailable:(BOOL)deviceAvailable;
@end

@interface XMPPConnectionMain : NSObject
+ (BOOL)shouldSendReadReceiptForMessage:(id)message userContext:(id)userContext;
- (void)sendReadReceiptsForMessagesIfNeeded:(id)messages;
@end

@interface WAChatViewController : UIViewController
- (void)changeOutgoingChatState:(NSUInteger)state forChatJID:(id)jid;
- (void)chatStorageDidRevokeMessages:(id)messages;
- (void)chatStorageWillRevokeMessages:(id)messages;
@end

@interface WAChatManager : NSObject
- (void)markChatSessions:(id)sessions read:(BOOL)read sendReadReceipts:(BOOL)sendReadReceipts error:(id *)error;
- (void)sendReadReceiptsForMessagesBeforeAndIncludingMessage:(id)message inChatSession:(id)session isMarkedByUser:(BOOL)isMarkedByUser;
- (void)markStatusAsSeen:(id)status sendReadReceipts:(BOOL)sendReadReceipts skipUpdateChatSession:(BOOL)skip;
@end

@interface WAStatusXMPPService : NSObject
- (void)sendReadReceiptsForStatuses:(id)statuses;
@end

@interface WAMessage : NSObject
@property (nonatomic, assign) BOOL isViewOnce;
@property (nonatomic, assign) int64_t viewOnceCount;
- (BOOL)isVideo;
- (NSUInteger)messageType;
- (BOOL)isViewOnceOpened;
- (BOOL)isViewOnceExpired;
- (void)markViewOnceMessageExpiredIfPossible;
- (BOOL)isRevoked;
- (BOOL)isRevokedByAdmin;
- (BOOL)isMessageRevoked;
- (NSString *)stanzaId;
- (id)chatJID;
- (NSString *)text;
- (void)setText:(NSString *)text;
- (id)mediaItem;
@end

@interface WAChatStorage : NSObject
- (void)revokeIncomingMessage:(id)message triggeredByMessageWithID:(id)messageID onDate:(id)date outOfOrder:(BOOL)outOfOrder revokedByAdminUserJID:(id)adminJID deferAction:(id)deferAction;
- (void)internalRevokeMessages:(NSArray *)messages triggeredByMessageWithID:(id)messageID onDate:(id)date outgoing:(BOOL)outgoing revokedByAdminUserJID:(id)adminJID botPluginMessagesToDelete:(id)botMsgs beginTransactions:(BOOL)begin commitTransactions:(BOOL)commit;
- (void)deleteExpiredViewOnceContent:(id)messages completion:(id)completion;
@end

@interface _TtC22WAChatMessagesVCStrict28WAChatMessagesViewController : UIViewController
- (void)chatStorageDidRevokeMessages:(id)messages;
- (void)chatStorageWillRevokeMessages:(id)messages;
- (void)presentExpiredViewOnceAlertViewForMessage:(id)message;
@end

@interface _TtC23WAViewOnceMessageViewer43ViewOnceMessageContentDisplayViewController : UIViewController
- (void)wa_applicationDidEnterBackground;
@end

@interface UIView (TweakScreenshotFix)
- (void)_setSecureContents:(BOOL)secure;
@end

@interface _TtC23WAViewOnceMessageViewerP33_7691D041A7C67D05AF843B2696D5309037ViewOnceDisplayChatMessagesController : NSObject
- (BOOL)pausesPlaybackForScreenRecording;
@end

@interface WAMediaBrowserViewController : UIViewController
- (void)userDidTakeScreenshot:(id)notification;
@end

@interface WABlockScreenshotViewProvider : NSObject
- (id)initWithIsProtected:(BOOL)arg1;
- (BOOL)isProtected;
- (void)setIsProtected:(BOOL)arg1;
- (BOOL)isOsCompatibleForDescriptionView;
- (BOOL)isOSVersionCompatible;
- (id)canvasView;
- (void)addSnapshotView:(id)arg1;
@end

@interface WABlockScreenshotDescriptionView : UIView
- (id)initWithConfiguration:(id)config;
- (id)whatsAppLogoBlockingOverlayView;
- (void)setWhatsAppLogoBlockingOverlayView:(id)view;
@end

@interface WAGenericMediaBrowserViewController : UIViewController
- (void)verifyScreenshotProtection;
- (void)showScreenshotBlockedToast;
- (void)userDidTakeScreenshot:(id)notification;
@end

@interface WAPictureContainerViewControllerV3 : UIViewController
- (void)installProfilePictureScreenshotProtectionIfNeeded;
- (BOOL)profilePictureScreenshotProtectionInstalled;
- (void)profilePictureUserDidTakeScreenshot:(id)notification;
@end

@interface WAStatusViewerViewController : UIViewController
- (void)viewerDidTakeScreenshot:(id)notification;
@end

@interface _TtC25WAMediaBrowserControllers30MediaBrowserTestViewController : UIViewController
@end

@interface _TtC25WAMessageSliceViewsStatus30StatusComponentMessageSnapshot : NSObject
- (BOOL)isMessageRevoked;
@end

@interface _TtC24WAMessageStatusProviding23MessageStatusDescriptor : NSObject
- (BOOL)snippetHideIfRevoked;
@end

@interface WATableSection : NSObject
@property (nonatomic, copy) NSArray *rows;
@property (nonatomic, copy) NSString *headerTitle;
@property (nonatomic, copy) NSString *footerTitle;
- (void)setRows:(NSArray *)rows;
@end

@interface WATableRow : NSObject
@property (nonatomic, copy) NSString *text;
@property (nonatomic, copy) NSString *detailText;
@property (nonatomic, strong) UITableViewCell *cell;
@end

@interface WAStaticTableViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, copy) NSArray *sections;
@property (nonatomic, strong) UITableView *tableView;
- (id)rowAtIndexPath:(NSIndexPath *)indexPath;
- (id)sectionAtIndex:(NSInteger)index;
- (void)setSections:(NSArray *)sections;
@end

@interface WASettingsViewController : WAStaticTableViewController
- (void)addSubscriptionsRowIfEligibleToSection:(id)arg1;
- (void)addSubscriptionsRowToSection:(id)arg1;
- (BOOL)isSubscriptionsRowPresentInTable;
- (BOOL)isSubscriptionsRowOffered;
- (void)watweak_openSettingsFromLongPress:(id)sender;
@end

@interface WAViewOnceMessageViewController : UIViewController
- (void)userDidTakeScreenshot:(id)notification;
- (void)viewOnceButtonTappedWithSender:(id)sender;
@end

@interface WAGroupIconViewController : UIViewController
- (void)addScreenshotProtectionIfNeeded;
- (void)addScreenRecordingProtectionIfNeeded;
@end

@interface WhatsAppAppDelegate : UIResponder <UIApplicationDelegate>
- (void)applicationUserDidTakeScreenshot:(id)notification;
@end

@interface WAContextualizePermissionsHelper : NSObject
+ (BOOL)isPermissionPrimerEnabledWithUserContext:(id)arg1;
+ (BOOL)isPermissionPrimerV2EnabledWithUserContext:(id)arg1;
+ (BOOL)isContactsPrimerEnabledWithUserContext:(id)arg1;
@end

@interface _TtC26WAContextualizePermissions48ContextualizePermissionsBasePrimerViewController : UIViewController
- (void)startLoadingState;
- (void)endLoadingStateWithCompletion:(id)arg1;
@end

@interface WAFakeVocabulary : NSObject
+ (instancetype)sharedInstance;
- (void)setVocabulary:(id)arg1 ofType:(NSInteger)arg2;
- (void)setVocabularyStrings:(id)arg1 ofType:(NSInteger)arg2;
- (void)removeAllVocabularyStrings;
@end

@interface _INVocabulary : NSObject
+ (id)sharedVocabulary;
- (void)setVocabulary:(id)arg1 ofType:(NSInteger)arg2;
- (void)setVocabularyStrings:(id)arg1 ofType:(NSInteger)arg2;
- (void)removeAllVocabularyStrings;
@end

@interface INPreferences (Private)
- (void)_verifyEntitlements;
@end

@interface DCDevice : NSObject
+ (instancetype)currentDevice;
- (BOOL)isSupported;
- (void)generateTokenWithCompletionHandler:(void (^)(NSData *token, NSError *error))completionHandler;
@end

@interface DCAppAttestService : NSObject
+ (instancetype)sharedService;
- (BOOL)isSupported;
- (void)generateKeyWithCompletionHandler:(void (^)(NSString *keyId, NSError *error))completionHandler;
- (void)attestKey:(NSString *)keyId clientDataHash:(NSData *)clientDataHash completionHandler:(void (^)(NSData *attestationObject, NSError *error))completionHandler;
@end

@interface CKContainer : NSObject
+ (instancetype)defaultContainer;
+ (instancetype)containerWithIdentifier:(NSString *)identifier;
- (id)_setupWithContainerID:(id)a options:(id)b;
- (id)_initWithContainerIdentifier:(id)a;
@end

@interface CKEntitlements : NSObject
- (id)initWithEntitlementsDict:(NSDictionary *)entitlements;
@end

@interface WAProfileViewController : WAStaticTableViewController
- (void)savePushNameIfValid;
@end

@interface WAVerificationProfileController : UIViewController
@end

@interface WATabBarController : UITabBarController
- (void)addAIFABIfNeeded;
- (void)updateAIFABStateIfNeeded;
- (void)updateAIFabStateIfTabChanged;
- (void)updateAIFABStateForShouldSelect:(id)arg1;
- (void)updateAIFABVisibility;
- (void)updateAIFABBottomConstraintIfNeeded;
@end

@interface _TtC9WAAIViews34FloatingActionButtonViewController : UIViewController
@end

@interface _TtC9WAAIViews29FloatingActionButtonViewModel : NSObject
- (BOOL)isFloatingActionButtonVisible;
@end

@interface _TtC25WAChatListViewControllers39ChatListAIFloatingActionButtonViewModel : NSObject
- (BOOL)isFloatingActionButtonVisible;
@end

@interface _TtC17WAFOABridgesViews36WAFOAHScrollCollectionViewController : UIViewController
@end

@interface WAChatListViewController : UIViewController
- (BOOL)metaAIFloatingButtonEnabled;
- (BOOL)metaAIFloatingButtonRefactorEnabled;
- (BOOL)isMetaAIInTabEnabled;
- (id)metaAIFloatingButton;
- (id)navBarMetaAIButton;
- (id)chatListNavigationMetaAIButton;
- (BOOL)chatListNavigationMetaAIFloatingButtonEnabled;
- (BOOL)isChatListMetaAIEntryPointEnabled;
- (void)updateRightBarButtonItems;
- (void)updateNavigationBarButtons;
- (void)addMetaAIFloatingButtonAsSubviewIfNeeded;
- (void)setupMetaAIFloatingButton;
@end

@interface WAMetaAIHeaderView : UIView
@end

@interface WASearchControllerViewController : UIViewController
@end

@interface WAFieldStats : NSObject
- (void)logEvent:(id)event;
- (void)logEvent:(id)event weight:(NSInteger)weight;
- (void)logEvent:(id)event weight:(NSInteger)weight eventObject:(id)object;
- (void)logEvent:(id)event samplingRate:(id)samplingRate;
- (void)uploadStatsWithCompletion:(id)completion;
@end

@interface WALogUploader : NSObject
- (void)uploadCrashLogsForAllDirectories;
- (void)uploadCriticalAndStallLogsForAllDirectories;
- (void)uploadLogs:(id)logs;
- (void)uploadLog:(id)log logUploadRequest:(id)req withCompletion:(id)completion;
@end
