#import "WAExtraLocalization.h"

@implementation WAExtraLocalization

+ (NSBundle *)tweakBundle {
    static NSBundle *bundle = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *path = @"/Library/Application Support/Tweak/Tweak.bundle";
        bundle = [NSBundle bundleWithPath:path];
        if (!bundle) {
            NSString *appBundlePath = [[NSBundle mainBundle] pathForResource:@"Tweak" ofType:@"bundle"];
            if (appBundlePath) {
                bundle = [NSBundle bundleWithPath:appBundlePath];
            }
        }
    });
    return bundle;
}

+ (NSString *)localizedStringForKey:(NSString *)key {
    NSBundle *bundle = [self tweakBundle];
    if (bundle) {
        NSString *val = [bundle localizedStringForKey:key value:nil table:nil];
        if (val && ![val isEqualToString:key]) {
            return val;
        }
    }

    static NSDictionary *enDict = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        enDict = @{
            @"TWEAK_SETTINGS": @"Tweak",
            @"APPLY": @"Apply",
            @"APPLY_CHANGES": @"Relaunch WhatsApp to apply changes?",
            @"CANCEL": @"Cancel",
            @"OK": @"OK",
            
            @"MEDIA_QUALITY_HEADER": @"Media Quality",
            @"UNCOMPRESSED_PHOTOS_TITLE": @"Uncompressed Photos",
            @"UNCOMPRESSED_PHOTOS_SUBTITLE": @"Send photos at full quality, no compression",
            @"UNCOMPRESSED_VIDEOS_TITLE": @"Uncompressed Videos",
            @"UNCOMPRESSED_VIDEOS_SUBTITLE": @"Send videos at maximum quality and resolution",
            
            @"GHOST_MODE_HEADER": @"Ghost Mode",
            @"DISABLE_ONLINE_TITLE": @"Hide Online Status",
            @"DISABLE_ONLINE_SUBTITLE": @"Always appear offline",
            @"DISABLE_TYPING_TITLE": @"Hide Typing / Recording Indicator",
            @"DISABLE_TYPING_SUBTITLE": @"Don’t show when you’re typing or recording",
            
            @"READ_RECEIPTS_HEADER": @"Read Receipts",
            @"DISABLE_READ_RECEIPTS_TITLE": @"Disable Read Receipts",
            @"DISABLE_READ_RECEIPTS_SUBTITLE": @"Only show one checkmark",
            @"DISABLE_STATUS_RECEIPTS_TITLE": @"Stealth Story Viewing",
            @"DISABLE_STATUS_RECEIPTS_SUBTITLE": @"View statuses anonymously",
            
            @"ANTI_REVOKE_HEADER": @"Message Protection",
            @"ANTI_REVOKE_TITLE": @"Anti-Revoke",
            @"ANTI_REVOKE_SUBTITLE": @"Keep deleted messages with tag",
            @"UNLIMITED_VIEW_ONCE_TITLE": @"Unlimited View-Once Media",
            @"UNLIMITED_VIEW_ONCE_SUBTITLE": @"View view-once media unlimited times",
            
            @"SECURITY_HEADER": @"Privacy & Screen Capture",
            @"DISABLE_SCREENSHOT_DETECTION_TITLE": @"Bypass Screenshot Detection",
            @"DISABLE_SCREENSHOT_DETECTION_SUBTITLE": @"Block detection and remove black screens",
            @"DISABLE_SCREEN_RECORDING_PAUSE_TITLE": @"Play Media during Screen Recording",
            @"DISABLE_SCREEN_RECORDING_PAUSE_SUBTITLE": @"Don’t pause media while recording the screen",
            
            @"CLEAN_UI_HEADER": @"Privacy & Meta Cleanup",
            @"HIDE_META_AI_TITLE": @"Hide Ask Meta AI",
            @"HIDE_META_AI_SUBTITLE": @"Remove Meta AI button from Chats",
            @"HIDE_META_TRASH_TITLE": @"Hide Meta Trash",
            @"HIDE_META_TRASH_SUBTITLE": @"Hide Subscriptions, Accounts Center and “Also from Meta”",
            @"DISABLE_TELEMETRY_TITLE": @"Block Telemetry & Logging",
            @"DISABLE_TELEMETRY_SUBTITLE": @"Block diagnostics and analytics to Meta/Google",
        };
    });

    return enDict[key] ?: key;
}

@end
