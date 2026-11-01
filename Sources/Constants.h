#import <Foundation/Foundation.h>

#define kUncompressedPhotos            @"watweak_uncompressed_photos"
#define kUncompressedVideos            @"watweak_uncompressed_videos"
#define kDisableOnline                 @"watweak_disable_online"
#define kDisableTyping                 @"watweak_disable_typing"
#define kDisableReadReceipts           @"watweak_disable_read_receipts"
#define kDisableStatusReceipts         @"watweak_disable_status_receipts"
#define kAntiRevoke                    @"watweak_anti_revoke"
#define kUnlimitedViewOnce             @"watweak_unlimited_view_once"
#define kDisableScreenshotDetection    @"watweak_disable_screenshot_detection"
#define kDisableScreenRecordingPause   @"watweak_disable_screen_recording_pause"

static inline BOOL WATweakGetBool(NSString *key, BOOL defaultVal) {
    id val = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    if (val == nil) {
        return defaultVal;
    }
    return [val boolValue];
}

static inline void WATweakSetBool(NSString *key, BOOL val) {
    [[NSUserDefaults standardUserDefaults] setBool:val forKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}
