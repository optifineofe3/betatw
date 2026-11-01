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
- (BOOL)isViewOnceOpened;
- (void)markViewOnceMessageExpiredIfPossible;
- (NSString *)stanzaId;
- (id)chatJID;
- (NSString *)text;
@end

@interface WASettingsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) UITableView *tableView;
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

@interface WAProfileViewController : UIViewController
- (void)savePushNameIfValid;
@end

@interface WAVerificationProfileController : UIViewController
@end
