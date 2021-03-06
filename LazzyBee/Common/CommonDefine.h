//
//  CommonDefine.h
//  LazzyBee
//
//  Created by HuKhong on 4/19/15.
//  Copyright (c) 2015 HuKhong. All rights reserved.
//

#ifndef LazzyBee_CommonDefine_h
#define LazzyBee_CommonDefine_h
#import <Foundation/Foundation.h>

#define IS_OS_8_OR_LATER    ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)
#define IS_IPAD (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
#define IS_IPHONE (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
#define IS_IPHONE_5 (IS_IPHONE && ([[UIScreen mainScreen] bounds].size.height == 568.0) && ((IS_OS_8_OR_LATER && [UIScreen mainScreen].nativeScale == [UIScreen mainScreen].scale) || !IS_OS_8_OR_LATER))
#define IS_STANDARD_IPHONE_6 (IS_IPHONE && [[UIScreen mainScreen] bounds].size.height == 667.0  && IS_OS_8_OR_LATER && [UIScreen mainScreen].nativeScale == [UIScreen mainScreen].scale)
#define IS_ZOOMED_IPHONE_6 (IS_IPHONE && [[UIScreen mainScreen] bounds].size.height == 568.0 && IS_OS_8_OR_LATER && [UIScreen mainScreen].nativeScale > [UIScreen mainScreen].scale)
#define IS_STANDARD_IPHONE_6_PLUS (IS_IPHONE && [[UIScreen mainScreen] bounds].size.height == 736.0)
#define IS_ZOOMED_IPHONE_6_PLUS (IS_IPHONE && [[UIScreen mainScreen] bounds].size.height == 667.0 && IS_OS_8_OR_LATER && [UIScreen mainScreen].nativeScale < [UIScreen mainScreen].scale)

//#define COMMON_COLOR [UIColor colorWithRed:243/255.f green:111/255.f blue:33/255.f alpha:1]
//#define COMMON_COLOR [UIColor colorWithRed:100/255.f green:142/255.f blue:45/255.f alpha:1]
#define COMMON_COLOR [UIColor colorWithRed:255/255.f green:200/255.f blue:47/255.f alpha:1]
#define GREEN_COLOR [UIColor colorWithRed:60/255.f green:159/255.f blue:30/255.f alpha:1]
#define BLUE_COLOR [UIColor colorWithRed:0/255.f green:103/255.f blue:194/255.f alpha:1]

#define SERVER_LINK  @"http://192.168.0.202"
#define REQUEST_HOME @""

#define DATABASENAME @"english.db"
#define DATABASENAME_NEW @"new_english.db"
#define DATABASENAME_BACKUP @"word.csv"
#define STREAK_BACKUP @"streak.csv"
#define DATABASENAME_BACKUPZIP [NSString stringWithFormat:@"%@.zip", [[Common sharedCommon] loadDataFromUserDefaultStandardWithKey:KEY_BACKUP_CODE]]

#define SECONDS_OF_DAY (24*3600)
#define SECONDS_OF_HALFDAY (12*3600)

#define BUFFER_SIZE 100
#define TOTAL_WORDS_A_DAY_MAX [[[Common sharedCommon] loadDataFromUserDefaultStandardWithKey:KEY_DAILY_TOTAL_TARGET] integerValue]

//user default keys
#define KEY_SPEAKING_SPEED @"SpeakingSpeed"
#define KEY_REMIND_TIME @"RemindTime"
#define KEY_LOWEST_LEVEL @"LowestLevel"
#define KEY_REMINDER_ONOFF @"ReminderOnOff"
#define KEY_AUTOPLAY @"AutoPlay"
#define KEY_DISPLAYMEANING @"DisplayMeaning"
#define KEY_DAILY_TARGET @"DailyTarget"
#define KEY_DAILY_TOTAL_TARGET @"DailyTotalTarget"
#define KEY_DB_VERSION @"DatabaseVersion"
#define KEY_COMPLETED_FLAG @"CompletedDailyTargetFlag"
#define KEY_TIME_TO_SHOW_ANSWER @"TimeToShowAnswer"
#define IS_FIRST_RUN @"IsFirstRun"
#define KEY_SELECTED_MAJOR @"SelectedMajor"
#define KEY_BACKUP_CODE @"BackupCode"
#define KEY_STREAK_INFO @"StreakInfo"
#define KEY_SHOW_GUIDE @"ShowGuide"
#define KEY_REVERSE_ENABLE @"ReverseEnable"

#define BACKUP_CODE_LENGTH 6
#define NUMBER_OF_STREAK_TO_BACKUP 10
#define NUMBER_OF_WORD_TO_ACTIVATE_REVERSE 50

//firebase
#define PROPERTY_SELECTED_LANG @"Selected_language"
#define PROPERTY_SELECTED_MAJOR @"Selected_major"
#define PROPERTY_DAILY_NEW_WORD @"Daily_new_word"
#define PROPERTY_DAILY_TOTAL_WORD @"Daily_total_word"
#define PROPERTY_SELECTED_LEVEL @"Selected_level"
#define PROPERTY_SELECTED_WAITING_TIME @"Selected_waiting_time"
#define PROPERTY_AUTOPLAY_SOUND @"Autoplay_sound"
#define PROPERTY_DISPLAY_MEANING @"Display_meaning"
#define PROPERTY_NOTIFICATION_STATUS @"notification_status"

#define EVENT_COUNT_REVIEW_W_PER_DAY @"Count_review_per_day"
#define EVENT_DAILY_NEW_WORD @"Daily_new_word"
#define EVENT_DAILY_TOTAL_WORD @"Daily_total_word"
#define EVENT_STREAK @"Streak"
#define EVENT_SEARCH_NOT_FOUND @"Search_not_found"

@interface CommonDefine : NSObject


@end

#endif
