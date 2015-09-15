//
//  SettingsViewController.h
//  LazzyBee
//
//  Created by HuKhong on 3/3/15.
//  Copyright (c) 2014 ITPRO. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    SettingsTableViewSectionAbout = 0,
    SettingsTableViewSectionSpeech,
    SettingsTableViewSectionDailyTarget,
    SettingsTableViewSectionNotification,
    SettingsTableViewSectionReset,
    SettingsTableViewSectionMax
} SETTINGS_TABLEVIEW_SECTION;

typedef enum {
    About = 0,
    AboutSectionMax
} ABOUT_SECTION;

typedef enum {
    SpeakingSpeed = 0,
    SpeechSectionMax
} SPEECH_SECTION;

typedef enum {
    DailyTarget = 0,
    DailyTargetSectionMax
} DAILY_SECTION;

typedef enum {
    NotificationOnOff = 0,
    NotificationTime,
    NotificationSectionMax
} NOTIFICATION_SECTION;

typedef enum {
    Reset = 0,
    ResetSectionMax
} RESET_SECTION;

@interface SettingsViewController : UIViewController
{
    IBOutlet UITableView *settingsTableView;
    
}
@end