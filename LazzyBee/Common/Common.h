//
//  common.h
//  unknown
//
//  Created by HuKhong on 3/3/15.
//  Copyright (c) 2015 HuKhong. All rights reserved.
//


#ifndef ImportContact_common_h
#define ImportContact_common_h
#import "CommonAlert.h"
#import "CommonDefine.h"
#import <UIKit/UIKit.h>


#define MINUMUM_Y_OFFSET 60

typedef enum {
    Position_Normal = 0,
    Position_Minimum,
    Position_Maximum
} POSITION_VIEW;


@interface Common : NSObject
{
    
}

@property (nonatomic, strong) NSString *downloadFolder;
@property (nonatomic, strong) NSString *documentsFolder;
@property (nonatomic, strong) NSString *libraryFolder;
@property (nonatomic, strong) NSString *tmpFolder;
@property (nonatomic, strong) NSString *privateDocumentsFolder;
@property (nonatomic, strong) NSString *trashFolder;
@property (nonatomic, strong) NSString *backupFolder;
@property (nonatomic, strong) NSString *restoreFolder;
@property (nonatomic, strong) NSString *dataFolder;

@property (nonatomic, assign) BOOL isBuffeAcc;


- (NSString *)downloadFolder;
- (NSString *)documentsFolder;
- (NSString *)libraryFolder;
- (NSString *)tmpFolder;
- (NSString *)privateDocumentsFolder;
- (NSString *)trashFolder;
- (NSString *)backupFolder;
- (NSString *)restoreFolder;
- (NSString *)dataFolder;

+ (Common *)sharedCommon;

- (NSString *)parsePhoneType:(NSString *)phoneType;
- (NSString *)addPrefixToPhoneNumber:(NSString *)phoneNumber;

- (void)saveDataToPlistFile:(NSArray *)data plistFile:(NSString *)plistFile;
- (NSArray *)loadDataFromPlist:(NSString *)plistFile;
- (void)saveDataToUserDefaultStandard:(id)data withKey:(NSString *)key;
- (id)loadDataFromUserDefaultStandardWithKey:(NSString *)key;
- (void)clearUserDefaultStandardWithKey:(NSString *)key;

- (void)saveDataToGroupUserDefaultStandard:(id)data withKey:(NSString *)key;
- (id)loadDataFromGroupUserDefaultStandardWithKey:(NSString *)key;

- (void)savePersonalData:(NSObject *)personObject withKey:(NSString *)key;
- (NSObject *)loadPersonalDataWithKey:(NSString *)key;

- (NSInteger)getDailyTarget;
- (NSString *)getCurrentDatetimeWithFormat:(NSString *)formatString;
- (NSString *)getNextDatetimeWithFormat:(NSString *)formatString;
- (NSString *)dateStringFromDate:(NSDate *)date withFormat:(NSString *)formatString;
- (NSString *)timeStringFromDate:(NSDate *)date;
- (NSString *)stringDateFromString:(NSString *)dateStr;
- (NSDate *)dateFromString:(NSString *)dateStr;
- (NSTimeInterval)getCurrentDatetimeInMinisec;
- (NSTimeInterval)getBeginOfDayInMinisec;
- (NSTimeInterval)getCurrentDatetimeInSec;
- (NSTimeInterval)getBeginOfDayInSec;
- (NSString *)getDayOfWeek:(NSDate *)date;
- (NSString *)convertDateOfWeekToVN:(NSString *)dateOfWeek;

- (void)trashFileAtPathAndEmpptyTrash:(NSString *)path;
- (NSString *)trashFileAtPath:(NSString *)path;
- (void)emptyTrash;
- (BOOL)checkFileExist:(NSString *)filePath;
- (NSString *)fileExistingInTempFolder;

- (void)sendSMS:(NSString *)bodyOfMessage recipientList:(NSArray *)recipients viewController:(id)viewController;

- (BOOL)networkIsActive;
- (BOOL) isUsingWifi;

- (NSString *)encodeURL:(NSString *)unencodedURL;

- (void)increaseRecordingCount;
- (NSInteger)getRecordingCount;

- (UIImage *)scaleAndRotateImage:(UIImage *)image withMaxSize:(int)kMaxResolution;
- (UIImage *)imageFromText:(NSString *)text;
- (UIImage *)createImageFromView:(UIView *)view;

- (BOOL)validateEmailWithString:(NSString*)email;
- (NSString *)hidePhoneNumber:(NSString *)phonenumber;

- (NSString *) stringByRemovingHTMLTag:(NSString *)text;
- (NSString *)stringByRemovingSpaceAndNewLineSymbol:(NSString *)text;

- (void)textToSpeech:(NSString *)text withRate:(float)rate;

- (void)saveStreak:(NSTimeInterval)date;
- (NSArray *)loadStreak;
- (NSInteger)getCountOfStreak;

@end
#endif
