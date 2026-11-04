#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import "WAExtra.h"
#import "WAExtraLocalization.h"
#import "../Constants.h"

#define WALoc(key) [WAExtraLocalization localizedStringForKey:(key)]

@interface WAExtra ()
@property (nonatomic, strong) UITableView *tableView;
@end

@implementation WAExtra

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = WALoc(@"TWEAK_SETTINGS");
    self.view.backgroundColor = [UIColor systemGroupedBackgroundColor];
    
    [self setupTableView];
    [self setupNavigationButtons];
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

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 6;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0: return 2; // Media Quality
        case 1: return 2; // Ghost Mode
        case 2: return 2; // Read Receipts
        case 3: return 2; // Anti-Revoke & View-Once
        case 4: return 2; // Security & Screenshots
        case 5: return 3; // Clean UI & Anti-Telemetry
        default: return 0;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0: return WALoc(@"MEDIA_QUALITY_HEADER");
        case 1: return WALoc(@"GHOST_MODE_HEADER");
        case 2: return WALoc(@"READ_RECEIPTS_HEADER");
        case 3: return WALoc(@"ANTI_REVOKE_HEADER");
        case 4: return WALoc(@"SECURITY_HEADER");
        case 5: return WALoc(@"CLEAN_UI_HEADER");
        default: return nil;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellId = @"WASwitchCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellId];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    UISwitch *toggle = [[UISwitch alloc] init];
    toggle.onTintColor = [UIColor systemGreenColor];
    
    NSString *prefKey = nil;
    BOOL defaultVal = NO;
    NSString *title = nil;
    NSString *subtitle = nil;
    
    if (indexPath.section == 0) {
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
    } else if (indexPath.section == 1) {
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
    } else if (indexPath.section == 2) {
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
    } else if (indexPath.section == 3) {
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
    } else if (indexPath.section == 4) {
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
    } else if (indexPath.section == 5) {
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

- (void)switchChanged:(UISwitch *)sender {
    NSString *key = objc_getAssociatedObject(sender, "prefKey");
    if (key) {
        WATweakSetBool(key, sender.isOn);
    }
}

@end
