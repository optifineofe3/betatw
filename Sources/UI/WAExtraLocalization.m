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

    // Fallback dictionary
    NSString *lang = [[NSLocale preferredLanguages] firstObject] ?: @"en";
    BOOL isRu = [lang hasPrefix:@"ru"] || [lang hasPrefix:@"uk"] || [lang hasPrefix:@"be"];

    static NSDictionary *ruDict = nil;
    static NSDictionary *enDict = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ruDict = @{
            @"TWEAK_SETTINGS": @"Настройки Tweak",
            @"APPLY": @"Применить",
            @"APPLY_CHANGES": @"Перезапустить WhatsApp для применения изменений?",
            @"CANCEL": @"Отмена",
            @"OK": @"ОК",
            
            @"MEDIA_QUALITY_HEADER": @"Качество медиа (Без сжатия)",
            @"UNCOMPRESSED_PHOTOS_TITLE": @"Фото без сжатия",
            @"UNCOMPRESSED_PHOTOS_SUBTITLE": @"Отправка фото в 100% качестве и оригинальном разрешении",
            @"UNCOMPRESSED_VIDEOS_TITLE": @"Видео без сжатия",
            @"UNCOMPRESSED_VIDEOS_SUBTITLE": @"Отправка видео с максимальным битрейтом и исходным качеством",
            
            @"GHOST_MODE_HEADER": @"Ghost Mode (Режим невидимки)",
            @"DISABLE_ONLINE_TITLE": @"Скрыть статус «В сети»",
            @"DISABLE_ONLINE_SUBTITLE": @"Вы всегда будете отображаться оффлайн для собеседников",
            @"DISABLE_TYPING_TITLE": @"Скрыть статус набора текста",
            @"DISABLE_TYPING_SUBTITLE": @"Не отправлять «печатает...» и «записывает аудио...»",
            
            @"READ_RECEIPTS_HEADER": @"Конфиденциальность прочтения",
            @"DISABLE_READ_RECEIPTS_TITLE": @"Отключить синие галочки",
            @"DISABLE_READ_RECEIPTS_SUBTITLE": @"Собеседник видит только две серые галочки (доставлено)",
            @"DISABLE_STATUS_RECEIPTS_TITLE": @"Скрытный просмотр историй",
            @"DISABLE_STATUS_RECEIPTS_SUBTITLE": @"Анонимный просмотр чужих статусов без отметки в списке",
            
            @"ANTI_REVOKE_HEADER": @"Защита сообщений",
            @"ANTI_REVOKE_TITLE": @"Anti-Revoke (Не удалять сообщения)",
            @"ANTI_REVOKE_SUBTITLE": @"Сохранять удаленные собеседником сообщения с плашкой [DEL]",
            @"UNLIMITED_VIEW_ONCE_TITLE": @"Бесконечный просмотр View-Once",
            @"UNLIMITED_VIEW_ONCE_SUBTITLE": @"Просмотр одноразовых фото и видео неограниченное число раз",
            
            @"SECURITY_HEADER": @"Защита и безопасность",
            @"DISABLE_SCREENSHOT_DETECTION_TITLE": @"Блокировка детекта скриншотов",
            @"DISABLE_SCREENSHOT_DETECTION_SUBTITLE": @"Скрывать снятие скриншотов и обходить черный экран",
            @"DISABLE_SCREEN_RECORDING_PAUSE_TITLE": @"Видео при записи экрана",
            @"DISABLE_SCREEN_RECORDING_PAUSE_SUBTITLE": @"Не ставить воспроизведение видео на паузу при записи экрана",
        };

        enDict = @{
            @"TWEAK_SETTINGS": @"Tweak Settings",
            @"APPLY": @"Apply",
            @"APPLY_CHANGES": @"Relaunch WhatsApp to apply changes?",
            @"CANCEL": @"Cancel",
            @"OK": @"OK",
            
            @"MEDIA_QUALITY_HEADER": @"Media Quality (Uncompressed)",
            @"UNCOMPRESSED_PHOTOS_TITLE": @"Uncompressed Photos",
            @"UNCOMPRESSED_PHOTOS_SUBTITLE": @"Send photos at 100% quality without downscaling",
            @"UNCOMPRESSED_VIDEOS_TITLE": @"Uncompressed Videos",
            @"UNCOMPRESSED_VIDEOS_SUBTITLE": @"Send videos with maximum bitrate and resolution",
            
            @"GHOST_MODE_HEADER": @"Ghost Mode",
            @"DISABLE_ONLINE_TITLE": @"Hide Online Status",
            @"DISABLE_ONLINE_SUBTITLE": @"You will always appear offline to contacts",
            @"DISABLE_TYPING_TITLE": @"Hide Typing / Recording Indicator",
            @"DISABLE_TYPING_SUBTITLE": @"Do not broadcast typing or audio recording status",
            
            @"READ_RECEIPTS_HEADER": @"Read Receipts",
            @"DISABLE_READ_RECEIPTS_TITLE": @"Disable Read Receipts (Blue Ticks)",
            @"DISABLE_READ_RECEIPTS_SUBTITLE": @"Contacts will only see delivered ticks (grey checks)",
            @"DISABLE_STATUS_RECEIPTS_TITLE": @"Stealth Story Viewing",
            @"DISABLE_STATUS_RECEIPTS_SUBTITLE": @"View contacts' status updates anonymously",
            
            @"ANTI_REVOKE_HEADER": @"Message Protection",
            @"ANTI_REVOKE_TITLE": @"Anti-Revoke (Keep Deleted Messages)",
            @"ANTI_REVOKE_SUBTITLE": @"Preserve messages deleted by sender with [DEL] tag",
            @"UNLIMITED_VIEW_ONCE_TITLE": @"Unlimited View-Once Media",
            @"UNLIMITED_VIEW_ONCE_SUBTITLE": @"View disappearing photos/videos unlimited times",
            
            @"SECURITY_HEADER": @"Privacy & Screen Capture",
            @"DISABLE_SCREENSHOT_DETECTION_TITLE": @"Bypass Screenshot Detection",
            @"DISABLE_SCREENSHOT_DETECTION_SUBTITLE": @"Prevent detection and remove screenshot blackouts",
            @"DISABLE_SCREEN_RECORDING_PAUSE_TITLE": @"Play Media during Screen Recording",
            @"DISABLE_SCREEN_RECORDING_PAUSE_SUBTITLE": @"Do not pause playback when screen recording is active",
        };
    });

    NSDictionary *activeDict = isRu ? ruDict : enDict;
    NSString *translated = activeDict[key];
    if (translated) {
        return translated;
    }
    return enDict[key] ?: key;
}

@end
