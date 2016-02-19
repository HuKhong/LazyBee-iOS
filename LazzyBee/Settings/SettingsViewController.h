//
//  SettingsViewController.h
//  LazzyBee
//
//  Created by HuKhong on 3/3/15.
//  Copyright (c) 2014 ITPRO. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    SettingsTableViewSectionLanguage = 0,
    SettingsTableViewSectionSpeech,
    SettingsTableViewSectionAutoPlay,
    SettingsTableViewSectionDisplayMeaning,
    SettingsTableViewSectionDailyTarget,
    SettingsTableViewSectionNotification,
    SettingsTableViewSectionUpdate,
    SettingsTableViewSectionBackup,
    SettingsTableViewSectionMax
} SETTINGS_TABLEVIEW_SECTION;

typedef enum {
    ChangeLanguage = 0,
    LanguageSectionMax
} LANGUAGE_SECTION;

typedef enum {
    SpeakingSpeed = 0,
    SpeechSectionMax
} SPEECH_SECTION;

typedef enum {
    DailyNewWordTarget = 0,
    DailyTotalWordsTarget,
    LowestLevel,
    TimeToShowAnswer,
    DailyTargetSectionMax
} DAILY_SECTION;

typedef enum {
    AutoPlaySound = 0,
    AutoPlayMax
} AUTOPLAY_SECTION;

typedef enum {
    DisplayVietnamese = 0,
    DisplayMeaningMax
} DISPLAYMEANING_SECTION;

typedef enum {
    NotificationOnOff = 0,
    NotificationTime,
    NotificationSectionMax
} NOTIFICATION_SECTION;

typedef enum {
//    UpdateCurrentDate = 0,
    UpdateDatabase = 0,
    UpdateSectionMax
} UPDATE_SECTION;

typedef enum {
    //    UpdateCurrentDate = 0,
    BackUpDatabase = 0,
    RestoreDatabase,
    BackupSectionMax
} BACKUP_SECTION;

@interface SettingsViewController : UIViewController
{
    IBOutlet UITableView *settingsTableView;
    
}
@end
