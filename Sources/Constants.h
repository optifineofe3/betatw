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
#define kHideMetaAI                    @"watweak_hide_meta_ai"
#define kHideMetaTrash                 @"watweak_hide_meta_trash"
#define kDisableTelemetry              @"watweak_disable_telemetry"

#define FAKE_LOCATION_ENABLED_KEY      @"watweak_fake_location_enabled"
#define FAKE_LATITUDE_KEY              @"watweak_fake_latitude"
#define FAKE_LONGITUDE_KEY             @"watweak_fake_longitude"
#define FILE_PICKER_FIX_KEY            @"watweak_fix_file_picker"
#define FILE_PICKER_PATH               @"watweak_file_picker_cache"

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
