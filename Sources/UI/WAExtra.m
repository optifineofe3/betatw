#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import "WAExtra.h"
#import "WAExtraLocalization.h"
#import "LocationSelector.h"
#import "../Constants.h"

#define WALoc(key) [WAExtraLocalization localizedStringForKey:(key)]

typedef NS_ENUM(NSInteger, WA_SETTINGS_SECTIONS) {
    SEC_MEDIA_QUALITY = 0,
    SEC_GHOST_MODE = 1,
    SEC_READ_RECEIPTS = 2,
    SEC_ANTI_REVOKE = 3,
    SEC_SECURITY = 4,
    SEC_FILE_FIXER = 5,
    SEC_FAKE_LOCATION = 6,
    SEC_CLEAN_UI = 7,
    SEC_COUNT = 8
};

@interface WAExtra ()
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, copy) NSString *cacheSize;
@end

@implementation WAExtra

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = WALoc(@"TWEAK_SETTINGS");
    self.view.backgroundColor = [UIColor systemGroupedBackgroundColor];
    
    [self setupTableView];
    [self setupNavigationButtons];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didChangeFakeLocation)
                                                 name:@"TweakLocationChanged"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didChangeFakeLocation)
                                                 name:@"LeadLocationChanged"
                                               object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didChangeFakeLocation {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSIndexSet *section = [NSIndexSet indexSetWithIndex:SEC_FAKE_LOCATION];
        [self.tableView reloadSections:section withRowAnimation:UITableViewRowAnimationAutomatic];
    });
}

- (void)setupTableView {
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleInsetGrouped];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.view addSubview:self.tableView];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.tableView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];
}

- (void)setupNavigationButtons {
    UIBarButtonItem *closeItem = [[UIBarButtonItem alloc] initWithTitle:WALoc(@"CANCEL")
                                                                  style:UIBarButtonItemStylePlain
                                                                 target:self
                                                                 action:@selector(dismissSelf)];
    self.navigationItem.leftBarButtonItem = closeItem;
    
    UIButton *applyButton = [UIButton buttonWithType:UIButtonTypeSystem];
    UIImage *applyImg = [UIImage systemImageNamed:@"checkmark.circle.fill"];
    [applyButton setImage:applyImg forState:UIControlStateNormal];
    applyButton.tintColor = [UIColor systemGreenColor];
    [applyButton addTarget:self action:@selector(applyChanges) forControlEvents:UIControlEventTouchUpInside];
    
    UIBarButtonItem *applyItem = [[UIBarButtonItem alloc] initWithCustomView:applyButton];
    self.navigationItem.rightBarButtonItem = applyItem;
}

- (void)dismissSelf {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)applyChanges {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:WALoc(@"APPLY")
                                                                   message:WALoc(@"APPLY_CHANGES")
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:WALoc(@"OK")
                                                       style:UIAlertActionStyleDestructive
                                                     handler:^(UIAlertAction * _Nonnull action) {
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        if ([[UIApplication sharedApplication] respondsToSelector:@selector(suspend)]) {
            [[UIApplication sharedApplication] performSelector:@selector(suspend)];
        }
        #pragma clang diagnostic pop
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            exit(0);
        });
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:WALoc(@"CANCEL")
                                                           style:UIAlertActionStyleCancel
                                                         handler:nil];
    
    [alert addAction:okAction];
    [alert addAction:cancelAction];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Cache Size & Cleaning

- (NSString *)sizeOfFilePickerDirectory {
    NSString *uglyFixDirectory = [NSTemporaryDirectory() stringByAppendingPathComponent:FILE_PICKER_PATH];
    unsigned long long totalSize = 0;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *contents = [fileManager subpathsAtPath:uglyFixDirectory];

    for (NSString *p in contents) {
        NSString *fullPath = [uglyFixDirectory stringByAppendingPathComponent:p];
        BOOL isDir = NO;
        if ([fileManager fileExistsAtPath:fullPath isDirectory:&isDir] && !isDir) {
            NSDictionary *attrs = [fileManager attributesOfItemAtPath:fullPath error:nil];
            totalSize += [attrs fileSize];
        }
    }

    if (totalSize >= 1024 * 1024 * 1024) {
        return [NSString stringWithFormat:@"%.2f GB", totalSize / (1024.0 * 1024.0 * 1024.0)];
    } else if (totalSize >= 1024 * 1024) {
        return [NSString stringWithFormat:@"%.2f MB", totalSize / (1024.0 * 1024.0)];
    } else if (totalSize > 0) {
        return [NSString stringWithFormat:@"%.1f KB", totalSize / 1024.0];
    }
    return @"0 KB";
}

- (void)clearFilePickerCache {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:WALoc(@"CACHE_CLEAR_WARNING_TITLE")
                                                                   message:WALoc(@"CACHE_CLEAR_WARNING_MESSAGE")
                                                            preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *okAction = [UIAlertAction actionWithTitle:WALoc(@"OK")
                                                       style:UIAlertActionStyleDestructive
                                                     handler:^(UIAlertAction *action) {
        NSString *fixDir = [NSTemporaryDirectory() stringByAppendingPathComponent:FILE_PICKER_PATH];
        NSError *err = nil;
        [[NSFileManager defaultManager] removeItemAtPath:fixDir error:&err];
        self.cacheSize = @"Cleared";

        dispatch_async(dispatch_get_main_queue(), ^{
            NSIndexSet *sec = [NSIndexSet indexSetWithIndex:SEC_FILE_FIXER];
            [self.tableView reloadSections:sec withRowAnimation:UITableViewRowAnimationAutomatic];
        });
    }];

    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:WALoc(@"CANCEL")
                                                           style:UIAlertActionStyleCancel
                                                         handler:nil];

    [alert addAction:cancelAction];
    [alert addAction:okAction];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showLocationSelector {
    LocationSelector *selectorVC = [[LocationSelector alloc] init];
    UINavigationController *navVC = [[UINavigationController alloc] initWithRootViewController:selectorVC];
    [self presentViewController:navVC animated:YES completion:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return SEC_COUNT;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case SEC_MEDIA_QUALITY: return 2;
        case SEC_GHOST_MODE: return 2;
        case SEC_READ_RECEIPTS: return 2;
        case SEC_ANTI_REVOKE: return 2;
        case SEC_SECURITY: return 2;
        case SEC_FILE_FIXER: return 2;
        case SEC_FAKE_LOCATION: return 2;
        case SEC_CLEAN_UI: return 3;
        default: return 0;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case SEC_MEDIA_QUALITY: return WALoc(@"MEDIA_QUALITY_HEADER");
        case SEC_GHOST_MODE: return WALoc(@"GHOST_MODE_HEADER");
        case SEC_READ_RECEIPTS: return WALoc(@"READ_RECEIPTS_HEADER");
        case SEC_ANTI_REVOKE: return WALoc(@"ANTI_REVOKE_HEADER");
        case SEC_SECURITY: return WALoc(@"SECURITY_HEADER");
        case SEC_FILE_FIXER: return WALoc(@"FILE_FIXER_HEADER");
        case SEC_FAKE_LOCATION: return WALoc(@"FAKE_LOCATION_HEADER");
        case SEC_CLEAN_UI: return WALoc(@"CLEAN_UI_HEADER");
        default: return nil;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    // Custom non-switch row: Clear cache (section 5, row 1)
    if (indexPath.section == SEC_FILE_FIXER && indexPath.row == 1) {
        static NSString *clearCellId = @"WAClearCacheCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:clearCellId];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:clearCellId];
        }
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        cell.textLabel.text = WALoc(@"CLEAR_FILE_PICKER_CACHE_TITLE");
        cell.textLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightRegular];
        cell.detailTextLabel.text = WALoc(@"CLEAR_FILE_PICKER_CACHE_SUBTITLE");
        cell.detailTextLabel.textColor = [UIColor secondaryLabelColor];
        cell.detailTextLabel.numberOfLines = 0;

        UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
        [spinner startAnimating];
        cell.accessoryView = spinner;

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            if (!self.cacheSize) {
                self.cacheSize = [self sizeOfFilePickerDirectory];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                UITableViewCell *curCell = [tableView cellForRowAtIndexPath:indexPath];
                if (curCell == cell) {
                    UILabel *sizeLbl = [[UILabel alloc] init];
                    sizeLbl.text = self.cacheSize;
                    sizeLbl.textColor = [UIColor secondaryLabelColor];
                    sizeLbl.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
                    [sizeLbl sizeToFit];
                    cell.accessoryView = sizeLbl;
                }
            });
        });
        return cell;
    }

    // Custom non-switch row: Select location (section 6, row 1)
    if (indexPath.section == SEC_FAKE_LOCATION && indexPath.row == 1) {
        static NSString *locCellId = @"WALocationSelectCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:locCellId];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:locCellId];
        }
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        cell.textLabel.text = WALoc(@"SELECT_FAKE_LOCATION_TITLE");
        cell.textLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightRegular];

        CGFloat savedLon = [[NSUserDefaults standardUserDefaults] floatForKey:FAKE_LONGITUDE_KEY];
        CGFloat savedLat = [[NSUserDefaults standardUserDefaults] floatForKey:FAKE_LATITUDE_KEY];
        if (savedLon != 0.0 && savedLat != 0.0) {
            cell.detailTextLabel.text = [NSString stringWithFormat:@"Lat: %.4f, Lon: %.4f", savedLat, savedLon];
        } else {
            cell.detailTextLabel.text = nil;
        }
        cell.detailTextLabel.textColor = [UIColor secondaryLabelColor];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.accessoryView = nil;
        return cell;
    }

    // Standard switch cell
    static NSString *cellId = @"WASwitchCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellId];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    cell.accessoryType = UITableViewCellAccessoryNone;

    UISwitch *toggle = [[UISwitch alloc] init];
    toggle.onTintColor = [UIColor systemGreenColor];
    
    NSString *prefKey = nil;
    BOOL defaultVal = NO;
    NSString *title = nil;
    NSString *subtitle = nil;
    
    if (indexPath.section == SEC_MEDIA_QUALITY) {
        if (indexPath.row == 0) {
            title = WALoc(@"UNCOMPRESSED_PHOTOS_TITLE");
            subtitle = WALoc(@"UNCOMPRESSED_PHOTOS_SUBTITLE");
            prefKey = kUncompressedPhotos;
            defaultVal = YES;
        } else {
            title = WALoc(@"UNCOMPRESSED_VIDEOS_TITLE");
            subtitle = WALoc(@"UNCOMPRESSED_VIDEOS_SUBTITLE");
            prefKey = kUncompressedVideos;
            defaultVal = YES;
        }
    } else if (indexPath.section == SEC_GHOST_MODE) {
        if (indexPath.row == 0) {
            title = WALoc(@"DISABLE_ONLINE_TITLE");
            subtitle = WALoc(@"DISABLE_ONLINE_SUBTITLE");
            prefKey = kDisableOnline;
            defaultVal = NO;
        } else {
            title = WALoc(@"DISABLE_TYPING_TITLE");
            subtitle = WALoc(@"DISABLE_TYPING_SUBTITLE");
            prefKey = kDisableTyping;
            defaultVal = NO;
        }
    } else if (indexPath.section == SEC_READ_RECEIPTS) {
        if (indexPath.row == 0) {
            title = WALoc(@"DISABLE_READ_RECEIPTS_TITLE");
            subtitle = WALoc(@"DISABLE_READ_RECEIPTS_SUBTITLE");
            prefKey = kDisableReadReceipts;
            defaultVal = NO;
        } else {
            title = WALoc(@"DISABLE_STATUS_RECEIPTS_TITLE");
            subtitle = WALoc(@"DISABLE_STATUS_RECEIPTS_SUBTITLE");
            prefKey = kDisableStatusReceipts;
            defaultVal = NO;
        }
    } else if (indexPath.section == SEC_ANTI_REVOKE) {
        if (indexPath.row == 0) {
            title = WALoc(@"ANTI_REVOKE_TITLE");
            subtitle = WALoc(@"ANTI_REVOKE_SUBTITLE");
            prefKey = kAntiRevoke;
            defaultVal = YES;
        } else {
            title = WALoc(@"UNLIMITED_VIEW_ONCE_TITLE");
            subtitle = WALoc(@"UNLIMITED_VIEW_ONCE_SUBTITLE");
            prefKey = kUnlimitedViewOnce;
            defaultVal = YES;
        }
    } else if (indexPath.section == SEC_SECURITY) {
        if (indexPath.row == 0) {
            title = WALoc(@"DISABLE_SCREENSHOT_DETECTION_TITLE");
            subtitle = WALoc(@"DISABLE_SCREENSHOT_DETECTION_SUBTITLE");
            prefKey = kDisableScreenshotDetection;
            defaultVal = YES;
        } else {
            title = WALoc(@"DISABLE_SCREEN_RECORDING_PAUSE_TITLE");
            subtitle = WALoc(@"DISABLE_SCREEN_RECORDING_PAUSE_SUBTITLE");
            prefKey = kDisableScreenRecordingPause;
            defaultVal = YES;
        }
    } else if (indexPath.section == SEC_FILE_FIXER) {
        title = WALoc(@"FIX_FILE_PICKER_TITLE");
        subtitle = WALoc(@"FIX_FILE_PICKER_SUBTITLE");
        prefKey = FILE_PICKER_FIX_KEY;
        defaultVal = NO;
    } else if (indexPath.section == SEC_FAKE_LOCATION) {
        title = WALoc(@"ENABLE_FAKE_LOCATION_TITLE");
        subtitle = WALoc(@"ENABLE_FAKE_LOCATION_SUBTITLE");
        prefKey = FAKE_LOCATION_ENABLED_KEY;
        defaultVal = NO;
    } else if (indexPath.section == SEC_CLEAN_UI) {
        if (indexPath.row == 0) {
            title = WALoc(@"HIDE_META_AI_TITLE");
            subtitle = WALoc(@"HIDE_META_AI_SUBTITLE");
            prefKey = kHideMetaAI;
            defaultVal = YES;
        } else if (indexPath.row == 1) {
            title = WALoc(@"HIDE_META_TRASH_TITLE");
            subtitle = WALoc(@"HIDE_META_TRASH_SUBTITLE");
            prefKey = kHideMetaTrash;
            defaultVal = YES;
        } else {
            title = WALoc(@"DISABLE_TELEMETRY_TITLE");
            subtitle = WALoc(@"DISABLE_TELEMETRY_SUBTITLE");
            prefKey = kDisableTelemetry;
            defaultVal = YES;
        }
    }
    
    cell.textLabel.text = title;
    cell.textLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightRegular];
    cell.detailTextLabel.text = subtitle;
    cell.detailTextLabel.textColor = [UIColor secondaryLabelColor];
    cell.detailTextLabel.numberOfLines = 0;
    
    toggle.on = WATweakGetBool(prefKey, defaultVal);
    objc_setAssociatedObject(toggle, "prefKey", prefKey, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [toggle removeTarget:nil action:NULL forControlEvents:UIControlEventValueChanged];
    [toggle addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
    
    cell.accessoryView = toggle;
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (indexPath.section == SEC_FILE_FIXER && indexPath.row == 1) {
        [self clearFilePickerCache];
    } else if (indexPath.section == SEC_FAKE_LOCATION && indexPath.row == 1) {
        [self showLocationSelector];
    }
}

- (void)switchChanged:(UISwitch *)sender {
    NSString *key = objc_getAssociatedObject(sender, "prefKey");
    if (key) {
        WATweakSetBool(key, sender.isOn);
    }
}

@end
