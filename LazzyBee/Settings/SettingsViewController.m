//
//  SettingsViewController.m
//  LazzyBee
//
//  Created by HuKhong on 3/3/15.
//  Copyright (c) 2014 ITPRO. All rights reserved.
//

#import "SettingsViewController.h"
#import "CommonSqlite.h"
#import "Common.h"
#import "AppDelegate.h"
#import "SpeedTableViewCell.h"
#import "DailyTargetViewController.h"
#import "NotificationTableViewCell.h"
#import "TimerViewController.h"
#import "LevelPickerViewController.h"
#import "SettingCustomTableViewCell.h"
#import "ChangeLanguageViewController.h"
#import "AboutTableViewCell.h"

#import "TAGContainer.h"
#import "SVProgressHUD.h"
#import "TagManagerHelper.h"
#import "LocalizeHelper.h"
#import "GTMHTTPFetcher.h"
#import "GTLDataServiceApi.h"

#import "UploadToServer.h"

@interface SettingsViewController ()
{
    TimerViewController *timerView;
    LevelPickerViewController *levelView;
    
    UploadToServer *uploadToSerVer;
}
@end

@implementation SettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [TagManagerHelper pushOpenScreenEvent:@"iSettings"];
    // Do any additional setup after loading the view from its nib.
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)
    {
        [self.navigationController.navigationBar setTranslucent:NO];
    }
#endif

    [self.navigationController.navigationBar setBarTintColor:COMMON_COLOR];
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor whiteColor]};
    [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
    
    [self setTitle:LocalizedString(@"Settings")];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateSettingsScreen)
                                                 name:@"updateSettingsScreen"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(changeLanguageHandle)
                                                 name:@"changeLanguage"
                                               object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)updateSettingsScreen {
    [settingsTableView reloadData];
}

#pragma mark data source
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == SettingsTableViewSectionAbout) {
        return 65;
    }
    
    return 40.0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return SettingsTableViewSectionMax;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    // If you're serving data from an array, return the length of the array:
    
    if (section == SettingsTableViewSectionLanguage) {
        return LanguageSectionMax;
        
    } else if (section == SettingsTableViewSectionSpeech) {
        return SpeechSectionMax;
        
    } else if (section == SettingsTableViewSectionDailyTarget) {
        return DailyTargetSectionMax;
      
    } else if (section == SettingsTableViewSectionAutoPlay) {
        return AutoPlayMax;
        
    } else if (section == SettingsTableViewSectionDisplayMeaning) {
        return DisplayMeaningMax;
        
    } else if (section == SettingsTableViewSectionNotification) {
        return NotificationSectionMax;
        
    } else if (section == SettingsTableViewSectionUpdate) {
        return UpdateSectionMax;
        
    } else if (section == SettingsTableViewSectionBackup) {
        return BackupSectionMax;
        
    } else if (section == SettingsTableViewSectionAbout) {
        return AboutMax;
    }
    
    
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == SettingsTableViewSectionSpeech) {
        return LocalizedString(@"Speaking speed");
        
    } else if (section == SettingsTableViewSectionDailyTarget) {
        return LocalizedString(@"Target");
        
    } else if (section == SettingsTableViewSectionNotification) {
        return LocalizedString(@"Reminder");
        
    } else if (section == SettingsTableViewSectionAbout) {
        return LocalizedString(@"App info");
    }
    
    return @"";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *normalCellIdentifier = @"NormalCell";
    
    UITableViewCell *norCell = [tableView dequeueReusableCellWithIdentifier:normalCellIdentifier];
    if (norCell == nil) {
        norCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:normalCellIdentifier];
        norCell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    norCell.textLabel.textAlignment = NSTextAlignmentLeft;
    norCell.textLabel.textColor = [UIColor blackColor];
    norCell.textLabel.font = [UIFont systemFontOfSize:16];
    
    switch (indexPath.section) {
        case SettingsTableViewSectionLanguage:
            {
                norCell.textLabel.text = LocalizedString(@"Change language");
                return norCell;
            }
            break;
        
        case SettingsTableViewSectionSpeech:
            switch (indexPath.row) {
                case SpeakingSpeed:
                    {
                        NSString *speedCellIdentifier = @"SpeedCellIdentifier";
                        
                        SpeedTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:speedCellIdentifier];
                        if (cell == nil) {
                            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"SpeedTableViewCell" owner:nil options:nil];
                            cell = [nib objectAtIndex:0];
                            cell.accessoryType = UITableViewCellAccessoryNone;
                        }
                        
                        NSNumber *speedNumberObj = [[Common sharedCommon] loadDataFromUserDefaultStandardWithKey:KEY_SPEAKING_SPEED];
                        
                        if (speedNumberObj) {
                            [cell.speedSlider setValue:[speedNumberObj floatValue]];
                        }
                        
                        return cell;
                    }
                    break;
                    
                default:
                    break;
            }
            break;
        
        case SettingsTableViewSectionDailyTarget:
            switch (indexPath.row) {
                case DailyNewWordTarget:
                    {
                        norCell.accessoryType = UITableViewCellAccessoryNone;
                        
                        NSNumber *targetNumberObj = [[Common sharedCommon] loadDataFromUserDefaultStandardWithKey:KEY_DAILY_TARGET];
                        
                        if (targetNumberObj) {
                            norCell.textLabel.textAlignment = NSTextAlignmentCenter;
                            norCell.textLabel.text = [NSString stringWithFormat:@"%@: %ld %@", LocalizedString(@"Daily new words"), (long)[targetNumberObj integerValue], LocalizedString(@"words")];
                        }
                        
                        return norCell;
                    }
                    break;
                    
                case DailyTotalWordsTarget:
                    {
                        norCell.accessoryType = UITableViewCellAccessoryNone;
                        
                        NSNumber *targetNumberObj = [[Common sharedCommon] loadDataFromUserDefaultStandardWithKey:KEY_DAILY_TOTAL_TARGET];
                        
                        if (targetNumberObj) {
                            norCell.textLabel.textAlignment = NSTextAlignmentCenter;
                            norCell.textLabel.text = [NSString stringWithFormat:@"%@: %ld %@", LocalizedString(@"Daily total words"), (long)[targetNumberObj integerValue], LocalizedString(@"words")];
                        }
                        
                        return norCell;
                    }
                        break;
                    
                case LowestLevel:
                    {
                        norCell.accessoryType = UITableViewCellAccessoryNone;
                        
                        NSString *level = [[Common sharedCommon] loadDataFromUserDefaultStandardWithKey:KEY_LOWEST_LEVEL];
                        
                        if (level) {
                            norCell.textLabel.textAlignment = NSTextAlignmentCenter;
                            norCell.textLabel.text = [NSString stringWithFormat:@"%@: %@", LocalizedString(@"Level"), level];
                        }
                        
                        return norCell;
                    }
                    break;
                    
                case TimeToShowAnswer:
                {
                    norCell.accessoryType = UITableViewCellAccessoryNone;
                    
                    NSString *time = [[Common sharedCommon] loadDataFromUserDefaultStandardWithKey:KEY_TIME_TO_SHOW_ANSWER];
                    
                    if (time) {
                        norCell.textLabel.textAlignment = NSTextAlignmentCenter;
                        
                        norCell.textLabel.text = [NSString stringWithFormat:@"%@: %@s", LocalizedString(@"Waiting time to show answer"), time];
                    }
                    
                    return norCell;
                }
                    break;
                default:
                    break;
            }
            
        case SettingsTableViewSectionAutoPlay:
            {
                switch (indexPath.row) {
                    case AutoPlaySound:
                    {
                        NSString *autoPlayCellIdentifier = @"AutoPlayCell";
                        
                        NotificationTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:autoPlayCellIdentifier];
                        if (cell == nil) {
                            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"NotificationTableViewCell" owner:nil options:nil];
                            cell = [nib objectAtIndex:0];
                            cell.accessoryType = UITableViewCellAccessoryNone;
                        }
                        
                        cell.tag = SettingsTableViewSectionAutoPlay;
                        cell.delegate = (id)self;
                        
                        cell.textLabel.textColor = [UIColor blackColor];
                        cell.textLabel.font = [UIFont systemFontOfSize:16];
                        cell.accessoryType = UITableViewCellAccessoryNone;
                        
                        cell.lbTitle.text = LocalizedString(@"Autoplay sound");
                        
                        NSNumber *autoPlayFlag = [[Common sharedCommon] loadDataFromUserDefaultStandardWithKey:KEY_AUTOPLAY];
                        
                        cell.swControl.on = [autoPlayFlag boolValue];
                        
                        return cell;
                    }
                        break;
                        
                    default:
                        break;
                }
            }
            break;
           
        case SettingsTableViewSectionDisplayMeaning:
        {
            switch (indexPath.row) {
                case DisplayVietnamese:
                {
                    NSString *displayMeaningCellIdentifier = @"DisplayMeaningCell";
                    
                    NotificationTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:displayMeaningCellIdentifier];
                    if (cell == nil) {
                        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"NotificationTableViewCell" owner:nil options:nil];
                        cell = [nib objectAtIndex:0];
                        cell.accessoryType = UITableViewCellAccessoryNone;
                    }
                    
                    cell.tag = SettingsTableViewSectionDisplayMeaning;
                    cell.delegate = (id)self;
                    
                    cell.textLabel.textColor = [UIColor blackColor];
                    cell.textLabel.font = [UIFont systemFontOfSize:16];
                    cell.accessoryType = UITableViewCellAccessoryNone;
                    
                    cell.lbTitle.text = LocalizedString(@"Display meaning");
                    
                    NSNumber *displayMeaningFlag = [[Common sharedCommon] loadDataFromUserDefaultStandardWithKey:KEY_DISPLAYMEANING];
                    
                    cell.swControl.on = [displayMeaningFlag boolValue];
                    
                    return cell;
                }
                    break;
                    
                default:
                    break;
            }
        }
            break;
            
        case SettingsTableViewSectionNotification:
            switch (indexPath.row) {
                case NotificationOnOff:
                {
                    NSString *notificationOnOffCell = @"NotificationOnOffCell";
                    
                    NotificationTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:notificationOnOffCell];
                    if (cell == nil) {
                        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"NotificationTableViewCell" owner:nil options:nil];
                        cell = [nib objectAtIndex:0];
                        cell.accessoryType = UITableViewCellAccessoryNone;
                    }
                    
                    cell.tag = SettingsTableViewSectionNotification;
                    cell.delegate = (id)self;
                    
                    cell.lbTitle.text = LocalizedString(@"Turn on reminder");
                    
                    NSNumber *reminderFlag = [[Common sharedCommon] loadDataFromUserDefaultStandardWithKey:KEY_REMINDER_ONOFF];
                    
                    cell.swControl.on = [reminderFlag boolValue];
                    
                    return cell;
                }
                break;
                    
                case NotificationTime:
                    {
                        norCell.accessoryType = UITableViewCellAccessoryNone;
                        
                        NSString *time = [[Common sharedCommon] loadDataFromUserDefaultStandardWithKey:KEY_REMIND_TIME];
                        
                        if (time) {
                            norCell.textLabel.textAlignment = NSTextAlignmentCenter;
                            norCell.textLabel.text = [NSString stringWithFormat:@"%@: %@", LocalizedString(@"Time to remind"), time];
                        }
                        
                        return norCell;
                    }
                    break;
                default:
                    break;
            }
            break;
            
            case SettingsTableViewSectionUpdate:
                switch (indexPath.row) {
/*                    case UpdateCurrentDate:
                        {
                            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:normalCellIdentifier];
                            if (cell == nil) {
                                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:normalCellIdentifier];
                                cell.accessoryType = UITableViewCellAccessoryNone;
                            }
                            
                            cell.textLabel.textAlignment = NSTextAlignmentLeft;
                            cell.textLabel.textColor = [UIColor blackColor];
                            cell.textLabel.font = [UIFont systemFontOfSize:16];
                            cell.accessoryType = UITableViewCellAccessoryNone;
                            
                            cell.textLabel.text = @"Update current date";
                            
                            return cell;
                        }
                        break;*/
                        
                    case UpdateDatabase:
                        {
                            NSString *updateDBCell = @"UpdateDBCell";
                            
                            SettingCustomTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:updateDBCell];
                            if (cell == nil) {
                                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"SettingCustomTableViewCell" owner:nil options:nil];
                                cell = [nib objectAtIndex:0];
                                cell.accessoryType = UITableViewCellAccessoryNone;
                            }
                            
                            cell.lbTitle.text = LocalizedString(@"Update database");
                            
                            [self displayUpdateAlert:cell];
                            
                            return cell;
                        }
                        break;
                    default:
                        break;
                }
            
        case SettingsTableViewSectionBackup:
        {
            norCell.accessoryType = UITableViewCellAccessoryNone;
            
            switch (indexPath.row) {
                case BackUpDatabase:
                {
                    NSString *code = [[Common sharedCommon] loadDataFromUserDefaultStandardWithKey:KEY_BACKUP_CODE];
                    
                    if (code && code.length > 0) {
                        norCell.textLabel.text = [NSString stringWithFormat:@"%@ (%@)", LocalizedString(@"Backup database"), code];
                        
                    } else {
                        norCell.textLabel.text = LocalizedString(@"Backup database");
                    }

                    return norCell;
                }
                    
                case RestoreDatabase:
                {
                    norCell.textLabel.text = LocalizedString(@"Restore database");
                    return norCell;
                }
                    
                default:
                    break;
            }
        }
            
        case SettingsTableViewSectionAbout:
            switch (indexPath.row) {
                case About:
                {
                    NSString *aboutCell = @"AboutTableViewCell";
                    
                    AboutTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:aboutCell];
                    if (cell == nil) {
                        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"AboutTableViewCell" owner:nil options:nil];
                        cell = [nib objectAtIndex:0];
                        cell.accessoryType = UITableViewCellAccessoryNone;
                    }
                    
                    cell.userInteractionEnabled = NO;
                    
                    NSString *appVer = [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"];
                    
                    cell.lbAppVersion.text = [NSString stringWithFormat:@"%@: %@", LocalizedString(@"App version"), appVer];
                    
                    NSInteger dbVersion = [[[Common sharedCommon] loadDataFromUserDefaultStandardWithKey:KEY_DB_VERSION] integerValue];
                    
                    cell.lbDBVersion.text = [NSString stringWithFormat:@"%@: %ld", LocalizedString(@"Database version"), (long)dbVersion];
                    
                    cell.lbCopyRight.text = LocalizedString(@"CopyRight");
                    
                    return cell;
                }
                    break;
            }
            
            break;
        default:
            break;
    }
    
    return nil;
}

#pragma mark table delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    switch (indexPath.section) {
        case SettingsTableViewSectionLanguage:
            {
                ChangeLanguageViewController *changeLangView = [[ChangeLanguageViewController alloc] initWithNibName:@"ChangeLanguageViewController" bundle:nil];
                
                [self.navigationController pushViewController:changeLangView animated:YES];
            }
            break;
            
        case SettingsTableViewSectionSpeech:
            switch (indexPath.row) {
                case SpeakingSpeed:
                    break;
                    
                default:
                    break;
            }
            break;
            
        case SettingsTableViewSectionDailyTarget:
            switch (indexPath.row) {
                case DailyNewWordTarget:
                    {
                        DailyTargetViewController *dailyTargetView = [[DailyTargetViewController alloc] initWithNibName:@"DailyTargetViewController" bundle:nil];
                        dailyTargetView.targetType = NewWordTargetType;
                        
                        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:dailyTargetView];
                        
                        [nav setModalPresentationStyle:UIModalPresentationFormSheet];
                        [nav setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
                        
                        [self.navigationController presentViewController:nav animated:YES completion:nil];
                    }
                    break;
                    
                case DailyTotalWordsTarget:
                    {
                        DailyTargetViewController *dailyTargetView = [[DailyTargetViewController alloc] initWithNibName:@"DailyTargetViewController" bundle:nil];
                        dailyTargetView.targetType = TotalTargetType;
                        
                        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:dailyTargetView];
                        
                        [nav setModalPresentationStyle:UIModalPresentationFormSheet];
                        [nav setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
                        
                        [self.navigationController presentViewController:nav animated:YES completion:nil];
                    }
                    break;
                    
                case LowestLevel:
                    {
                        [self showLevelPicker];
                    }
                    break;
                    
                case TimeToShowAnswer:
                    {
                        [self showSelectTimePicker];
                    }
                    break;
                default:
                    break;
            }
            break;
            
            
        case SettingsTableViewSectionNotification:
            switch (indexPath.row) {
                case NotificationOnOff:
                    break;
                    
                case NotificationTime:
                    [self showTimePicker];
                    break;
                    
                default:
                    break;
            }
            break;
            
        case SettingsTableViewSectionUpdate:
            switch (indexPath.row) {
/*                case UpdateCurrentDate:
                {
                    [[CommonSqlite sharedCommonSqlite] resetDateOfPickedWordList];
                    
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Date is updated." delegate:(id)self cancelButtonTitle:@"OK" otherButtonTitles: nil];
                    alert.tag = 1;
                    
                    [alert show];
                }
                    break;*/
                    
                case UpdateDatabase:
                {
                    if ([[Common sharedCommon] networkIsActive]) {
                        [self updateDatabaseFromServer];
                        
                    } else {
                        [self noConnectionAlert];
                    }
                }
                    break;
                default:
                    break;
            }
            break;
            
        case SettingsTableViewSectionBackup:
            switch (indexPath.row) {
                case BackUpDatabase:
                {
                    if ([[Common sharedCommon] networkIsActive]) {
                        [[CommonSqlite sharedCommonSqlite] backupData];
                        
//                        [self uploadDatabaseToServer];//move to a common lib
                        if (uploadToSerVer == nil) {
                            uploadToSerVer = [[UploadToServer alloc] init];
                            uploadToSerVer.delegate = (id)self;
                        }
                        
                        [uploadToSerVer uploadDatabaseToServer];
                        
                    } else {
                        [self noConnectionAlert];
                    }
                }
                    break;
                    
                case RestoreDatabase:
                {
                    if ([[Common sharedCommon] networkIsActive]) {
                        //input code to download restored file
                        [self inputCodeToDownloadAlert];
                        
                    } else {
                        [self noConnectionAlert];
                    }
                }
                default:
                    break;
            }
            break;
            
        default:
            break;
    }
}

//NotificationCellDelegate delegate
- (void)switchControlChangeValue:(id)sender {
    NotificationTableViewCell *cell = (NotificationTableViewCell *)sender;
    UISwitch *sw = cell.swControl;
    
    if (cell.tag == SettingsTableViewSectionAutoPlay) {
        NSNumber *autoPlayNumberObj = nil;
        
        if (sw.isOn) {
            autoPlayNumberObj = [NSNumber numberWithBool:YES];
        } else {
            autoPlayNumberObj = [NSNumber numberWithBool:NO];
        }
        
        [[Common sharedCommon] saveDataToUserDefaultStandard:autoPlayNumberObj withKey:KEY_AUTOPLAY];
        
    } else if (cell.tag == SettingsTableViewSectionDisplayMeaning) {
        NSNumber *displayMeaningNumberObj = nil;
        
        if (sw.isOn) {
            displayMeaningNumberObj = [NSNumber numberWithBool:YES];
        } else {
            displayMeaningNumberObj = [NSNumber numberWithBool:NO];
        }
        
        [[Common sharedCommon] saveDataToUserDefaultStandard:displayMeaningNumberObj withKey:KEY_DISPLAYMEANING];
        
    } else if (cell.tag == SettingsTableViewSectionNotification) {
        
        NSNumber *reminderNumberObj = nil;
        
        if (sw.isOn) {
            reminderNumberObj = [NSNumber numberWithBool:YES];
        } else {
            reminderNumberObj = [NSNumber numberWithBool:NO];
        }
        
        [[Common sharedCommon] saveDataToUserDefaultStandard:reminderNumberObj withKey:KEY_REMINDER_ONOFF];
    }
}

#pragma mark alert delegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {

    if (alertView.tag == 1) {
        if (buttonIndex != 0) {
        }
        
    } else if (alertView.tag == 7) {    //input code
        if (buttonIndex != 0) {
            UITextField *textField = [alertView textFieldAtIndex:0];
            
            [self downloadFileFromServerWithCode:textField.text];
        }
        
    } else if (alertView.tag == 8) {    //wrong code
        if (buttonIndex != 0) {
            [self inputCodeToDownloadAlert];
        }
        
    }
    
    return;
}

- (void)showTimePicker {
    timerView = [[TimerViewController alloc] initWithNibName:@"TimerViewController" bundle:nil];

    timerView.view.alpha = 0;
    
    CGRect rect = self.view.frame;
    rect.origin.y = 0;
    [timerView.view setFrame:rect];
    
    [self.view addSubview:timerView.view];
    
    [UIView animateWithDuration:0.3 animations:^(void) {
        timerView.view.alpha = 1;
    }];
}

- (void)showLevelPicker {
    levelView = [[LevelPickerViewController alloc] initWithNibName:@"LevelPickerViewController" bundle:nil];
    levelView.pickerType = LevelPicker;
    levelView.view.alpha = 0;
    
    CGRect rect = self.view.frame;
    rect.origin.y = 0;
    [levelView.view setFrame:rect];
    
    [self.view addSubview:levelView.view];
    
    [UIView animateWithDuration:0.3 animations:^(void) {
        levelView.view.alpha = 1;
    }];
}

- (void)showSelectTimePicker {
    levelView = [[LevelPickerViewController alloc] initWithNibName:@"LevelPickerViewController" bundle:nil];
    levelView.pickerType = WaitingTimePicker;
    levelView.view.alpha = 0;
    
    CGRect rect = self.view.frame;
    rect.origin.y = 0;
    [levelView.view setFrame:rect];
    
    [self.view addSubview:levelView.view];
    
    [UIView animateWithDuration:0.3 animations:^(void) {
        levelView.view.alpha = 1;
    }];
}

- (void)updateDatabaseFromServer {
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    TAGContainer *container = appDelegate.container;
    
    NSLog(@"db version:: %@", [container stringForKey:@"gae_db_version"]);
    
    NSInteger serverVersion = [[container stringForKey:@"gae_db_version"] integerValue];

    __block NSInteger dbVersion = [[[Common sharedCommon] loadDataFromUserDefaultStandardWithKey:KEY_DB_VERSION] integerValue];

    [SVProgressHUD showWithStatus:LocalizedString(@"Updating")];
    dispatch_queue_t taskQ = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    dispatch_async(taskQ, ^{
        [NSThread sleepForTimeInterval:0.1];
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            if (serverVersion > dbVersion) {
                BOOL updatedFlag = YES;
                while (serverVersion > dbVersion) {
                    updatedFlag = YES;
                    NSString *dbPath = [container stringForKey:@"base_url_db"];
                    dbVersion = dbVersion + 1;
                    dbPath = [NSString stringWithFormat:@"%@%ld.db", dbPath, (long)dbVersion];
                    
                    updatedFlag = [[CommonSqlite sharedCommonSqlite] updateDatabaseWithPath:dbPath];
                    
                    if (updatedFlag) {
                        [[Common sharedCommon] saveDataToUserDefaultStandard:[NSNumber numberWithInteger:dbVersion] withKey:KEY_DB_VERSION];
                    } else {
                        break;
                    }
                    
                }
                
                if (updatedFlag) {
                    [SVProgressHUD showSuccessWithStatus:LocalizedString(@"Update successfully")];
                    [self hideUpdateAlert];
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateDatabaseCompleted" object:nil];
                    
                } else {
                    [SVProgressHUD showErrorWithStatus:LocalizedString(@"Update failed")];
                }
                
            } else {
                [SVProgressHUD showSuccessWithStatus:LocalizedString(@"Database is up-to-date")];
            }
        });
    });
}

- (void)displayUpdateAlert:(SettingCustomTableViewCell *)cell {
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    TAGContainer *container = appDelegate.container;
    
    NSLog(@"db version:: %@", [container stringForKey:@"gae_db_version"]);
    
    NSInteger serverVersion = [[container stringForKey:@"gae_db_version"] integerValue];
    
    NSInteger dbVersion = [[[Common sharedCommon] loadDataFromUserDefaultStandardWithKey:KEY_DB_VERSION] integerValue];

    if (serverVersion > dbVersion) {
        [cell startAlertAnimation];
    }
}

- (void)hideUpdateAlert {
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:UpdateDatabase inSection:SettingsTableViewSectionUpdate];
    SettingCustomTableViewCell *cell = [settingsTableView cellForRowAtIndexPath:indexPath];
    
    [cell stopAlertAnimation];
}

- (void)changeLanguageHandle {
    [self setTitle:LocalizedString(@"Settings")];
    [settingsTableView reloadData];
    
}


#pragma mark backup and restore
/* move to a common lib
- (void)uploadDatabaseToServer {
    NSString *pathZip = [[[Common sharedCommon] backupFolder] stringByAppendingPathComponent:DATABASENAME_BACKUPZIP];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:pathZip]) {
        [self sendRequestToGetPostLink];
    }
    
}


- (void)sendRequestToGetPostLink {
    [SVProgressHUD show];

    static GTLServiceDataServiceApi *service = nil;
    if (!service) {
        service = [[GTLServiceDataServiceApi alloc] init];
        service.retryEnabled = YES;
        //[GTMHTTPFetcher setLoggingEnabled:YES];
    }

    GTLQueryDataServiceApi *query = [GTLQueryDataServiceApi queryForGetUploadUrl];
    //TODO: Add waiting progress here
    [service executeQuery:query completionHandler:^(GTLServiceTicket *ticket, GTLDataServiceApiUploadTarget *object, NSError *error) {
        if (object && object.url && object.url.length > 0){
            [self didReceivePostLink:object.url];
            
        } else {
            [SVProgressHUD dismiss];
            [self failedToConnectToServerAlert];
        }
    }];
    
}

- (void)didReceivePostLink:(NSString *)postLink {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:postLink]
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                       timeoutInterval:60.0];
    // Specify that it will be a POST request
    [request setHTTPMethod:@"POST"];
    //—————————
    //    NSString *boundary = @"---------------------------14737809831466499882746641449";
    NSString *boundary = @"born2go14737809831466499882746641449";
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary];
    [request addValue:contentType forHTTPHeaderField: @"Content-Type"];
    
    //adding content as a body to post
    
    NSMutableData *body = [NSMutableData data];
    
    //data files
    NSString *pathZip = [[[Common sharedCommon] backupFolder] stringByAppendingPathComponent:DATABASENAME_BACKUPZIP];
    NSData *dataZip = [NSData dataWithContentsOfFile:pathZip];
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [body appendData:[[NSString stringWithString:[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"file\"; filename=\"%@\"\r\n", DATABASENAME_BACKUPZIP]] dataUsingEncoding:NSUTF8StringEncoding]];
    //[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"file\"; filename=\"%@\"\r\n", view.txtCaption.text]
    
    [body appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[NSData dataWithData:dataZip]];
    
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [body appendData:[@"Content-Type: text/plain\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition:form-data; name=\"device_id\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSString *uniqueIdentifier = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    
    [body appendData:[[NSString stringWithFormat:@"%@", uniqueIdentifier] dataUsingEncoding:NSUTF8StringEncoding]];
    
    //finish
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [request setHTTPBody:body];
    
    //    NSString* test = [[NSString alloc] initWithData:body encoding:NSUTF8StringEncoding];
    //    NSLog(@"test ::: %@", test);
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    
    [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
     {
         dispatch_sync(dispatch_get_main_queue(), ^{
             [SVProgressHUD dismiss];
             if (error == nil && data != nil) {
                 [self didPostingResponse:data];
                 
             } else {
                 [self failedToConnectToServerAlert];
             }
         });
     }];
}

- (void)didPostingResponse:(NSData *)data {

    [self backupSuccessfullyAlert];
}
*/

//restore
- (void)downloadFileFromServerWithCode:(NSString *)code {
    [SVProgressHUD showWithStatus:LocalizedString(@"Restoring")];
    
    dispatch_queue_t taskQ = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    dispatch_async(taskQ, ^{
        [NSThread sleepForTimeInterval:0.5];
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            
            static GTLServiceDataServiceApi *service = nil;
            if (!service) {
                service = [[GTLServiceDataServiceApi alloc] init];
                service.retryEnabled = YES;
                //[GTMHTTPFetcher setLoggingEnabled:YES];
            }
            
            GTLQueryDataServiceApi *query = [GTLQueryDataServiceApi queryForGetDownloadUrlWithCode:code];
            //TODO: Add waiting progress here
            [service executeQuery:query completionHandler:^(GTLServiceTicket *ticket, GTLDataServiceApiDownloadTarget *object, NSError *error) {
                if (object && object.url && object.url.length > 0){
                    [self didReceiveDownloadLink:object.url];
                    
                } else {
                    [self wrongCodeAlert];
                }
                [SVProgressHUD dismiss];
            }];
        });
    });
}

- (void)didReceiveDownloadLink:(NSString *)downloadLink {
    NSURL *storeURL = [NSURL URLWithString:downloadLink];
    
    NSData *data = [NSData dataWithContentsOfURL:storeURL];
    NSString *dbPathNew = [[CommonSqlite sharedCommonSqlite] getBackupDatabasePath];
    
    //remove the existing file
    [[Common sharedCommon] trashFileAtPathAndEmpptyTrash:dbPathNew];
    
    if (data) {
        [data writeToFile:dbPathNew atomically:YES];
        
        //unzip and restore
        BOOL res = [[CommonSqlite sharedCommonSqlite] restoreData];
        
        if (res == NO) {
            [self failedToRestoreAlert];
        } else {
            [self restoreSuccessfullyAlert];
        }
        
    } else {
        [self failedToDownloadFromServerAlert];
        return;
    }
}

- (void)noConnectionAlert {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:LocalizedString(@"No connection") message:LocalizedString(@"Please double check wifi/3G connection") delegate:(id)self cancelButtonTitle:LocalizedString(@"OK") otherButtonTitles:nil];
    alert.tag = 2;
    
    [alert show];
}

- (void)failedToConnectToServerAlert {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:LocalizedString(@"Failed") message:LocalizedString(@"Failed to connect to server") delegate:(id)self cancelButtonTitle:LocalizedString(@"OK") otherButtonTitles:nil];
    alert.tag = 3;
    
    [alert show];
}

- (void)failedToDownloadFromServerAlert {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:LocalizedString(@"Failed") message:LocalizedString(@"Can not download the backed up database") delegate:(id)self cancelButtonTitle:LocalizedString(@"OK") otherButtonTitles:nil];
    alert.tag = 4;
    
    [alert show];
}

- (void)failedToRestoreAlert {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:LocalizedString(@"Failed") message:LocalizedString(@"Can not restore database, please try again.") delegate:(id)self cancelButtonTitle:LocalizedString(@"OK") otherButtonTitles:nil];
    alert.tag = 4;
    
    [alert show];
}

- (void)backupSuccessfullyAlert {
    NSString *content = @"";
    NSString *code = [[Common sharedCommon] loadDataFromUserDefaultStandardWithKey:KEY_BACKUP_CODE];
    //show code
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:BackUpDatabase inSection:SettingsTableViewSectionBackup];
    [settingsTableView beginUpdates];
    [settingsTableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
    [settingsTableView endUpdates];
    
    content = [NSString stringWithFormat:@"%@:\n%@", LocalizedString(@"Your database will be archived on server in 7 days"), code];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:LocalizedString(@"Successfully") message:content delegate:(id)self cancelButtonTitle:LocalizedString(@"OK") otherButtonTitles:nil];
    alert.tag = 5;
    
    [alert show];
}

- (void)restoreSuccessfullyAlert {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:LocalizedString(@"Successfully") message:LocalizedString(@"Your database have been restored successfully") delegate:(id)self cancelButtonTitle:LocalizedString(@"OK") otherButtonTitles:nil];
    alert.tag = 6;
    
    [alert show];
}
- (void)inputCodeToDownloadAlert {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:LocalizedString(@"Restore database")
                                                        message:LocalizedString(@"Input code that you achieved when backing up database")
                                                       delegate:self
                                              cancelButtonTitle:LocalizedString(@"Cancel")
                                              otherButtonTitles:LocalizedString(@"OK"), nil];
    
    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    alertView.tag = 7;
    [alertView show];
}

- (void)wrongCodeAlert {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:LocalizedString(@"Failed") message:LocalizedString(@"Wrong code, please try again") delegate:(id)self cancelButtonTitle:LocalizedString(@"Cancel") otherButtonTitles:LocalizedString(@"Try again"), nil];
    alert.tag = 8;
    
    [alert show];
}
@end
