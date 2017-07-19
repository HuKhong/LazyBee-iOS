//
//  common.m
//  LazzyBee
//
//  Created by HuKhong on 3/3/15.
//  Copyright (c) 2015 HuKhong. All rights reserved.
//

#import "CommonSqlite.h"
#import <Foundation/Foundation.h>
#import "Common.h"
#import "Reachability.h"
#import <AVFoundation/AVFoundation.h>

@import MessageUI;

@implementation Common
@synthesize downloadFolder, documentsFolder, libraryFolder, tmpFolder, privateDocumentsFolder, trashFolder, backupFolder, restoreFolder, dataFolder;

- (id)init {
    self = [super init];
    if (self) {
        
    }
    return self;
}


+(Common *)sharedCommon {
    static Common *sharedCommon = nil;
    if (!sharedCommon) {
        sharedCommon = [[super allocWithZone:nil] init];
    }
    return sharedCommon;
}

+(id)allocWithZone:(NSZone *)zone {
    return [self sharedCommon];
}

- (NSString *)parsePhoneType:(NSString *)phoneType {
    NSString *res = @"";
    NSRange first = [phoneType rangeOfString:@"<"];
    NSRange last = [phoneType rangeOfString:@">"];
    NSRange range;
    
    if (first.location != NSNotFound && last.location != NSNotFound) {
        range.location = first.location + 1;
        range.length = last.location - first.location -1;
        res = [phoneType substringWithRange:range];
    } else {
        res = phoneType;
    }

    return res;
}

- (NSString *)addPrefixToPhoneNumber:(NSString *)phoneNumber {
    if (phoneNumber.length > 0) {
        NSString *phoneWithPrefix = phoneNumber;
        phoneWithPrefix = [[phoneWithPrefix componentsSeparatedByCharactersInSet:
                            [[NSCharacterSet decimalDigitCharacterSet] invertedSet]]
                           componentsJoinedByString:@""];
        if (phoneWithPrefix.length > 0) {
//            phoneWithPrefix = [PHONE_PREFIX stringByAppendingString:phoneWithPrefix];
        } else {
            phoneWithPrefix = @"";
        }
        
        return phoneWithPrefix;
        
    } else {
        return @"";
    }
}

- (void)saveDataToPlistFile:(NSArray *)data plistFile:(NSString *)plistFile {
    NSFileManager *fileManager = [NSFileManager defaultManager]; // File manager instance
    
    NSString *pathURL = [[fileManager URLForDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:NULL] path];
    NSString *filePath = [pathURL stringByAppendingPathComponent:plistFile];
    
    NSError  *error;
    NSData* archiveData = [NSKeyedArchiver archivedDataWithRootObject:data];
    [archiveData writeToFile:filePath options:NSDataWritingAtomic error:&error];
    archiveData = nil;
}

- (NSArray *)loadDataFromPlist:(NSString *)plistFile {
    NSFileManager *fileManager = [NSFileManager defaultManager]; // File manager instance
    
    NSString *pathURL = [[fileManager URLForDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:NULL] path];
    NSString *filePath = [pathURL stringByAppendingPathComponent:plistFile];
    
    NSMutableArray *resArr = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
    
    if (resArr == nil)
    {
        resArr = [[NSMutableArray alloc] init];
    }
    
    return resArr;
}

#pragma mark user default
- (void)saveDataToUserDefaultStandard:(id)data withKey:(NSString *)key {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
   
    [defaults setObject:data forKey:key];
}

- (id)loadDataFromUserDefaultStandardWithKey:(NSString *)key {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    id data = [defaults objectForKey:key];
    
    return data;
}

- (void)saveDataToGroupUserDefaultStandard:(id)data withKey:(NSString *)key {
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.born2go.lazzybee"];
    
    [defaults setObject:data forKey:key];
    
    [defaults synchronize];
}

- (id)loadDataFromGroupUserDefaultStandardWithKey:(NSString *)key {
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.born2go.lazzybee"];
    id data = [defaults objectForKey:key];
    
    return data;
}

- (void)clearUserDefaultStandardWithKey:(NSString *)key {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:key];
}

- (void)savePersonalData:(NSObject *)personObject withKey:(NSString *)key {

    NSData *personEncodedObject = [NSKeyedArchiver archivedDataWithRootObject:personObject];
    
    NSUserDefaults *userData = [NSUserDefaults standardUserDefaults];
    [userData setObject:personEncodedObject forKey:key];
}

- (NSObject *)loadPersonalDataWithKey:(NSString *)key {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSData *data = [defaults objectForKey:key];
    NSObject *res =  nil;
    
    if (data) {
        res = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    }
    return res;
}

//
- (NSInteger)getDailyTarget {
    NSNumber *target  = [self loadDataFromUserDefaultStandardWithKey:KEY_DAILY_TARGET];
    
    return [target integerValue];
}

- (NSTimeInterval)getCurrentDatetimeInMinisec {
    
    NSString *curDateString = [self getCurrentDatetimeWithFormat:@"dd/MM/yyyy HH:mm:ss"];
    NSDate *curDate = [self dateFromString:curDateString];
    NSTimeInterval datetime = [curDate timeIntervalSince1970] * 1000;
    
    return datetime;
}

//doesn't count seconds
- (NSTimeInterval)getBeginOfDayInMinisec {
    NSString *curDateString = [self getCurrentDatetimeWithFormat:@"dd/MM/yyyy 00:00:00"];
    NSDate *curDate = [self dateFromString:curDateString];
    NSTimeInterval datetime = [curDate timeIntervalSince1970] * 1000;
    
    return datetime;
}

- (NSTimeInterval)getCurrentDatetimeInSec {
    
    NSString *curDateString = [self getCurrentDatetimeWithFormat:@"dd/MM/yyyy HH:mm:ss"];
    NSDate *curDate = [self dateFromString:curDateString];
    NSTimeInterval datetime = [curDate timeIntervalSince1970];
    
    return datetime;
}

//doesn't count seconds
- (NSTimeInterval)getBeginOfDayInSec {
    NSString *curDateString = [self getCurrentDatetimeWithFormat:@"dd/MM/yyyy 00:00:00"];
    NSDate *curDate = [self dateFromString:curDateString];
    NSTimeInterval datetime = [curDate timeIntervalSince1970];
    
    return datetime;
}

- (NSString *)getCurrentDatetimeWithFormat:(NSString *)formatString {
    NSString *dateString = nil;
    NSLocale* currentLocale = [NSLocale currentLocale];
    [[NSDate date] descriptionWithLocale:currentLocale];
    
    NSDate *curDate = [NSDate date];
    
    dateString = [self dateStringFromDate:curDate withFormat:formatString];
    
    return dateString;
}

- (NSString *)getNextDatetimeWithFormat:(NSString *)formatString {
    NSString *dateString = nil;
    NSLocale* currentLocale = [NSLocale currentLocale];
    [[NSDate date] descriptionWithLocale:currentLocale];
    
    NSTimeInterval nextTimeInterval = [self getCurrentDatetimeInSec] + SECONDS_OF_DAY;
    NSDate *nextDate = [NSDate dateWithTimeIntervalSince1970:nextTimeInterval];
    
    dateString = [self dateStringFromDate:nextDate withFormat:formatString];
    
    return dateString;
}

- (NSString *)dateStringFromDate:(NSDate *)date withFormat:(NSString *)formatString {
    NSString *dateString = nil;
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    
    NSString *locale = [[NSLocale currentLocale] localeIdentifier];
    NSLocale *currentLocale = [[NSLocale alloc] initWithLocaleIdentifier:locale];
    [format setLocale:currentLocale];
    [format setTimeZone:[NSTimeZone localTimeZone]];
    
    [format setDateFormat:formatString];
    
    dateString = [format stringFromDate:date];

    return dateString;
}

- (NSString *)timeStringFromDate:(NSDate *)date {
    NSString *dateString = nil;
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    
    NSString *locale = [[NSLocale currentLocale] localeIdentifier];
    NSLocale *currentLocale = [[NSLocale alloc] initWithLocaleIdentifier:locale];
    [format setLocale:currentLocale];
    [format setTimeZone:[NSTimeZone localTimeZone]];
    [format setDateFormat:@"HH:mm"];
    
    // set default NSGregorianCalendar
    NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *components = [gregorianCalendar components:(NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitYear |NSCalendarUnitMonth|NSCalendarUnitDay) fromDate:date];
    
    NSDate *dateNew = [gregorianCalendar dateFromComponents:components];
    
    dateString = [format stringFromDate:dateNew];
    format = nil;
    return dateString;
}

- (NSDate *)dateFromString:(NSString *)dateStr {
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    NSString *locale = [[NSLocale currentLocale] localeIdentifier];
    NSLocale *currentLocale = [[NSLocale alloc] initWithLocaleIdentifier:locale];
    [dateFormatter setLocale:currentLocale];
    [dateFormatter setTimeZone:[NSTimeZone localTimeZone]];
    
    NSDate *date = [dateFormatter dateFromString:dateStr];
    //Apr 25, 2015 5:15:22 AM
    if (date == nil) {
        dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mmZZZ";
        date = [dateFormatter dateFromString:dateStr];
    }

    if (date == nil) {
        dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZZZ";
        date = [dateFormatter dateFromString:dateStr];
    }

    if (date == nil) {
        dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss";
        date = [dateFormatter dateFromString:dateStr];
    }

    if (date == nil) {
        dateFormatter.dateFormat = @"yyyyMMdd";
        date = [dateFormatter dateFromString:dateStr];
    }

    if (date == nil) {
        dateFormatter.dateFormat = @"MMM dd/yyyy";
        date = [dateFormatter dateFromString:dateStr];
    }

    if (date == nil) {
        dateFormatter.dateFormat = @"yyyyMMddHHmmss";
        date = [dateFormatter dateFromString:dateStr];
    }
    
    if (date == nil) {
        dateFormatter.dateFormat = @"yyyyMMddHHmm";
        date = [dateFormatter dateFromString:dateStr];
    }
    
    if (date == nil) {
        dateFormatter.dateFormat = @"MMM dd, yyyy HH:mm:ss a";
        date = [dateFormatter dateFromString:dateStr];
    }
    
    if (date == nil) {
        dateFormatter.dateFormat = @"dd/MM/yyyy HH:mm:ss";
        date = [dateFormatter dateFromString:dateStr];
    }
    
    if (date == nil) {
        dateFormatter.dateFormat = @"dd/MM/yyyy HH:mm";
        date = [dateFormatter dateFromString:dateStr];
    }
    
    if (date == nil) {
        dateFormatter.dateFormat = @"dd/MM/yyyy";
        date = [dateFormatter dateFromString:dateStr];
    }
    
    if (date == nil) {
        dateFormatter.dateFormat = @"yyyy-MM-dd";
        date = [dateFormatter dateFromString:dateStr];
    }
    
    if (date == nil) {
        dateFormatter.dateFormat = @"yyyy/MM/dd";
        date = [dateFormatter dateFromString:dateStr];
    }
    
    if (date == nil) {
        dateFormatter.dateFormat = @"HH:mm";
        date = [dateFormatter dateFromString:dateStr];
    }
    
    dateFormatter = nil;
    
    return date;
}

- (NSString *)stringDateFromString:(NSString *)dateStr {
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"dd/MM/yyyy";
    NSString *rv = [dateFormatter stringFromDate:[self dateFromString:dateStr]];
    dateFormatter = nil;
    return rv;
}

- (NSString *)getDayOfWeek:(NSDate *)date {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"EEEE"];
    NSLocale *frLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    [dateFormatter setLocale:frLocale];
//    NSString *locale = [[NSLocale currentLocale] localeIdentifier];
//    NSLocale *currentLocale = [[NSLocale alloc] initWithLocaleIdentifier:locale];
//    [dateFormatter setLocale:currentLocale];
//    [dateFormatter setTimeZone:[NSTimeZone localTimeZone]];
    NSString *res = @"";
    
    NSString *curLang = [[NSUserDefaults standardUserDefaults] objectForKey:@"CurrentLanguageInApp"];
    if (curLang == nil) {
        res = [self convertDateOfWeekToVN:[dateFormatter stringFromDate:date]];
    } else {
        if ([curLang isEqualToString:@"vi"]) {
            res = [self convertDateOfWeekToVN:[dateFormatter stringFromDate:date]];
        } else if ([curLang isEqualToString:@"en"]) {
            res = [dateFormatter stringFromDate:date];
        }
    }
    return res;
}

- (NSString *)convertDateOfWeekToVN:(NSString *)dateOfWeek {
    NSString *res = dateOfWeek;
    
    if ([[res lowercaseString] isEqualToString:@"monday"]) {
        res = @"T2";
    } else if ([[res lowercaseString] isEqualToString:@"tuesday"]) {
        res = @"T3";
    } else if ([[res lowercaseString] isEqualToString:@"wednesday"]) {
        res = @"T4";
    } else if ([[res lowercaseString] isEqualToString:@"thursday"]) {
        res = @"T5";
    } else if ([[res lowercaseString] isEqualToString:@"friday"]) {
        res = @"T6";
    } else if ([[res lowercaseString] isEqualToString:@"saturday"]) {
        res = @"T7";
    } else if ([[res lowercaseString] isEqualToString:@"sunday"]) {
        res = @"CN";
    }
    
    return res;
}

//folder
-(NSString *)applicationSupportFolder {
    return [[[NSFileManager defaultManager] URLForDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:NULL] path];
}

/*
 Returns the Download folder path from the sandbox
 */
-(NSString *)downloadFolder {
    if (downloadFolder == nil) {
        downloadFolder = [[self applicationSupportFolder] stringByAppendingPathComponent:@"Download"];
    }
    
//    NSLog(@"downloadFolder: %@", documentsFolder);
    return downloadFolder;
}

/*
 Returns the Document folder path from the sandbox
 */
-(NSString *)documentsFolder {
    if (documentsFolder == nil) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        documentsFolder = [paths objectAtIndex:0];
    }
    
//    NSLog(@"documentsFolder: %@", documentsFolder);
    return documentsFolder;
}

/*
 Return the path to the Library folder
 */
-(NSString *)libraryFolder {
    if (libraryFolder == nil) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
        libraryFolder = [paths objectAtIndex:0];
    }
    
//    NSLog(@"libraryFolder: %@", libraryFolder);
    return libraryFolder;
}

/*
 Return the path to the tmp folder
 */
-(NSString *)tmpFolder {
    if (tmpFolder == nil) {
        tmpFolder = [privateDocumentsFolder stringByAppendingPathComponent:@"Temp Folder"];
        [[NSFileManager defaultManager] createDirectoryAtPath:tmpFolder withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
//    NSLog(@"tmpFolder: %@", tmpFolder);
    return tmpFolder;
}

/*
 Creates the "Private Documents" folder if needed and returns the path to it
 */
-(NSString *)privateDocumentsFolder {
    if (privateDocumentsFolder == nil) {
        privateDocumentsFolder = [[self libraryFolder] stringByAppendingPathComponent:@"Private Documents"];
        NSError *error;
        [[NSFileManager defaultManager] createDirectoryAtPath:privateDocumentsFolder withIntermediateDirectories:YES attributes:nil error:&error];
    }
    
//    NSLog(@"privateDocumentsFolder: %@", privateDocumentsFolder);
    return privateDocumentsFolder;
}

- (NSString *)trashFolder {
    if (trashFolder == nil) {
        trashFolder = [[self libraryFolder] stringByAppendingPathComponent:@"Trash Folder"];
        
        [[NSFileManager defaultManager] createDirectoryAtPath:trashFolder withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return trashFolder;
}

/*
 Return the path to the backup folder
 */
-(NSString *)backupFolder {
    if (backupFolder == nil) {
        backupFolder = [[self libraryFolder] stringByAppendingPathComponent:@"Backup"];
        [[NSFileManager defaultManager] createDirectoryAtPath:backupFolder withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    //    NSLog(@"backupFolder: %@", backupFolder);
    return backupFolder;
}

-(NSString *)restoreFolder {
    if (restoreFolder == nil) {
        restoreFolder = [[self libraryFolder] stringByAppendingPathComponent:@"Restore"];
        [[NSFileManager defaultManager] createDirectoryAtPath:restoreFolder withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    //    NSLog(@"restoreFolder: %@", restoreFolder);
    return restoreFolder;
}

-(NSString *)dataFolder {
    if (dataFolder == nil) {
        dataFolder = [[self libraryFolder] stringByAppendingPathComponent:@"Data"];
        [[NSFileManager defaultManager] createDirectoryAtPath:dataFolder withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    //    NSLog(@"dataFolder: %@", dataFolder);
    return dataFolder;
}

- (BOOL) networkIsActive {
    //Attempt to connect to sample host using Reachability
    Reachability* reachability = [Reachability reachabilityWithHostName:@"www.google.com"];
    NetworkStatus remoteHostStatus = [reachability currentReachabilityStatus];
    
    //Check remoteHostStatus
    if(remoteHostStatus == NotReachable)
    {
        NSLog(@"Host not reachable");
        return NO;
    }
    else if (remoteHostStatus == ReachableViaWWAN)
    {
        NSLog(@"Host reachable via wwan");
        return YES;
    }
    else if (remoteHostStatus == ReachableViaWiFi)
    {
        NSLog(@"Host reachable via wifi");
        return YES;
    }
    return NO;
}

- (BOOL) isUsingWifi {
    //Attempt to connect to sample host using Reachability
//    Reachability* reachability = [Reachability reachabilityWithHostName:@"www.google.com"];
//    Reachability *reachability = [Reachability reachabilityForInternetConnection];
//    [reachability startNotifier];
//    
//    NetworkStatus remoteHostStatus = [reachability currentReachabilityStatus];
//    
//    //Check remoteHostStatus
//    if(remoteHostStatus == NotReachable)
//    {
//        NSLog(@"Host not reachable");
//        return YES;
//    }
//    else if (remoteHostStatus == ReachableViaWWAN)
//    {
//        NSLog(@"Host reachable via wwan");
//        return NO;
//    }
//    else if (remoteHostStatus == ReachableViaWiFi)
//    {
//        NSLog(@"Host reachable via wifi");
//        return YES;
//    }
//    return YES;
/*    BOOL res = YES;
    NSArray *subviews = [[[[UIApplication sharedApplication] valueForKey:@"statusBar"] valueForKey:@"foregroundView"]subviews];
    NSNumber *dataNetworkItemView = nil;
    
    for (id subview in subviews) {
        if([subview isKindOfClass:[NSClassFromString(@"UIStatusBarDataNetworkItemView") class]]) {
            dataNetworkItemView = subview;
            break;
        }
    }
    
    switch ([[dataNetworkItemView valueForKey:@"dataNetworkType"]integerValue]) {
        case 0:
            NSLog(@"No wifi or cellular");
            break;
            
        case 1:
            NSLog(@"2G");
            res = NO;
            break;
            
        case 2:
            NSLog(@"3G");
            res = NO;
            break;
            
        case 3:
            NSLog(@"4G");
            res = NO;
            break;
            
        case 4:
            NSLog(@"LTE");
            res = NO;
            break;
            
        case 5:
            NSLog(@"Wifi");
            res = YES;
            break;
            
        default:
            break;
    };
*/    
    return NO;
}

- (void)emptyTrash {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[self trashFolder] error:nil];
        if (files != nil && files.count > 0) {
            for (NSString *file in files) {
                NSString *path = [[self trashFolder] stringByAppendingPathComponent:file];
                
                [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
            }
        }
    });
}

/*
 Moves the object at path to the trash and returns the path to it if successful
 */
-(NSString *)trashFileAtPath:(NSString *)path {
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:path]) {
        NSString *filename = [path lastPathComponent];
        NSString *trashPath = [[self trashFolder] stringByAppendingPathComponent:filename];
        int n = 0;
        while ([fm fileExistsAtPath:trashPath]) {
            n++;
            trashPath = [trashFolder stringByAppendingPathComponent:[NSString stringWithFormat:@"%@(%d)", filename, n]];
        }
        NSError *error;
        [fm moveItemAtPath:path toPath:trashPath error:&error];
        if (error == nil) {
            return trashPath;
        }
    }
    return nil;
}

//move the folder at path to trash and delete it
- (void)trashFileAtPathAndEmpptyTrash:(NSString *)path {
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSString *deletedName = [self trashFileAtPath:path];
        if (deletedName) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                [[NSFileManager defaultManager] removeItemAtPath:deletedName error:nil];
            });
        }
    }
}

- (BOOL)checkFileExist:(NSString *)filePath {
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:filePath]) {
        return YES;
    }
    
    return NO;
}

- (void)sendSMS:(NSString *)bodyOfMessage recipientList:(NSArray *)recipients viewController:(id)viewController {
    MFMessageComposeViewController *controller = [[MFMessageComposeViewController alloc] init];
    
    if([MFMessageComposeViewController canSendText])
    {
        controller.body = bodyOfMessage;
        controller.recipients = recipients;
        controller.messageComposeDelegate = (id)viewController;
        [viewController presentViewController:controller animated:YES completion:nil];
    }
}

- (NSString *)encodeURL:(NSString *)unencodedURL {
    NSString *encodedString = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
                                                                                  NULL,
                                                                                  (CFStringRef)unencodedURL,
                                                                                  NULL,
                                                                                  (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                                  kCFStringEncodingUTF8 ));
    
    return encodedString;
}

- (NSString *)fileExistingInTempFolder {
    NSArray * directoryContents = [[NSFileManager defaultManager]
                                    contentsOfDirectoryAtPath:[self tmpFolder] error:nil];
    
    for (NSString *path in directoryContents) {
        if ([path rangeOfString:@"temp.wav"].location != NSNotFound) {
            return [path lastPathComponent];
        }
    }
    
    return @"";
}

- (void)increaseRecordingCount {
    NSNumber *count = [[NSUserDefaults standardUserDefaults] valueForKey:@"RecordingCount"];
    
    if (count == nil) {
        [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithInteger:1] forKey:@"RecordingCount"];
        
    } else {
        NSInteger integerCount = [count integerValue] + 1;
        [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithInteger:integerCount] forKey:@"RecordingCount"];
    }
}

- (void)decreaseRecordingCount {
    
}

- (NSInteger)getRecordingCount {
    NSNumber *count = [[NSUserDefaults standardUserDefaults] valueForKey:@"RecordingCount"];
    
    if (count == nil) {
        count = [NSNumber numberWithInteger:1];
        [[NSUserDefaults standardUserDefaults] setValue:count forKey:@"RecordingCount"];
        
    }
    
    return [count integerValue];
}

- (UIImage *)scaleAndRotateImage:(UIImage *)image withMaxSize:(int)kMaxResolution {
//    int kMaxResolution = 960; // Or whatever
    
    CGImageRef imgRef = image.CGImage;
    
    CGFloat width = CGImageGetWidth(imgRef);
    CGFloat height = CGImageGetHeight(imgRef);
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    CGRect bounds = CGRectMake(0, 0, width, height);
    if (width > kMaxResolution || height > kMaxResolution) {
        CGFloat ratio = width/height;
        if (ratio > 1) {
            bounds.size.width = kMaxResolution;
            bounds.size.height = bounds.size.width / ratio;
        }
        else {
            bounds.size.height = kMaxResolution;
            bounds.size.width = bounds.size.height * ratio;
        }
    }
    
    CGFloat scaleRatio = bounds.size.width / width;
    CGSize imageSize = CGSizeMake(CGImageGetWidth(imgRef), CGImageGetHeight(imgRef));
    CGFloat boundHeight;
    UIImageOrientation orient = image.imageOrientation;
    switch(orient) {
        case UIImageOrientationUp: //EXIF = 1
            transform = CGAffineTransformIdentity;
            break;
        case UIImageOrientationUpMirrored: //EXIF = 2
            transform = CGAffineTransformMakeTranslation(imageSize.width, 0.0);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            break;
        case UIImageOrientationDown: //EXIF = 3
            transform = CGAffineTransformMakeTranslation(imageSize.width, imageSize.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
        case UIImageOrientationDownMirrored: //EXIF = 4
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.height);
            transform = CGAffineTransformScale(transform, 1.0, -1.0);
            break;
        case UIImageOrientationLeftMirrored: //EXIF = 5
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(imageSize.height, imageSize.width);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            break;
        case UIImageOrientationLeft: //EXIF = 6
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.width);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            break;
        case UIImageOrientationRightMirrored: //EXIF = 7
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeScale(-1.0, 1.0);
            transform = CGAffineTransformRotate(transform, M_PI / 2.0);
            break;
        case UIImageOrientationRight: //EXIF = 8
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(imageSize.height, 0.0);
            transform = CGAffineTransformRotate(transform, M_PI / 2.0);
            break;
        default:
            [NSException raise:NSInternalInconsistencyException format:@"Invalid image orientation"];
    }
    
    UIGraphicsBeginImageContext(bounds.size);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    if (orient == UIImageOrientationRight || orient == UIImageOrientationLeft) {
        CGContextScaleCTM(context, -scaleRatio, scaleRatio);
        CGContextTranslateCTM(context, -height, 0);
    }
    else {
        CGContextScaleCTM(context, scaleRatio, -scaleRatio);
        CGContextTranslateCTM(context, 0, -height);
    }
    
    CGContextConcatCTM(context, transform);
    
    CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, width, height), imgRef);
    UIImage *imageCopy = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return imageCopy;
}

-(UIImage *)imageFromText:(NSString *)text {
    // set the font type and size
    UIFont *font = [UIFont systemFontOfSize:50.0];

    NSDictionary *attributes = [NSDictionary dictionaryWithObjects:
                                @[font, [UIColor lightGrayColor]]
                                                           forKeys:
                                @[NSFontAttributeName, NSForegroundColorAttributeName]];
    
    CGSize size  = [text sizeWithAttributes:attributes];
    
    UIGraphicsBeginImageContext(size);

    [text drawAtPoint:CGPointMake(0.0, 0.0) withAttributes:attributes];
    
    // transfer image
    CGContextSetShouldAntialias(UIGraphicsGetCurrentContext(), YES);
    CGContextSetAllowsAntialiasing(UIGraphicsGetCurrentContext(), YES);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

- (UIImage *)createImageFromView:(UIScrollView *)view {
    UIGraphicsBeginImageContext(view.contentSize);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

- (BOOL)validateEmailWithString:(NSString *)email {
    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:email];
}

- (NSString *)hidePhoneNumber:(NSString *)phonenumber {
    NSString *res = phonenumber;
    NSRange range;
    range.length = 2;
    range.location = res.length - 5;
    res = [res stringByReplacingCharactersInRange:range withString:@"*"];
    
    return res;
}

- (NSString *) stringByRemovingHTMLTag:(NSString *)text {
    NSRange range;
    NSString *res = text;
    
    while ((range = [res rangeOfString:@"<[^>]+>" options:NSRegularExpressionSearch]).location != NSNotFound) {
        res = [res stringByReplacingCharactersInRange:range withString:@""];
    }
    return res;
}

- (NSString *)stringByRemovingSpaceAndNewLineSymbol:(NSString *)text {
    NSString *newText = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    return newText;
}

- (void)textToSpeech:(NSString *)text withRate:(float)rate {
    AVSpeechSynthesizer *synthesizer = [[AVSpeechSynthesizer alloc]init];
    
    [synthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
    
    AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:text];

    [utterance setRate:rate];
    [synthesizer speakUtterance:utterance];
}

//streak
- (void)saveStreak:(NSTimeInterval)date {
    NSNumber *number = [NSNumber numberWithDouble:date];
    NSMutableArray *streakArr = [[NSMutableArray alloc] initWithArray:[self loadStreak]];
    
    [streakArr addObject:number];
    
    NSData* archivedData = [NSKeyedArchiver archivedDataWithRootObject:streakArr];
    
    [self saveDataToUserDefaultStandard:archivedData withKey:KEY_STREAK_INFO];
}

- (NSArray *)loadStreak {
    NSData* archivedData = [self loadDataFromUserDefaultStandardWithKey:KEY_STREAK_INFO];
    
    NSArray *streakArr = [NSKeyedUnarchiver unarchiveObjectWithData:archivedData];
    
    return streakArr;
}

- (NSInteger)getCountOfStreak {
    NSTimeInterval curDate = [self getBeginOfDayInSec];
    NSArray *streakArr = [self loadStreak];
    NSInteger count = 0;
    int nextInd = 2;
    NSTimeInterval streakDate = 0;
    
    if ([streakArr count] > 0) {
        //the last date in streak could be current date or yesterday
        streakDate = [[streakArr objectAtIndex:[streakArr count] - 1] doubleValue];
        NSTimeInterval offset = 0;
        
        if (curDate >= streakDate) {
            offset = curDate - streakDate;
            
        } else {
            offset = streakDate - curDate;
        }
        
//        if (offset == 24 * 3600 || offset == 0) {
        if (offset < SECONDS_OF_DAY + SECONDS_OF_HALFDAY) {
            count++;
            
        } else {
            if ([streakArr count] > 1) {
                streakDate = [[streakArr objectAtIndex:[streakArr count] - 2] doubleValue];
                if (curDate >= streakDate) {
                    offset = curDate - streakDate;
                    
                } else {
                    offset = streakDate - curDate;
                }
                
                if (offset < SECONDS_OF_DAY + SECONDS_OF_HALFDAY) {
                    count++;
                    nextInd = 3;
                    
                } else {
                    return count;
                }
                
            } else {
                return count;
            }
        }
        
        curDate = streakDate;
        
        for (int i = ((int)[streakArr count] - nextInd); i >=0; i--) {
            streakDate = [[streakArr objectAtIndex:i] doubleValue];
            offset = curDate - streakDate;
            
//            if (offset == 24 * 3600) {
            if (offset <= SECONDS_OF_DAY*2) {
                count++;
                
            } else {
                break;
            }
            
            curDate = streakDate;
        }
    }
    
    return count;
}

- (NSString *)fileNameToBackup {
    NSString *res = [NSString stringWithFormat:@"%@_%lu.zip", [[Common sharedCommon] loadDataFromUserDefaultStandardWithKey:KEY_BACKUP_CODE], (unsigned long)[[CommonSqlite sharedCommonSqlite] getCountOfStudiedWord]];
    
    return res;
}

@end
