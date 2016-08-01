//
//  CommonSqlite.m
//  LazzyBee
//
//  Created by HuKhong on 4/19/15.
//  Copyright (c) 2015 HuKhong. All rights reserved.
//

#import "CommonSqlite.h"
#import "UIKit/UIKit.h"
#import "sqlite3.h"
#import "CommonDefine.h"
#import "Common.h"
#import "Algorithm.h"
#import "WordObject.h"
#import "ZipArchive.h"
#import "MajorObject.h"
#import "SVProgressHUD.h"
#import "GTMHTTPFetcher.h"
#import "GTLDataServiceApi.h"
#import "LocalizeHelper.h"

@import FirebaseAnalytics;

// Singleton
static CommonSqlite* sharedCommonSqlite = nil;

@implementation CommonSqlite
{
    NSMutableArray *lostWords;
}

//-------------------------------------------------------------
// allways return the same singleton
//-------------------------------------------------------------
+ (CommonSqlite*) sharedCommonSqlite {
    // lazy instantiation
    if (sharedCommonSqlite == nil) {
        sharedCommonSqlite = [[CommonSqlite alloc] init];
    }
    return sharedCommonSqlite;
}


//-------------------------------------------------------------
// initiating
//-------------------------------------------------------------
- (id) init {
    self = [super init];
    if (self) {
        // use systems main bundle as default bundle
    }
    return self;
}


#pragma mark vocabulary
- (NSArray *)getAllWords {
    NSString *strQuery = @"SELECT id, question, answers, subcats, status, package, level, queue, due, rev_count, last_ivl, e_factor, l_vn, l_en, gid, user_note FROM \"vocabulary\"";
    
    NSString *dbPath = [self getDatabasePath];
    NSArray *resArr = [self getWordByQueryString:strQuery fromDatabase:dbPath];
    
    return resArr;
}

- (WordObject *)getWordInformation:(NSString *)word {
    NSString *strQuery = [NSString stringWithFormat: @"SELECT id, question, answers, subcats, status, package, level, queue, due, rev_count, last_ivl, e_factor, l_vn, l_en, gid, user_note FROM \"vocabulary\" WHERE question = '%@'", word];
    NSString *dbPath = [self getDatabasePath];
    NSArray *resArr = [self getWordByQueryString:strQuery fromDatabase:dbPath];
    
    return [resArr objectAtIndex:0];
}

- (NSArray *)getStudiedList {
    NSString *strQuery = [NSString stringWithFormat:@"SELECT id, question, answers, subcats, status, package, level, queue, due, rev_count, last_ivl, e_factor, l_vn, l_en, gid, user_note FROM \"vocabulary\" where queue = %d OR queue = %d ORDER BY level", QUEUE_REVIEW, QUEUE_DONE];
    
    NSString *dbPath = [self getDatabasePath];
    NSArray *resArr = [self getWordByQueryString:strQuery fromDatabase:dbPath];
    
    return resArr;
}

- (NSArray *)getNewWordsList {
    NSArray *resArr = [self fetchWordsFromVocabularyForKey:PICKEDWORD];
    
    return resArr;
}

- (NSArray *)getIncomingList {
    NSArray *resArr = [self fetchWordsFromVocabularyForKey:BUFFER];
    
    return resArr;
}

- (NSArray *)getStudyAgainListWithLimit:(NSInteger)limit {
    NSString *strQuery = @"SELECT id, question, answers, subcats, status, package, level, queue, due, rev_count, last_ivl, e_factor, l_vn, l_en, gid, user_note FROM \"vocabulary\" where queue = 1 ORDER BY level LIMIT %d";
    strQuery = [NSString stringWithFormat:strQuery, limit];
    
    NSString *dbPath = [self getDatabasePath];
    NSArray *resArr = [self getWordByQueryString:strQuery fromDatabase:dbPath];
    
    return resArr;
}

- (NSArray *)getReviewList {
    NSArray *resArr = [self getReviewListFromSystem];
    
    //if it is yesterday, get new review list from vocabulary
    //resArr could be empty after completed daily target (so can learn after have completed daily target
    if (resArr == nil || [resArr count] == 0) {
        resArr = [self getReviewListFromVocabulary];
        
        //save list to db (only word-id)
        [self createInreivewListForADay:resArr];
        
        [FIRAnalytics logEventWithName:EVENT_COUNT_REVIEW_W_PER_DAY parameters:@{
                                                                     kFIRParameterValue:@([resArr count])
                                                                     }];
        
    }
    
    return resArr;
}

- (NSArray *)getSearchHintList:(NSString *)searchText {
    NSString *strQuery = [NSString stringWithFormat:@"SELECT id, question, answers, subcats, status, package, level, queue, due, rev_count, last_ivl, e_factor, l_vn, l_en, gid, user_note FROM \"vocabulary\" where question like '%@%%' OR question like '%% %@%%' ORDER BY level", searchText, searchText];
    
    NSString *dbPath = [self getDatabasePath];
    NSArray *resArr = [self getWordByQueryString:strQuery fromDatabase:dbPath];
    
    return resArr;
}

- (NSArray *)getSearchResultList:(NSString *)searchText {
    NSString *strQuery = [NSString stringWithFormat:@"SELECT id, question, answers, subcats, status, package, level, queue, due, rev_count, last_ivl, e_factor, l_vn, l_en, gid, user_note FROM \"vocabulary\" where question like '%@%%' OR question like '%% %@%%'  ORDER BY level", searchText, searchText];
    
    NSString *dbPath = [self getDatabasePath];
    NSArray *resArr = [self getWordByQueryString:strQuery fromDatabase:dbPath];
    
    return resArr;
}

//selected fields in the query string must be ordered as: id, question, answers, subcats, status, package, level, queue, due, rev_count, last_ivl, e_factor
- (NSArray *)getWordByQueryString:(NSString *)strQuery fromDatabase:(NSString *)dbPath {
    NSURL *storeURL = [NSURL URLWithString:dbPath];
    
    const char *dbFilePathUTF8 = [[storeURL path] UTF8String];
    sqlite3 *db;
    int dbrc; //database return code
    dbrc = sqlite3_open(dbFilePathUTF8, &db);
    
    if (dbrc) {
        return nil;
    }
    sqlite3_stmt *dbps;

    const char *charQuery = [strQuery UTF8String];
    
    sqlite3_prepare_v2(db, charQuery, -1, &dbps, NULL);
    
    NSMutableArray *resArr = [[NSMutableArray alloc] init];
    
//    NSMutableDictionary *log = [[NSMutableDictionary alloc] init];//for test
    while(sqlite3_step(dbps) == SQLITE_ROW) {
        WordObject *wordObj = [[WordObject alloc] init];
        
        //id, question, answers, subcats, status, package, level, queue, due, revCount, lastInterval, eFactor, l_vn, l_en
        if (sqlite3_column_text(dbps, 0)) {
            wordObj.wordid = [NSString stringWithUTF8String:(char *)sqlite3_column_text(dbps, 0)];
        }
        
        if (sqlite3_column_text(dbps, 1)) {
            wordObj.question = [NSString stringWithUTF8String:(char *)sqlite3_column_text(dbps, 1)];
        }
        
        if (sqlite3_column_text(dbps, 2)) {
            wordObj.answers = [NSString stringWithUTF8String:(char *)sqlite3_column_text(dbps, 2)];
        }
        
        if (sqlite3_column_text(dbps, 3)) {
            wordObj.subcats = [NSString stringWithUTF8String:(char *)sqlite3_column_text(dbps, 3)];
        }
        
        if (sqlite3_column_text(dbps, 4)) {
            wordObj.status = [NSString stringWithUTF8String:(char *)sqlite3_column_text(dbps, 4)];
        }
        
        if (sqlite3_column_text(dbps, 5)) {
            wordObj.package = [NSString stringWithUTF8String:(char *)sqlite3_column_text(dbps, 5)];
        }
        
        if (sqlite3_column_text(dbps, 6)) {
            wordObj.level = [NSString stringWithUTF8String:(char *)sqlite3_column_text(dbps, 6)];
        }
        
        if (sqlite3_column_text(dbps, 7)) {
            wordObj.queue = [NSString stringWithUTF8String:(char *)sqlite3_column_text(dbps, 7)];
        }
        
        if (sqlite3_column_text(dbps, 8)) {
            wordObj.due = [NSString stringWithUTF8String:(char *)sqlite3_column_text(dbps, 8)];
        }
        
        if (sqlite3_column_text(dbps, 9)) {
            wordObj.revCount = [NSString stringWithUTF8String:(char *)sqlite3_column_text(dbps, 9)];
        }
        
        if (sqlite3_column_text(dbps, 10)) {
            wordObj.lastInterval = [NSString stringWithUTF8String:(char *)sqlite3_column_text(dbps, 10)];
        }
        
        if (sqlite3_column_text(dbps, 11)) {
            wordObj.eFactor = [NSString stringWithUTF8String:(char *)sqlite3_column_text(dbps, 11)];
        }
        
        if (sqlite3_column_text(dbps, 12)) {
            wordObj.langVN = [NSString stringWithUTF8String:(char *)sqlite3_column_text(dbps, 12)];
        }
        
        if (sqlite3_column_text(dbps, 13)) {
            wordObj.langEN = [NSString stringWithUTF8String:(char *)sqlite3_column_text(dbps, 13)];
        }
        
        if (sqlite3_column_text(dbps, 14)) {
            wordObj.gid = [NSString stringWithUTF8String:(char *)sqlite3_column_text(dbps, 14)];
        }
        
        if (sqlite3_column_text(dbps, 15)) {
            wordObj.userNote = [NSString stringWithUTF8String:(char *)sqlite3_column_text(dbps, 15)];
        }
        
        [resArr addObject:wordObj];
        
        /* for test :: check empty content - begin */
/*        NSData *data = [wordObj.answers dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *dictAnswer = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        NSString *strPronounciation = [dictAnswer valueForKey:@"pronoun"];
        
        //A word may has many meanings corresponding to many fields (common, it, economic...)
        //The meaning of each field is considered as a package
        NSDictionary *dictPackages = [dictAnswer valueForKey:@"packages"];
        NSDictionary *dictSinglePackage = [dictPackages valueForKey:@"common"];
        //"common":{"meaning":"", "explain":"<p>The edge of something is the part of it that is farthest from the center.</p>", "example":"<p>He ran to the edge of the cliff.</p>"}}
        
        NSString *strExplanation = [dictSinglePackage valueForKey:@"explain"];
        NSString *strExample = [dictSinglePackage valueForKey:@"example"];
        NSMutableDictionary *item = [[NSMutableDictionary alloc] init];
        BOOL found = NO;
        
        if (strPronounciation == nil || strPronounciation.length == 0) {
            [item setValue:@"pronounce" forKey:@"pronounce"];
            found = YES;
        }
        
        if (strExplanation == nil || strExplanation.length == 0) {
            [item setValue:@"explain" forKey:@"explain"];
            found = YES;
        }
        
        if (strExample == nil || strExample.length == 0) {
            [item setValue:@"example" forKey:@"example"];
            found = YES;
        }
        
        if (wordObj.langEN == nil || wordObj.langEN.length == 0) {
            [item setValue:@"langEN" forKey:@"langEN"];
            found = YES;
        }
        
        if (wordObj.langVN == nil || wordObj.langVN.length == 0) {
            [item setValue:@"langVN" forKey:@"langVN"];
            found = YES;
        }
        
        if (found == YES) {
            [log setObject:item forKey:wordObj.question];
        }*/
        /* for test - end */
    }
    
    sqlite3_finalize(dbps);
    sqlite3_close(db);
    
    return resArr;
}

- (void)updateWord:(WordObject *)wordObj {
    NSString *dbPath = [self getDatabasePath];
    NSURL *storeURL = [NSURL URLWithString:dbPath];
    
    const char *dbFilePathUTF8 = [[storeURL path] UTF8String];
    sqlite3 *db;
    int dbrc; //database return code
    dbrc = sqlite3_open(dbFilePathUTF8, &db);
    
    if (dbrc) {
        return;
    }
    sqlite3_stmt *dbps;
    /**
     @property (nonatomic, strong) NSString *wordid;
     @property (nonatomic, strong) NSString *question;
     @property (nonatomic, strong) NSString *answers;
     @property (nonatomic, strong) NSString *subcats;
     @property (nonatomic, strong) NSString *status;
     @property (nonatomic, strong) NSString *package;
     @property (nonatomic, strong) NSString *level;
     @property (nonatomic, strong) NSString *queue;
     @property (nonatomic, strong) NSString *due;
     @property (nonatomic, strong) NSString *revCount;
     @property (nonatomic, strong) NSString *lastInterval;
     @property (nonatomic, strong) NSString *eFactor;
     id, question, answers, subcats, status, package, level, queue, due, rev_count, last_ivl, e_factor
     */
    NSString *formattedAnswer = [wordObj.answers stringByReplacingOccurrencesOfString:@"\'" withString:@"\'\'"];
    NSString *formattedVN = [wordObj.langVN stringByReplacingOccurrencesOfString:@"\'" withString:@"\'\'"];
    NSString *formattedEN = [wordObj.langEN stringByReplacingOccurrencesOfString:@"\'" withString:@"\'\'"];
    
    NSString *strQuery = [NSString stringWithFormat:@"UPDATE \"vocabulary\" SET queue = %d, due = %d, rev_count = %d, last_ivl = %d, e_factor = %d, answers = \'%@\', l_vn = \'%@\', l_en = \'%@\' where question = \'%@\'", [wordObj.queue intValue], [wordObj.due intValue], [wordObj.revCount intValue], [wordObj.lastInterval intValue], [wordObj.eFactor intValue], formattedAnswer, formattedVN, formattedEN, wordObj.question];
    const char *charQuery = [strQuery UTF8String];
    
    sqlite3_prepare_v2(db, charQuery, -1, &dbps, NULL);
    
    if(SQLITE_DONE != sqlite3_step(dbps)) {
        NSLog(@"Error while updating. %s", sqlite3_errmsg(db));
    }
    
    sqlite3_finalize(dbps);
    sqlite3_close(db);

}

- (void)saveNoteForWord:(WordObject *)wordObj withNewNote:(NSString *)note {
    NSString *dbPath = [self getDatabasePath];
    NSURL *storeURL = [NSURL URLWithString:dbPath];
    
    const char *dbFilePathUTF8 = [[storeURL path] UTF8String];
    sqlite3 *db;
    int dbrc; //database return code
    dbrc = sqlite3_open(dbFilePathUTF8, &db);
    
    if (dbrc) {
        return;
    }
    sqlite3_stmt *dbps;
    
    NSString *formattedNote = [note stringByReplacingOccurrencesOfString:@"\'" withString:@"\'\'"];
    
    NSString *strQuery = [NSString stringWithFormat:@"UPDATE \"vocabulary\" SET user_note = \'%@\' where question = \'%@\'", formattedNote, wordObj.question];
    const char *charQuery = [strQuery UTF8String];
    
    sqlite3_prepare_v2(db, charQuery, -1, &dbps, NULL);
    
    if(SQLITE_DONE != sqlite3_step(dbps)) {
        NSLog(@"Error while updating. %s", sqlite3_errmsg(db));
    }
    
    sqlite3_finalize(dbps);
    sqlite3_close(db);
    
}

- (void)insertWordToDatabase:(WordObject *)wordObj {
    NSString *dbPath = [self getDatabasePath];
    NSURL *storeURL = [NSURL URLWithString:dbPath];
    
    const char *dbFilePathUTF8 = [[storeURL path] UTF8String];
    sqlite3 *db;
    int dbrc; //database return code
    dbrc = sqlite3_open(dbFilePathUTF8, &db);
    
    if (dbrc) {
        return;
    }
    sqlite3_stmt *dbps;

    NSString *strQuery = [NSString stringWithFormat:@"SELECT COUNT(*) FROM 'vocabulary' WHERE gid = %@", wordObj.gid];
    const char *charQuery = [strQuery UTF8String];
    NSInteger count = 0;
    
    sqlite3_prepare_v2(db, charQuery, -1, &dbps, NULL);
    
    if(SQLITE_DONE != sqlite3_step(dbps)) {
        if (sqlite3_column_int(dbps, 0)) {
            count = sqlite3_column_int(dbps, 0);
        }
    }
    sqlite3_finalize(dbps);
    
    NSString *formattedAnswer = [wordObj.answers stringByReplacingOccurrencesOfString:@"\'" withString:@"\'\'"];
    NSString *formattedVN = [wordObj.langVN stringByReplacingOccurrencesOfString:@"\'" withString:@"\'\'"];
    NSString *formattedEN = [wordObj.langEN stringByReplacingOccurrencesOfString:@"\'" withString:@"\'\'"];
    
    if (count == 0) {
        
        strQuery = @"INSERT INTO 'vocabulary' (question, answers, subcats, status, package, level, queue, due, rev_count, last_ivl, e_factor, l_vn, l_en, gid) VALUES ('%@', '%@', '%@', '%@', '%@', '%@', '%@', '%@', '%@', '%@', '%@', '%@', '%@', '%@')";
        strQuery = [NSString stringWithFormat:strQuery, wordObj.question, formattedAnswer, wordObj.subcats, wordObj.status, wordObj.package, wordObj.level, wordObj.queue, wordObj.due, wordObj.revCount, wordObj.lastInterval, wordObj.eFactor, formattedVN, formattedEN, wordObj.gid];
        
        charQuery = [strQuery UTF8String];
        
        sqlite3_prepare_v2(db, charQuery, -1, &dbps, NULL);
        
        if(SQLITE_DONE != sqlite3_step(dbps)) {
            NSLog(@"Error while inserting. %s", sqlite3_errmsg(db));
        }
        
    } else {
        strQuery = [NSString stringWithFormat:@"UPDATE \"vocabulary\" SET queue = %d, due = %d, rev_count = %d, last_ivl = %d, e_factor = %d, answers = \'%@\', l_vn = \'%@\', l_en = \'%@\' where question = \'%@\'", [wordObj.queue intValue], [wordObj.due intValue], [wordObj.revCount intValue], [wordObj.lastInterval intValue], [wordObj.eFactor intValue], formattedAnswer, formattedVN, formattedEN, wordObj.question];
        const char *charQuery = [strQuery UTF8String];
        
        sqlite3_prepare_v2(db, charQuery, -1, &dbps, NULL);
        
        if(SQLITE_DONE != sqlite3_step(dbps)) {
            NSLog(@"Error while updating. %s", sqlite3_errmsg(db));
        }
    }
    
    sqlite3_finalize(dbps);
    sqlite3_close(db);
    
}

- (NSTimeInterval)getEndOfDayInSec {
    NSTimeInterval datetime = [[Common sharedCommon] getBeginOfDayInSec];
    
    datetime = datetime + 24*3600;
    
    return datetime;
}

- (NSArray *)getReviewListFromVocabulary {
    NSString *strQuery = [NSString stringWithFormat:@"SELECT id, question, answers, subcats, status, package, level, queue, due, rev_count, last_ivl, e_factor, l_vn, l_en, gid, user_note FROM \"vocabulary\" where queue = %d AND due <= %f ORDER BY level LIMIT %ld", QUEUE_REVIEW, [self getEndOfDayInSec], (long)TOTAL_WORDS_A_DAY_MAX];
    
    NSString *dbPath = [self getDatabasePath];
    NSArray *resArr = [self getWordByQueryString:strQuery fromDatabase:dbPath];
    
    return resArr;
}

- (NSInteger)getCountOfStudyAgain {
    NSString *dbPath = [self getDatabasePath];
    NSURL *storeURL = [NSURL URLWithString:dbPath];
    
    const char *dbFilePathUTF8 = [[storeURL path] UTF8String];
    sqlite3 *db;
    int dbrc; //database return code
    dbrc = sqlite3_open(dbFilePathUTF8, &db);
    
    if (dbrc) {
        return 0;
    }
    sqlite3_stmt *dbps;

    NSString *strQuery = @"SELECT COUNT(*) FROM \"vocabulary\" where queue = 1";
    const char *charQuery = [strQuery UTF8String];
    NSInteger count = 0;
    
    sqlite3_prepare_v2(db, charQuery, -1, &dbps, NULL);
    
    if(SQLITE_DONE != sqlite3_step(dbps)) {
        if (sqlite3_column_int(dbps, 0)) {
            count = sqlite3_column_int(dbps, 0);
        }
    }
    
    sqlite3_finalize(dbps);
    sqlite3_close(db);
    
    return count;
}

- (NSInteger)getCountOfStudiedWord {
    NSString *dbPath = [self getDatabasePath];
    NSURL *storeURL = [NSURL URLWithString:dbPath];
    
    const char *dbFilePathUTF8 = [[storeURL path] UTF8String];
    sqlite3 *db;
    int dbrc; //database return code
    dbrc = sqlite3_open(dbFilePathUTF8, &db);
    
    if (dbrc) {
        return 0;
    }
    sqlite3_stmt *dbps;
    
    NSString *strQuery = [NSString stringWithFormat:@"SELECT COUNT(*) FROM \"vocabulary\" where queue = %d OR queue = %d", QUEUE_REVIEW, QUEUE_DONE];
    const char *charQuery = [strQuery UTF8String];
    NSInteger count = 0;
    
    sqlite3_prepare_v2(db, charQuery, -1, &dbps, NULL);
    
    if(SQLITE_DONE != sqlite3_step(dbps)) {
        if (sqlite3_column_int(dbps, 0)) {
            count = sqlite3_column_int(dbps, 0);
        }
    }
    
    sqlite3_finalize(dbps);
    sqlite3_close(db);
    
    return count;
}

- (BOOL)updateDatabaseWithPath:(NSString *)dbPath {
    NSURL *storeURL = [NSURL URLWithString:dbPath];
    
    NSData *urlData = [NSData dataWithContentsOfURL:storeURL];
    NSString *dbPathNew = [self getNewDatabasePath];
    
    //remove the existing file
    [[Common sharedCommon] trashFileAtPathAndEmpptyTrash:dbPathNew];
    
    if (urlData) {
        [urlData writeToFile:dbPathNew atomically:YES];
        
    } else {
        return NO;
    }

    NSString *strQuery = @"SELECT id, question, answers, subcats, status, package, level, queue, due, rev_count, last_ivl, e_factor, l_vn, l_en, gid FROM \"vocabulary\" ORDER BY level";
    
    NSArray *newWordsArr = [self getWordByQueryString:strQuery fromDatabase:dbPathNew];
    
    NSLog(@"count :: %lu", (unsigned long)[newWordsArr  count]);
    
    //remove the new file after reading
    [[Common sharedCommon] trashFileAtPathAndEmpptyTrash:dbPathNew];
    
    //update old db
    NSString *dbPathOld = [self getDatabasePath];
    NSArray *oldWordsArr = [self getWordByQueryString:strQuery fromDatabase:dbPathOld];
    NSMutableDictionary *oldWordsDictionary = [[NSMutableDictionary alloc] init];   //improve search words
    for (WordObject *oldWord in oldWordsArr) {
        [oldWordsDictionary setValue:oldWord.answers forKey:oldWord.question];
    }
    
    storeURL = [NSURL URLWithString:dbPathOld];
    
    const char *dbFilePathUTF8 = [[storeURL path] UTF8String];
    sqlite3 *db;
    int dbrc; //database return code
    dbrc = sqlite3_open(dbFilePathUTF8, &db);
    
    if (dbrc) {
        return NO;
    }
    sqlite3_stmt *dbps;
    NSString *formattedAnswer = @"";
    NSString *formattedVN = @"";
    NSString *formattedEN = @"";
    const char *charQuery = nil;
    BOOL updateFlag = NO;
    
    for (WordObject *newWord in newWordsArr) {
        updateFlag = NO;
        for (WordObject *oldWord in oldWordsArr) {
            if ([oldWord.question isEqualToString:newWord.question]) {
                if (![oldWord.answers isEqualToString:newWord.answers] ||
                    ![oldWord.level isEqualToString:newWord.level] ||
                    ![oldWord.package isEqualToString:newWord.package] ||
                    ![oldWord.langVN isEqualToString:newWord.langVN] ||
                    ![oldWord.langEN isEqualToString:newWord.langEN]) {
                    
                    updateFlag = YES;
                }
                break;
            }
        }
        
        if (updateFlag == YES) {
            formattedAnswer = [newWord.answers stringByReplacingOccurrencesOfString:@"\'" withString:@"\'\'"];
            formattedVN = [newWord.langVN stringByReplacingOccurrencesOfString:@"\'" withString:@"\'\'"];
            formattedEN = [newWord.langEN stringByReplacingOccurrencesOfString:@"\'" withString:@"\'\'"];
            
            strQuery = [NSString stringWithFormat:@"UPDATE 'vocabulary' SET answers = '%@', level = '%@', package = '%@', l_vn = '%@', l_en = '%@' where question = '%@'", formattedAnswer, newWord.level, newWord.package, formattedVN, formattedEN, newWord.question];
            
            charQuery = [strQuery UTF8String];
            
            sqlite3_prepare_v2(db, charQuery, -1, &dbps, NULL);
            
            if(SQLITE_DONE != sqlite3_step(dbps)) {
                NSLog(@"Error while updating. %s", sqlite3_errmsg(db));
            }
            
            sqlite3_finalize(dbps);
        }
    }
    
    //insert new word
    for (WordObject *newWord in newWordsArr) {
        
        if (![oldWordsDictionary valueForKey:newWord.question]) {
            formattedAnswer = [newWord.answers stringByReplacingOccurrencesOfString:@"\'" withString:@"\'\'"];
            formattedVN = [newWord.langVN stringByReplacingOccurrencesOfString:@"\'" withString:@"\'\'"];
            formattedEN = [newWord.langEN stringByReplacingOccurrencesOfString:@"\'" withString:@"\'\'"];
            
            strQuery = @"INSERT INTO 'vocabulary' (question, answers, subcats, status, package, level, queue, due, rev_count, last_ivl, e_factor, l_vn, l_en, gid) VALUES ('%@', '%@', '%@', '%@', '%@', '%@', '%@', '%@', '%@', '%@', '%@', '%@', '%@', '%@')";
            strQuery = [NSString stringWithFormat:strQuery, newWord.question, formattedAnswer, newWord.subcats, newWord.status, newWord.package, newWord.level, newWord.queue, newWord.due, newWord.revCount, newWord.lastInterval, newWord.eFactor, formattedVN, formattedEN, newWord.gid];
            
            charQuery = [strQuery UTF8String];
            
            sqlite3_prepare_v2(db, charQuery, -1, &dbps, NULL);
            
            if(SQLITE_DONE != sqlite3_step(dbps)) {
                NSLog(@"Error while inserting. %s", sqlite3_errmsg(db));
            }
            
            sqlite3_finalize(dbps);
        }
    }
    
    sqlite3_close(db);
    
    return YES;
}

- (void)addMoreFieldToTable {
    NSString *dbPath = [self getDatabasePath];
    NSURL *storeURL = [NSURL URLWithString:dbPath];
    
    const char *dbFilePathUTF8 = [[storeURL path] UTF8String];
    sqlite3 *db;
    int dbrc; //database return code
    dbrc = sqlite3_open(dbFilePathUTF8, &db);
    
    if (dbrc) {
        return;
    }
    sqlite3_stmt *dbps;
    
    NSString *strQuery = @"ALTER TABLE 'vocabulary' ADD COLUMN l_vn TEXT";
    const char *charQuery = [strQuery UTF8String];
    
    sqlite3_prepare_v2(db, charQuery, -1, &dbps, NULL);
    if(SQLITE_DONE != sqlite3_step(dbps)) {
        NSLog(@"Error while altering table: %s", sqlite3_errmsg(db));
    }
    
    sqlite3_finalize(dbps);
    
    strQuery = @"ALTER TABLE 'vocabulary' ADD COLUMN l_en TEXT";
    charQuery = [strQuery UTF8String];
    
    sqlite3_prepare_v2(db, charQuery, -1, &dbps, NULL);
    if(SQLITE_DONE != sqlite3_step(dbps)) {
        NSLog(@"Error while altering table: %s", sqlite3_errmsg(db));
    }
    
    sqlite3_finalize(dbps);
    
    strQuery = @"ALTER TABLE 'vocabulary' ADD COLUMN priority INTEGER";
    charQuery = [strQuery UTF8String];
    
    sqlite3_prepare_v2(db, charQuery, -1, &dbps, NULL);
    if(SQLITE_DONE != sqlite3_step(dbps)) {
        NSLog(@"Error while altering table: %s", sqlite3_errmsg(db));
    }
    
    sqlite3_finalize(dbps);
    
    sqlite3_close(db);
}


#pragma mark system table
- (NSArray *)getReviewListFromSystem {
    NSMutableArray *resArr = [[NSMutableArray alloc] init];
    
    NSString *dbPath = [self getDatabasePath];
    NSURL *storeURL = [NSURL URLWithString:dbPath];
    
    const char *dbFilePathUTF8 = [[storeURL path] UTF8String];
    sqlite3 *db;
    int dbrc; //database return code
    dbrc = sqlite3_open(dbFilePathUTF8, &db);
    
    if (dbrc) {
        return nil;
    }
    sqlite3_stmt *dbps;
    
    //check date before add new words to pickedword
    NSString *strQuery = @"SELECT value from \"system\" WHERE key = 'inreview'";
    
    const char *charQuery = [strQuery UTF8String];
    
    sqlite3_prepare_v2(db, charQuery, -1, &dbps, NULL);
    NSString *strJson = @"";
    
    while(sqlite3_step(dbps) == SQLITE_ROW) {
        if (sqlite3_column_text(dbps, 0)) {
            strJson = [NSString stringWithUTF8String:(char *)sqlite3_column_text(dbps, 0)];
        }
    }
    
    sqlite3_finalize(dbps);
    
    //insert inreview key if it doesnt not exist
    if ([strJson isEqualToString:@""]) {
        strQuery = @"INSERT INTO \"system\" (key, value) VALUES ('inreview', '')";
        charQuery = [strQuery UTF8String];
        
        sqlite3_prepare_v2(db, charQuery, -1, &dbps, NULL);
        
        if(SQLITE_DONE != sqlite3_step(dbps)) {
            NSLog(@"Error while inserting: %s", sqlite3_errmsg(db));
        }
        
        sqlite3_finalize(dbps);
    }
    
    //parse the result to get date
    NSMutableArray *idListArr = [[NSMutableArray alloc] init];
    NSString *strIDList = @"";
    NSTimeInterval oldDate = 0;
    NSData *data = [strJson dataUsingEncoding:NSUTF8StringEncoding];
    if (data) {
        NSDictionary *dictIDList = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        oldDate = [[dictIDList valueForKey:@"date"] doubleValue];
        
        [idListArr addObjectsFromArray:[dictIDList valueForKey:@"card"]];
        
        if (idListArr) {
            strIDList = [[Common sharedCommon] stringByRemovingSpaceAndNewLineSymbol:[idListArr description]];
        }
    }
    
    //compare current date
    NSTimeInterval curDate = [[Common sharedCommon] getBeginOfDayInSec];   //just get time at the begin of day
    
    if (oldDate == curDate) {     //get if it is new. If review list is old, get review list from vocabulary table
        //get word object  from vocabulary with id from system
        strQuery = [NSString stringWithFormat:@"SELECT id, question, answers, subcats, status, package, level, queue, due, rev_count, last_ivl, e_factor, l_vn, l_en, gid, user_note from \"vocabulary\" WHERE id IN %@", strIDList];
        charQuery = [strQuery UTF8String];
        
        sqlite3_prepare_v2(db, charQuery, -1, &dbps, NULL);
        
        while(sqlite3_step(dbps) == SQLITE_ROW) {
            WordObject *wordObj = [[WordObject alloc] init];
            
            if (sqlite3_column_text(dbps, 0)) {
                wordObj.wordid = [NSString stringWithUTF8String:(char *)sqlite3_column_text(dbps, 0)];
            }
            
            if (sqlite3_column_text(dbps, 1)) {
                wordObj.question = [NSString stringWithUTF8String:(char *)sqlite3_column_text(dbps, 1)];
            }
            
            if (sqlite3_column_text(dbps, 2)) {
                wordObj.answers = [NSString stringWithUTF8String:(char *)sqlite3_column_text(dbps, 2)];
            }
            
            if (sqlite3_column_text(dbps, 3)) {
                wordObj.subcats = [NSString stringWithUTF8String:(char *)sqlite3_column_text(dbps, 3)];
            }
            
            if (sqlite3_column_text(dbps, 4)) {
                wordObj.status = [NSString stringWithUTF8String:(char *)sqlite3_column_text(dbps, 4)];
            }
            
            if (sqlite3_column_text(dbps, 5)) {
                wordObj.package = [NSString stringWithUTF8String:(char *)sqlite3_column_text(dbps, 5)];
            }
            
            if (sqlite3_column_text(dbps, 6)) {
                wordObj.level = [NSString stringWithUTF8String:(char *)sqlite3_column_text(dbps, 6)];
            }
            
            if (sqlite3_column_text(dbps, 7)) {
                wordObj.queue = [NSString stringWithUTF8String:(char *)sqlite3_column_text(dbps, 7)];
            }
            
            if (sqlite3_column_text(dbps, 8)) {
                wordObj.due = [NSString stringWithUTF8String:(char *)sqlite3_column_text(dbps, 8)];
            }
            
            if (sqlite3_column_text(dbps, 9)) {
                wordObj.revCount = [NSString stringWithUTF8String:(char *)sqlite3_column_text(dbps, 9)];
            }
            
            if (sqlite3_column_text(dbps, 10)) {
                wordObj.lastInterval = [NSString stringWithUTF8String:(char *)sqlite3_column_text(dbps, 10)];
            }
            
            if (sqlite3_column_text(dbps, 11)) {
                wordObj.eFactor = [NSString stringWithUTF8String:(char *)sqlite3_column_text(dbps, 11)];
            }
            
            if (sqlite3_column_text(dbps, 12)) {
                wordObj.langVN = [NSString stringWithUTF8String:(char *)sqlite3_column_text(dbps, 12)];
            }
            
            if (sqlite3_column_text(dbps, 13)) {
                wordObj.langEN = [NSString stringWithUTF8String:(char *)sqlite3_column_text(dbps, 13)];
            }
            
            if (sqlite3_column_text(dbps, 14)) {
                wordObj.gid = [NSString stringWithUTF8String:(char *)sqlite3_column_text(dbps, 14)];
            }
            
            if (sqlite3_column_text(dbps, 15)) {
                wordObj.userNote = [NSString stringWithUTF8String:(char *)sqlite3_column_text(dbps, 15)];
            }
            
            [resArr addObject:wordObj];
        }
        
        sqlite3_finalize(dbps);
    }
    
    sqlite3_close(db);
    
    return resArr;
}

//pick up "amount" news word-ids from vocabulary, then add to buffer
- (void)prepareWordsToStudyingQueue:(NSInteger)amount inPackage:(NSString *)package {
    //get current words list from system table
    NSString *dbPath = [self getDatabasePath];
    NSURL *storeURL = [NSURL URLWithString:dbPath];
    
    const char *dbFilePathUTF8 = [[storeURL path] UTF8String];
    sqlite3 *db;
    int dbrc; //database return code
    dbrc = sqlite3_open(dbFilePathUTF8, &db);

    if (dbrc) {
        return;
    }
    sqlite3_stmt *dbps;
    
    NSString *strQuery = @"";
    const char *charQuery = nil;

    //pick up "amount" news word-ids from vocabulary that not included the old words
    NSMutableArray *resArr = [[NSMutableArray alloc] init];
    
    NSString *lowestLevel = [[Common sharedCommon] loadDataFromUserDefaultStandardWithKey:KEY_LOWEST_LEVEL];
    NSString *igniredLevel = @"7";
    
    if (![package isEqualToString:@"common"]) {
        igniredLevel = @"0";
    }
    
    strQuery = [NSString stringWithFormat:@"SELECT id from \"vocabulary\" WHERE package LIKE '%%,%@,%%' AND queue = %d AND level >= %@ AND level <> %@ ORDER BY level LIMIT %ld", package, QUEUE_UNKNOWN, lowestLevel, igniredLevel, (long)amount];
    charQuery = [strQuery UTF8String];
    
    sqlite3_prepare_v2(db, charQuery, -1, &dbps, NULL);
    
    while(sqlite3_step(dbps) == SQLITE_ROW) {
        if (sqlite3_column_text(dbps, 0)) {
            NSString *wordID = [NSString stringWithUTF8String:(char *)sqlite3_column_text(dbps, 0)];
            
            [resArr addObject:wordID];
        }
    }
    
    sqlite3_finalize(dbps);

    //if the selected package is not enough, get more from common
    if ([resArr count] < amount) {
        strQuery = [NSString stringWithFormat:@"SELECT id from \"vocabulary\" WHERE package LIKE '%%,%@,%%' AND package NOT LIKE '%%,%@,%%' AND queue = %d AND level >= %@ AND level <> %@ ORDER BY level LIMIT %ld", @"common", package, QUEUE_UNKNOWN, lowestLevel, igniredLevel, (long)(amount - [resArr count])];
        charQuery = [strQuery UTF8String];
        
        sqlite3_prepare_v2(db, charQuery, -1, &dbps, NULL);
        
        while(sqlite3_step(dbps) == SQLITE_ROW) {
            if (sqlite3_column_text(dbps, 0)) {
                NSString *wordID = [NSString stringWithUTF8String:(char *)sqlite3_column_text(dbps, 0)];
                
                [resArr addObject:wordID];
            }
        }
        
        sqlite3_finalize(dbps);
    }
    
    //if there is no word with queue = QUEUE_UNKNOWN, reset all words with queue = NEW_WORD to UNKNOWN
    if ([resArr count] < amount) {
        strQuery = [NSString stringWithFormat:@"UPDATE \"vocabulary\" SET queue = %d where queue = %d", QUEUE_UNKNOWN, QUEUE_NEW_WORD];
        const char *charQuery = [strQuery UTF8String];
        
        sqlite3_prepare_v2(db, charQuery, -1, &dbps, NULL);
        
        if(SQLITE_DONE != sqlite3_step(dbps)) {
            NSLog(@"Error while updating. %s", sqlite3_errmsg(db));
        }
        
        sqlite3_finalize(dbps);
    }
    
    //create json to re-add to db
    NSMutableDictionary *dictNewWords = [[NSMutableDictionary alloc] init];
    [dictNewWords setObject:[[NSNumber alloc] initWithInteger:[resArr count]] forKey:@"count"];
    [dictNewWords setObject:resArr forKey:@"card"];
    
    //convert to json string
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dictNewWords
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&error];
    
    NSString *strJson = @"";
    if (!jsonData) {
        NSLog(@"Got an error: %@", error);
    } else {
        strJson = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    
    //update new buffer to db
    strQuery = [NSString stringWithFormat:@"UPDATE \"system\" SET value = \'%@\' where key = 'buffer'", strJson];
    
    charQuery = [strQuery UTF8String];
    
    sqlite3_prepare_v2(db, charQuery, -1, &dbps, NULL);
    
    if(SQLITE_DONE != sqlite3_step(dbps)) {
        NSLog(@"Error while updating. %s", sqlite3_errmsg(db));
    }
    
    sqlite3_finalize(dbps);
    sqlite3_close(db);
}

//pick up "amount" word-ids from buffer, then add to pickedword (this list is to study)
//forceFlag: YES: dont need to check date
- (void)pickUpRandom10WordsToStudyingQueue:(NSInteger)amount withForceFlag:(BOOL)force {
    NSString *dbPath = [self getDatabasePath];
    NSURL *storeURL = [NSURL URLWithString:dbPath];
    
    const char *dbFilePathUTF8 = [[storeURL path] UTF8String];
    sqlite3 *db;
    int dbrc; //database return code
    dbrc = sqlite3_open(dbFilePathUTF8, &db);
    
    if (dbrc) {
        return;
    }
    sqlite3_stmt *dbps;
    
    //check date before add new words to pickedword
    NSString *strQuery = @"SELECT value from \"system\" WHERE key = 'pickedword'";
    
    const char *charQuery = [strQuery UTF8String];
    
    sqlite3_prepare_v2(db, charQuery, -1, &dbps, NULL);
    NSString *strJson = @"";
    
    while(sqlite3_step(dbps) == SQLITE_ROW) {
        if (sqlite3_column_text(dbps, 0)) {
            strJson = [NSString stringWithUTF8String:(char *)sqlite3_column_text(dbps, 0)];
            //{"count":37,"card":["67","5","27","29","39","46","58","4","21","43","81","139","165","175","180","262","269","277","279","334","359","387","2","7","8","10","11","13","14","19","31","35","38","42","44","47","49"]}
            
        }
    }
    
    sqlite3_finalize(dbps);
    
    //parse the result to get date
    NSTimeInterval oldDate = 0;
    NSData *data = [strJson dataUsingEncoding:NSUTF8StringEncoding];
    if (data) {
        NSDictionary *dictIDList = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        oldDate = [[dictIDList valueForKey:@"date"] doubleValue];
    }
    
    //compare current date
    NSTimeInterval curDate = [[Common sharedCommon] getBeginOfDayInSec];   //just get time at the begin of day
    
    if (force == YES || (oldDate == 0 || curDate != oldDate)) {
        //reset flag if it's new day
        if ((oldDate == 0 || curDate != oldDate)) {
            [[Common sharedCommon] saveDataToUserDefaultStandard:[NSNumber numberWithBool:NO] withKey:KEY_COMPLETED_FLAG];
        }
        
        //get random 10 words in buffer from system table
        strQuery = @"SELECT value from \"system\" WHERE key = 'buffer'";
        
        charQuery = [strQuery UTF8String];
        
        sqlite3_prepare_v2(db, charQuery, -1, &dbps, NULL);
        strJson = @"";
        
        while(sqlite3_step(dbps) == SQLITE_ROW) {
            if (sqlite3_column_text(dbps, 0)) {
                strJson = [NSString stringWithUTF8String:(char *)sqlite3_column_text(dbps, 0)];
                //{"count":37,"card":["67","5","27","29","39","46","58","4","21","43","81","139","165","175","180","262","269","277","279","334","359","387","2","7","8","10","11","13","14","19","31","35","38","42","44","47","49"]}
                
            }
        }
        
        sqlite3_finalize(dbps);
        
        //parse the result to get word-id list
        NSMutableArray *idListArr = [[NSMutableArray alloc] init];
        data = [strJson dataUsingEncoding:NSUTF8StringEncoding];
        if (data) {
            NSDictionary *dictIDList = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            [idListArr addObjectsFromArray:[dictIDList valueForKey:@"card"]];

        }
        
//        NSUInteger randomIndex = 0;
        NSMutableArray *pickedIDArr = [[NSMutableArray alloc] init];
        int count = 0; //to prevent infinite loop
        
//        NSMutableDictionary *preventDuplicateDict = [[NSMutableDictionary alloc] init]; //to prevent duplicate words
//        NSString *strIndex = @"";
        
        while ([pickedIDArr count] < amount && count < [idListArr count]) {
//            randomIndex = arc4random() % [idListArr count];
//            strIndex = [NSString stringWithFormat:@"%d", count];
//            
//            if (![preventDuplicateDict objectForKey:strIndex]) {
//                [preventDuplicateDict setObject:strIndex forKey:strIndex];
//                
//                [pickedIDArr addObject:[idListArr objectAtIndex:randomIndex]];
//            }
            [pickedIDArr addObject:[idListArr objectAtIndex:count]];
            
            count ++;
//            if (count == 99) {  //99 is enough large
//                break;
//            }
        }
        
        //create json to add to db
        NSMutableDictionary *dictNewWords = [[NSMutableDictionary alloc] init];
        NSString *strDate = [NSString stringWithFormat:@"%f",curDate];
        
        [dictNewWords setObject:strDate forKey:@"date"];
        [dictNewWords setObject:pickedIDArr forKey:@"card"];
        
        //convert to json string
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dictNewWords
                                                           options:NSJSONWritingPrettyPrinted
                                                             error:&error];
        
        if (!jsonData) {
            NSLog(@"Got an error: %@", error);
        } else {
            strJson = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        }
        
        //update new pickedword to db
        strQuery = [NSString stringWithFormat:@"UPDATE \"system\" SET value = \'%@\' where key = 'pickedword'", strJson];
        
        charQuery = [strQuery UTF8String];
        
        sqlite3_prepare_v2(db, charQuery, -1, &dbps, NULL);
        
        if(SQLITE_DONE != sqlite3_step(dbps)) {
            NSLog(@"Error while updating. %s", sqlite3_errmsg(db));
        }
        
        sqlite3_finalize(dbps);
        
        //remove these words from buffer
        [idListArr removeObjectsInArray:pickedIDArr];
        
        NSMutableDictionary *dictReAdd = [[NSMutableDictionary alloc] init];
        [dictReAdd setObject:[[NSNumber alloc] initWithInteger:[idListArr count]] forKey:@"count"];
        [dictReAdd setObject:idListArr forKey:@"card"];
        
        //convert to json string
        jsonData = [NSJSONSerialization dataWithJSONObject:dictReAdd
                                                           options:NSJSONWritingPrettyPrinted
                                                             error:&error];
        
        if (!jsonData) {
            NSLog(@"Got an error: %@", error);
        } else {
            strJson = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        }
        
        //update new buffer to db
        strQuery = [NSString stringWithFormat:@"UPDATE \"system\" SET value = \'%@\' where key = 'buffer'", strJson];
        
        charQuery = [strQuery UTF8String];
        
        sqlite3_prepare_v2(db, charQuery, -1, &dbps, NULL);
        
        if(SQLITE_DONE != sqlite3_step(dbps)) {
            NSLog(@"Error while updating. %s", sqlite3_errmsg(db));
        }
        
        sqlite3_finalize(dbps);
        
        //update queue to NEW_WORD for picked words
        NSString *strIDList = @"";
        if ([pickedIDArr count] > 0) {
            strIDList = [[Common sharedCommon] stringByRemovingSpaceAndNewLineSymbol:[pickedIDArr description]];
            
            strQuery = [NSString stringWithFormat:@"UPDATE \"vocabulary\" SET queue = %d where id IN %@", QUEUE_NEW_WORD, strIDList];
            
            charQuery = [strQuery UTF8String];
            
            sqlite3_prepare_v2(db, charQuery, -1, &dbps, NULL);
            
            if(SQLITE_DONE != sqlite3_step(dbps)) {
                NSLog(@"Error while updating. %s", sqlite3_errmsg(db));
            }
            
            sqlite3_finalize(dbps);
        }
        
        sqlite3_close(db);
    }
}

//add a word to pickedword list more
- (void)addAWordToStydyingQueue:(WordObject *)wordObj {
    //get current value then add a word to "pickedword" more
    NSString *dbPath = [self getDatabasePath];
    NSURL *storeURL = [NSURL URLWithString:dbPath];
    
    const char *dbFilePathUTF8 = [[storeURL path] UTF8String];
    sqlite3 *db;
    int dbrc; //database return code
    dbrc = sqlite3_open(dbFilePathUTF8, &db);
    
    if (dbrc) {
        return;
    }
    sqlite3_stmt *dbps;
    
    NSString *strQuery = @"SELECT value from \"system\" WHERE key = 'pickedword'";
    
    const char *charQuery = [strQuery UTF8String];
    
    sqlite3_prepare_v2(db, charQuery, -1, &dbps, NULL);
    NSString *strJson = @"";
    
    while(sqlite3_step(dbps) == SQLITE_ROW) {
        if (sqlite3_column_text(dbps, 0)) {
            strJson = [NSString stringWithUTF8String:(char *)sqlite3_column_text(dbps, 0)];
        }
    }
    
    sqlite3_finalize(dbps);
    
    //parse the result to get word-id list
    NSTimeInterval oldDate = 0;
    NSMutableArray *idListArr = [[NSMutableArray alloc] init];
    NSData *data = [strJson dataUsingEncoding:NSUTF8StringEncoding];
    
    if (data) {
        NSDictionary *dictIDList = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        [idListArr addObjectsFromArray:[dictIDList valueForKey:@"card"]];
        oldDate = [[dictIDList valueForKey:@"date"] doubleValue];
    }
    
    BOOL found = NO;
    for (NSString *wordID in idListArr) {
        if ([wordID isEqualToString:wordObj.wordid]) {
            found = YES;
        }
    }
    
    //add new word if it is not existing in queue
    if (found == NO) {
        [idListArr addObject:wordObj.wordid];
    }
    
    //create json to add to db
    NSMutableDictionary *dictNewWords = [[NSMutableDictionary alloc] init];
    NSString *strDate = [NSString stringWithFormat:@"%f",oldDate];
    
    [dictNewWords setObject:strDate forKey:@"date"];
    [dictNewWords setObject:idListArr forKey:@"card"];
    
    //convert to json string
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dictNewWords
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&error];
    
    if (!jsonData) {
        NSLog(@"Got an error: %@", error);
    } else {
        strJson = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    
    //update new buffer to db
    strQuery = [NSString stringWithFormat:@"UPDATE \"system\" SET value = \'%@\' where key = 'pickedword'", strJson];
    
    charQuery = [strQuery UTF8String];
    
    sqlite3_prepare_v2(db, charQuery, -1, &dbps, NULL);
    
    if(SQLITE_DONE != sqlite3_step(dbps)) {
        NSLog(@"Error while updating. %s", sqlite3_errmsg(db));
    }
    
    sqlite3_finalize(dbps);
    sqlite3_close(db);
}

//key: buffer, pickedword, inreview
- (void)updateSystemTableForKey:(NSString *)key withArray:(NSArray *)wordsArr {
    NSMutableArray *idListArr = [[NSMutableArray alloc] init];
    
    for (WordObject *wordObj in wordsArr) {
        [idListArr addObject:wordObj.wordid];
    }
    
    //open db
    NSString *dbPath = [self getDatabasePath];
    NSURL *storeURL = [NSURL URLWithString:dbPath];
    
    const char *dbFilePathUTF8 = [[storeURL path] UTF8String];
    sqlite3 *db;
    int dbrc; //database return code
    dbrc = sqlite3_open(dbFilePathUTF8, &db);
    
    if (dbrc) {
        return;
    }
    sqlite3_stmt *dbps;
    
    NSString *strQuery = @"";
    NSString *strJson = @"";
    
    //get old date, just update word-id list, keep old date
    strQuery = @"SELECT value from \"system\" WHERE key = '%@'";
    strQuery = [NSString stringWithFormat:strQuery, key];
    
    const char *charQuery = [strQuery UTF8String];
    
    sqlite3_prepare_v2(db, charQuery, -1, &dbps, NULL);
    
    while(sqlite3_step(dbps) == SQLITE_ROW) {
        if (sqlite3_column_text(dbps, 0)) {
            strJson = [NSString stringWithUTF8String:(char *)sqlite3_column_text(dbps, 0)];
        }
    }
    
    sqlite3_finalize(dbps);
    
    //parse the result to get old date
    NSString *strOldDate = @"";
    NSNumber *countNumber = nil;
    NSData *data = [strJson dataUsingEncoding:NSUTF8StringEncoding];
    
    if (data) {
        NSDictionary *dictIDList = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        strOldDate = [dictIDList valueForKey:@"date"];
        
        if ([key isEqualToString:INREVIEW]) {
            countNumber = [dictIDList valueForKey:@"count"];
        }
    }
    
    //create json to add to db
    NSMutableDictionary *dictNewWords = [[NSMutableDictionary alloc] init];
    
    [dictNewWords setObject:strOldDate forKey:@"date"];
    [dictNewWords setObject:idListArr forKey:@"card"];
    
    if ([key isEqualToString:INREVIEW]) {
        [dictNewWords setObject:countNumber forKey:@"count"];   //keep this value even if removing a word from "card"
    }
    
    //convert to json string
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dictNewWords
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&error];
    
    if (!jsonData) {
        NSLog(@"Got an error: %@", error);
    } else {
        strJson = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    
    //update new buffer to db
    strQuery = [NSString stringWithFormat:@"UPDATE \"system\" SET value = \'%@\' where key = '%@'", strJson, key];
    
    charQuery = [strQuery UTF8String];
    
    sqlite3_prepare_v2(db, charQuery, -1, &dbps, NULL);
    
    if(SQLITE_DONE != sqlite3_step(dbps)) {
        NSLog(@"Error while updating. %s", sqlite3_errmsg(db));
    }
    
    sqlite3_finalize(dbps);
    sqlite3_close(db);
}

//update pickedword by wordArr
- (void)updatePickedWordList:(NSArray *)wordsArr {
    [self updateSystemTableForKey:PICKEDWORD withArray:wordsArr];
}

//update inreview by wordArr
- (void)updateInreviewWordList:(NSArray *)wordsArr {
    [self updateSystemTableForKey:INREVIEW withArray:wordsArr];
}

- (void)createInreivewListForADay:(NSArray *)wordsArr {
    NSMutableArray *idListArr = [[NSMutableArray alloc] init];
    
    for (WordObject *wordObj in wordsArr) {
        [idListArr addObject:wordObj.wordid];
    }
    
    //open db
    NSString *dbPath = [self getDatabasePath];
    NSURL *storeURL = [NSURL URLWithString:dbPath];
    
    const char *dbFilePathUTF8 = [[storeURL path] UTF8String];
    sqlite3 *db;
    int dbrc; //database return code
    dbrc = sqlite3_open(dbFilePathUTF8, &db);
    
    if (dbrc) {
        return;
    }
    sqlite3_stmt *dbps;
    
    NSString *strQuery = @"";
    NSString *strJson = @"";

    NSTimeInterval curDate = [[Common sharedCommon] getBeginOfDayInSec];   //just get time at the begin of day
    
    //create json to add to db
    NSMutableDictionary *dictNewWords = [[NSMutableDictionary alloc] init];
    NSString *strDate = [NSString stringWithFormat:@"%f",curDate];
    
    [dictNewWords setObject:strDate forKey:@"date"];
    [dictNewWords setObject:idListArr forKey:@"card"];
    [dictNewWords setObject:[[NSNumber alloc] initWithInteger:[wordsArr count]] forKey:@"count"];   //keep this value even if removing a word from "card"
    
    //convert to json string
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dictNewWords
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&error];
    
    if (!jsonData) {
        NSLog(@"Got an error: %@", error);
    } else {
        strJson = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    
    //update new pickedword to db
    strQuery = [NSString stringWithFormat:@"UPDATE \"system\" SET value = \'%@\' where key = 'inreview'", strJson];
    
    const char *charQuery = [strQuery UTF8String];
    
    sqlite3_prepare_v2(db, charQuery, -1, &dbps, NULL);
    
    if(SQLITE_DONE != sqlite3_step(dbps)) {
        NSLog(@"Error while updating. %s", sqlite3_errmsg(db));
    }
    
    sqlite3_finalize(dbps);
    sqlite3_close(db);
}

//fetch word objects from vocabulary by word-id that contained in pickedword or buffer
- (NSArray *)fetchWordsFromVocabularyForKey:(NSString *)key {
    //get word id from pickedword
    NSString *dbPath = [self getDatabasePath];
    NSURL *storeURL = [NSURL URLWithString:dbPath];
    
    const char *dbFilePathUTF8 = [[storeURL path] UTF8String];
    sqlite3 *db;
    int dbrc; //database return code
    dbrc = sqlite3_open(dbFilePathUTF8, &db);
    
    if (dbrc) {
        return nil;
    }
    sqlite3_stmt *dbps;
    
    NSString *strQuery = @"SELECT value from \"system\" WHERE key = '%@'";
    strQuery = [NSString stringWithFormat:strQuery, key];
    
    const char *charQuery = [strQuery UTF8String];
    
    sqlite3_prepare_v2(db, charQuery, -1, &dbps, NULL);
    NSString *strJson = @"";
    
    while(sqlite3_step(dbps) == SQLITE_ROW) {
        if (sqlite3_column_text(dbps, 0)) {
            strJson = [NSString stringWithUTF8String:(char *)sqlite3_column_text(dbps, 0)];
        }
    }
    
    sqlite3_finalize(dbps);
    
    //parse the result to get word-id list
    NSMutableArray *idListArr = [[NSMutableArray alloc] init];
    NSString *strIDList = @"";
    NSData *data = [strJson dataUsingEncoding:NSUTF8StringEncoding];
    
    if (data) {
        NSDictionary *dictIDList = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        [idListArr addObjectsFromArray:[dictIDList valueForKey:@"card"]];
        
        if (idListArr) {
            strIDList = [[Common sharedCommon] stringByRemovingSpaceAndNewLineSymbol:[idListArr description]];
        }
    }
    
    MajorObject *curMajorObj = (MajorObject *)[[Common sharedCommon] loadPersonalDataWithKey:KEY_SELECTED_MAJOR];
    NSString *curMajor = curMajorObj.majorName;
    
    if (curMajor == nil || curMajor.length == 0) {
        curMajor = @"common";
    } else {
        curMajor = [curMajor lowercaseString];
    }
    
    NSMutableArray *resArr = [[NSMutableArray alloc] init];
    
    while (([resArr count] < [idListArr count])) {
        //get word object  from vocabulary
        strQuery = [NSString stringWithFormat:@"SELECT id, question, answers, subcats, status, package, level, queue, due, rev_count, last_ivl, e_factor, l_vn, l_en, gid, user_note from \"vocabulary\" WHERE id IN %@ ORDER BY level", strIDList];
        
//        if (![curMajor isEqualToString:@"common"]) {
//            strQuery = [NSString stringWithFormat:@"SELECT id, question, answers, subcats, status, package, level, queue, due, rev_count, last_ivl, e_factor, l_vn, l_en, gid, user_note from \"vocabulary\" WHERE package LIKE '%%,%@,%%' AND id IN %@ ORDER BY level", curMajor, strIDList];
        
//        } else {
//            strQuery = [NSString stringWithFormat:@"SELECT id, question, answers, subcats, status, package, level, queue, due, rev_count, last_ivl, e_factor, l_vn, l_en, gid, user_note from \"vocabulary\" WHERE package LIKE '%%,%@,%%' AND package NOT LIKE '%%,%@,%%' AND id IN %@ ORDER BY level", curMajor, [[(MajorObject *)[[Common sharedCommon] loadPersonalDataWithKey:KEY_SELECTED_MAJOR] majorName] lowercaseString], strIDList];
//        }
        
        charQuery = [strQuery UTF8String];
        
        sqlite3_prepare_v2(db, charQuery, -1, &dbps, NULL);
        
        while(sqlite3_step(dbps) == SQLITE_ROW) {
            WordObject *wordObj = [[WordObject alloc] init];
            
            if (sqlite3_column_text(dbps, 0)) {
                wordObj.wordid = [NSString stringWithUTF8String:(char *)sqlite3_column_text(dbps, 0)];
            }
            
            if (sqlite3_column_text(dbps, 1)) {
                wordObj.question = [NSString stringWithUTF8String:(char *)sqlite3_column_text(dbps, 1)];
            }
            
            if (sqlite3_column_text(dbps, 2)) {
                wordObj.answers = [NSString stringWithUTF8String:(char *)sqlite3_column_text(dbps, 2)];
            }
            
            if (sqlite3_column_text(dbps, 3)) {
                wordObj.subcats = [NSString stringWithUTF8String:(char *)sqlite3_column_text(dbps, 3)];
            }
            
            if (sqlite3_column_text(dbps, 4)) {
                wordObj.status = [NSString stringWithUTF8String:(char *)sqlite3_column_text(dbps, 4)];
            }
            
            if (sqlite3_column_text(dbps, 5)) {
                wordObj.package = [NSString stringWithUTF8String:(char *)sqlite3_column_text(dbps, 5)];
            }
            
            if (sqlite3_column_text(dbps, 6)) {
                wordObj.level = [NSString stringWithUTF8String:(char *)sqlite3_column_text(dbps, 6)];
            }
            
            if (sqlite3_column_text(dbps, 7)) {
                wordObj.queue = [NSString stringWithUTF8String:(char *)sqlite3_column_text(dbps, 7)];
            }
            
            if (sqlite3_column_text(dbps, 8)) {
                wordObj.due = [NSString stringWithUTF8String:(char *)sqlite3_column_text(dbps, 8)];
            }
            
            if (sqlite3_column_text(dbps, 9)) {
                wordObj.revCount = [NSString stringWithUTF8String:(char *)sqlite3_column_text(dbps, 9)];
            }
            
            if (sqlite3_column_text(dbps, 10)) {
                wordObj.lastInterval = [NSString stringWithUTF8String:(char *)sqlite3_column_text(dbps, 10)];
            }
            
            if (sqlite3_column_text(dbps, 11)) {
                wordObj.eFactor = [NSString stringWithUTF8String:(char *)sqlite3_column_text(dbps, 11)];
            }
            
            if (sqlite3_column_text(dbps, 12)) {
                wordObj.langVN = [NSString stringWithUTF8String:(char *)sqlite3_column_text(dbps, 12)];
            }
            
            if (sqlite3_column_text(dbps, 13)) {
                wordObj.langEN = [NSString stringWithUTF8String:(char *)sqlite3_column_text(dbps, 13)];
            }
            
            if (sqlite3_column_text(dbps, 14)) {
                wordObj.gid = [NSString stringWithUTF8String:(char *)sqlite3_column_text(dbps, 14)];
            }
            
            if (sqlite3_column_text(dbps, 15)) {
                wordObj.userNote = [NSString stringWithUTF8String:(char *)sqlite3_column_text(dbps, 15)];
            }
            
            [resArr addObject:wordObj];
        }
        
        sqlite3_finalize(dbps);
        
        //if specilized word is not enough
        if ([resArr count] < [idListArr count] && ![curMajor isEqualToString:@"common"]) {
            curMajor = @"common";
        } else {
            break;
        }
    }
    
    sqlite3_close(db);
    
    return resArr;
}

- (NSInteger)getCountOfWordByKey:(NSString *)key {
    //get word id from key in system
    NSString *dbPath = [self getDatabasePath];
    NSURL *storeURL = [NSURL URLWithString:dbPath];
    
    const char *dbFilePathUTF8 = [[storeURL path] UTF8String];
    sqlite3 *db;
    int dbrc; //database return code
    dbrc = sqlite3_open(dbFilePathUTF8, &db);
    
    if (dbrc) {
        return 0;
    }
    sqlite3_stmt *dbps;
    
    NSString *strQuery = @"SELECT value from \"system\" WHERE key = '%@'";
    strQuery = [NSString stringWithFormat:strQuery, key];
    
    const char *charQuery = [strQuery UTF8String];
    
    sqlite3_prepare_v2(db, charQuery, -1, &dbps, NULL);
    NSString *strJson = @"";
    
    while(sqlite3_step(dbps) == SQLITE_ROW) {
        if (sqlite3_column_text(dbps, 0)) {
            strJson = [NSString stringWithUTF8String:(char *)sqlite3_column_text(dbps, 0)];
        }
    }
    
    //parse the result to get word-id list
     NSInteger res = 0;
    NSNumber *countNumber = nil;
    NSMutableArray *idListArr = [[NSMutableArray alloc] init];
    NSData *data = [strJson dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *dictIDList = nil;
    
    if (data) {
        dictIDList = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    }
    
    if ([key isEqualToString:INREVIEW]) {
        if (dictIDList) {
            countNumber = [dictIDList valueForKey:@"count"];
            res = [countNumber integerValue];
        }
    } else {
    
        if (dictIDList) {
            [idListArr addObjectsFromArray:[dictIDList valueForKey:@"card"]];
            res = [idListArr count];
        }
    }
    
    sqlite3_finalize(dbps);
    sqlite3_close(db);
    
    
    return res;
}

- (NSInteger)getCountOfPickedWord {
    //get word id from pickedword
    return [self getCountOfWordByKey:PICKEDWORD];
}

- (NSInteger)getCountOfBuffer {
    //get word id from buffer
    return [self getCountOfWordByKey:BUFFER];
}

- (NSInteger)getCountOfInreview {
    //get word id from buffer
    return [self getCountOfWordByKey:INREVIEW];
}

- (NSString *)getDatabasePath {
    NSString *dbPath = [[[Common sharedCommon] dataFolder] stringByAppendingPathComponent:DATABASENAME];
    
//    [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:DATABASENAME]
    if ([[NSFileManager defaultManager] fileExistsAtPath:dbPath]) {
        return dbPath;
    } else {
        return @"";
    }
}

- (NSString *)getNewDatabasePath {
    NSString *dbPath = [[[Common sharedCommon] dataFolder] stringByAppendingPathComponent:DATABASENAME_NEW];
    
    return dbPath;
}

- (NSString *)getBackupDatabasePath {
    NSString *dbPath = [[[Common sharedCommon] restoreFolder] stringByAppendingPathComponent:DATABASENAME_BACKUPZIP];
    
    return dbPath;
}

- (void)resetDateOfPickedWordList {
    //open db
    NSString *dbPath = [self getDatabasePath];
    NSURL *storeURL = [NSURL URLWithString:dbPath];
    
    const char *dbFilePathUTF8 = [[storeURL path] UTF8String];
    sqlite3 *db;
    int dbrc; //database return code
    dbrc = sqlite3_open(dbFilePathUTF8, &db);
    
    if (dbrc) {
        return;
    }
    sqlite3_stmt *dbps;
    
    NSString *strQuery = @"";
    NSString *strJson = @"";
    
    //get old date, just update word-id list, keep old date
    strQuery = @"SELECT value from \"system\" WHERE key = 'pickedword'";
    
    const char *charQuery = [strQuery UTF8String];
    
    sqlite3_prepare_v2(db, charQuery, -1, &dbps, NULL);
    
    while(sqlite3_step(dbps) == SQLITE_ROW) {
        if (sqlite3_column_text(dbps, 0)) {
            strJson = [NSString stringWithUTF8String:(char *)sqlite3_column_text(dbps, 0)];
        }
    }
    
    sqlite3_finalize(dbps);
    
    //parse the result to get old date
    NSData *data = [strJson dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *dictIDList = nil;
    if (data) {
        dictIDList = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    }
    
    if (dictIDList) {
        //create json to add to db
        NSTimeInterval curDate = [[Common sharedCommon] getBeginOfDayInSec];   //just get time at the begin of day
        NSString *strDate = [NSString stringWithFormat:@"%f",curDate];
        
        NSMutableDictionary *dictNewWords = [[NSMutableDictionary alloc] initWithDictionary:dictIDList];
        
        [dictNewWords setObject:strDate forKey:@"date"];
        
        //convert to json string
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dictNewWords
                                                           options:NSJSONWritingPrettyPrinted
                                                             error:&error];
        
        if (!jsonData) {
            NSLog(@"Got an error: %@", error);
        } else {
            strJson = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        }
        
        //update new buffer to db
        strQuery = [NSString stringWithFormat:@"UPDATE \"system\" SET value = \'%@\' where key = 'pickedword'", strJson];
        
        charQuery = [strQuery UTF8String];
        
        sqlite3_prepare_v2(db, charQuery, -1, &dbps, NULL);
        
        if(SQLITE_DONE != sqlite3_step(dbps)) {
            NSLog(@"Error while updating. %s", sqlite3_errmsg(db));
        }
        
        sqlite3_finalize(dbps);
    }
    
    sqlite3_close(db);
}

- (void)removeWordFromBuffer:(WordObject *)wordObj {
    NSString *dbPath = [self getDatabasePath];
    NSURL *storeURL = [NSURL URLWithString:dbPath];
    
    const char *dbFilePathUTF8 = [[storeURL path] UTF8String];
    sqlite3 *db;
    int dbrc; //database return code
    dbrc = sqlite3_open(dbFilePathUTF8, &db);
    
    if (dbrc) {
        return;
    }
    sqlite3_stmt *dbps;
    
    //check date before add new words to pickedword
    NSString *strQuery = @"SELECT value from \"system\" WHERE key = 'buffer'";
    const char *charQuery = [strQuery UTF8String];
    
    sqlite3_prepare_v2(db, charQuery, -1, &dbps, NULL);
    NSString *strJson = @"";
    
    while(sqlite3_step(dbps) == SQLITE_ROW) {
        if (sqlite3_column_text(dbps, 0)) {
            strJson = [NSString stringWithUTF8String:(char *)sqlite3_column_text(dbps, 0)];
            //{"count":37,"card":["67","5","27","29","39","46","58","4","21","43","81","139","165","175","180","262","269","277","279","334","359","387","2","7","8","10","11","13","14","19","31","35","38","42","44","47","49"]}
            
        }
    }
    
    sqlite3_finalize(dbps);
    
    //parse the result to get word-id list
    NSMutableArray *idListArr = [[NSMutableArray alloc] init];
    NSData *data = [strJson dataUsingEncoding:NSUTF8StringEncoding];
    if (data) {
        NSDictionary *dictIDList = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        [idListArr addObjectsFromArray:[dictIDList valueForKey:@"card"]];
        
    }
    
    for (NSString *wordid in idListArr) {
        if ([wordid isEqualToString:wordObj.wordid]) {
            [idListArr removeObject:wordid];
            break;
        }
    }
    
    NSMutableDictionary *dictReAdd = [[NSMutableDictionary alloc] init];
    [dictReAdd setObject:[[NSNumber alloc] initWithInteger:[idListArr count]] forKey:@"count"];
    [dictReAdd setObject:idListArr forKey:@"card"];
    
    //convert to json string
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dictReAdd
                                               options:NSJSONWritingPrettyPrinted
                                                 error:&error];
    
    if (!jsonData) {
        NSLog(@"Got an error: %@", error);
    } else {
        strJson = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    
    //update new buffer to db
    strQuery = [NSString stringWithFormat:@"UPDATE \"system\" SET value = \'%@\' where key = 'buffer'", strJson];
    
    charQuery = [strQuery UTF8String];
    
    sqlite3_prepare_v2(db, charQuery, -1, &dbps, NULL);
    
    if(SQLITE_DONE != sqlite3_step(dbps)) {
        NSLog(@"Error while updating. %s", sqlite3_errmsg(db));
    }
    
    sqlite3_finalize(dbps);
    sqlite3_close(db);
}

- (NSTimeInterval)getDateInBuffer {
    NSString *dbPath = [self getDatabasePath];
    NSURL *storeURL = [NSURL URLWithString:dbPath];
    
    const char *dbFilePathUTF8 = [[storeURL path] UTF8String];
    sqlite3 *db;
    int dbrc; //database return code
    dbrc = sqlite3_open(dbFilePathUTF8, &db);
    
    if (dbrc) {
        return 0;
    }
    sqlite3_stmt *dbps;
    
    NSString *strQuery = @"SELECT value from \"system\" WHERE key = 'pickedword'";
    
    const char *charQuery = [strQuery UTF8String];
    
    sqlite3_prepare_v2(db, charQuery, -1, &dbps, NULL);
    NSString *strJson = @"";
    
    while(sqlite3_step(dbps) == SQLITE_ROW) {
        if (sqlite3_column_text(dbps, 0)) {
            strJson = [NSString stringWithUTF8String:(char *)sqlite3_column_text(dbps, 0)];
        }
    }
    
    sqlite3_finalize(dbps);
    
    //parse the result to get date
    NSData *data = [strJson dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *dictIDList = nil;
    
    if (data) {
        dictIDList = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    }
    

    NSString *date = nil;
    if (dictIDList) {
         date = [dictIDList valueForKey:@"date"];
    }
    
    sqlite3_close(db);
    
    NSTimeInterval dateInterval = 0;
    if (date) {
        dateInterval = [date doubleValue];
    }
    
    return dateInterval;
}

#pragma mark export database
- (NSArray *)fetchDataNeedToBackup {
    NSString *dbPath = [self getDatabasePath];
    
    NSString *strQuery = @"SELECT queue, due, rev_count, last_ivl, e_factor, gid, user_note, level FROM 'vocabulary' WHERE queue = 1 OR queue = 2 OR queue = -1 OR queue = -2";
    
    NSURL *storeURL = [NSURL URLWithString:dbPath];
    const char *dbFilePathUTF8 = [[storeURL path] UTF8String];
    sqlite3 *db;
    int dbrc; //database return code
    dbrc = sqlite3_open(dbFilePathUTF8, &db);
    
    if (dbrc) {
        return nil;
    }
    sqlite3_stmt *dbps;
    
    const char *charQuery = [strQuery UTF8String];
    
    sqlite3_prepare_v2(db, charQuery, -1, &dbps, NULL);
    
    NSMutableArray *resArr = [[NSMutableArray alloc] init];
    
    //    NSMutableDictionary *log = [[NSMutableDictionary alloc] init];//for test
    while(sqlite3_step(dbps) == SQLITE_ROW) {
        WordObject *wordObj = [[WordObject alloc] init];
        
        //queue, due, rev_count, last_ivl, e_factor, gid, user_note
        if (sqlite3_column_text(dbps, 0)) {
            wordObj.queue = [NSString stringWithUTF8String:(char *)sqlite3_column_text(dbps, 0)];
        }
        
        if (sqlite3_column_text(dbps, 1)) {
            wordObj.due = [NSString stringWithUTF8String:(char *)sqlite3_column_text(dbps, 1)];
        }
        
        if (sqlite3_column_text(dbps, 2)) {
            wordObj.revCount = [NSString stringWithUTF8String:(char *)sqlite3_column_text(dbps, 2)];
        }
        
        if (sqlite3_column_text(dbps, 3)) {
            wordObj.lastInterval = [NSString stringWithUTF8String:(char *)sqlite3_column_text(dbps, 3)];
        }
        
        if (sqlite3_column_text(dbps, 4)) {
            wordObj.eFactor = [NSString stringWithUTF8String:(char *)sqlite3_column_text(dbps, 4)];
        }

        if (sqlite3_column_text(dbps, 5)) {
            wordObj.gid = [NSString stringWithUTF8String:(char *)sqlite3_column_text(dbps, 5)];
        }
        
        if (sqlite3_column_text(dbps, 6)) {
            wordObj.userNote = [NSString stringWithUTF8String:(char *)sqlite3_column_text(dbps, 6)];
        }
        
        if (sqlite3_column_text(dbps, 7)) {
            wordObj.level = [NSString stringWithUTF8String:(char *)sqlite3_column_text(dbps, 7)];
        }
        
        [resArr addObject:wordObj];
    }
    
    sqlite3_finalize(dbps);
    sqlite3_close(db);
    
    return resArr;
}

- (void)writeDataToFile:(NSArray *)dataArr {
    NSString *path = [[[Common sharedCommon] backupFolder] stringByAppendingPathComponent:DATABASENAME_BACKUP];
    [[Common sharedCommon] trashFileAtPathAndEmpptyTrash:path];
    
    NSMutableString *strData = [[NSMutableString alloc] init];
    for (WordObject *word in dataArr) {
        NSString *userNote = [word.userNote stringByReplacingOccurrencesOfString:@"," withString:@"*#*"];
        
        [strData appendFormat:@"%@,%@,%@,%@,%@,%@,%@,%@,\n", word.gid, word.queue, word.due,word.revCount, word.lastInterval, word.eFactor, userNote, word.level];
    }
    NSError *error = nil;
    [strData writeToFile:path
              atomically:YES
                encoding:NSUTF8StringEncoding
                   error:&error];
    NSLog(@"%@", error.description);
}

- (void)writeStreakToFile {
    NSString *path = [[[Common sharedCommon] backupFolder] stringByAppendingPathComponent:STREAK_BACKUP];
    [[Common sharedCommon] trashFileAtPathAndEmpptyTrash:path];
    
    NSArray *streakArr = [[Common sharedCommon] loadStreak];
    
    NSMutableString *strData = [[NSMutableString alloc] init];
    for (NSNumber *streak in streakArr) {
        [strData appendFormat:@"%@,\n", streak];
    }
    NSError *error = nil;
    [strData writeToFile:path
              atomically:YES
                encoding:NSUTF8StringEncoding
                   error:&error];
    NSLog(@"%@", error.description);
}

- (void)backupData {
    NSArray *data = [self fetchDataNeedToBackup];
    [self writeDataToFile:data];
    
    [self writeStreakToFile];
    
    NSString *pathWordFile = [[[Common sharedCommon] backupFolder] stringByAppendingPathComponent:DATABASENAME_BACKUP];
    NSString *pathStreakFile = [[[Common sharedCommon] backupFolder] stringByAppendingPathComponent:STREAK_BACKUP];
    NSString *pathZip = [[[Common sharedCommon] backupFolder] stringByAppendingPathComponent:DATABASENAME_BACKUPZIP];
    
    [[Common sharedCommon] trashFileAtPathAndEmpptyTrash:pathZip];
    
    [SSZipArchive createZipFileAtPath: pathZip withFilesAtPaths:[NSArray arrayWithObjects:pathWordFile, pathStreakFile, nil]];
    
    [[Common sharedCommon] trashFileAtPathAndEmpptyTrash:pathWordFile];
    [[Common sharedCommon] trashFileAtPathAndEmpptyTrash:pathStreakFile];
}

- (BOOL)restoreData {
    NSString *pathWordFile = [[[Common sharedCommon] restoreFolder] stringByAppendingPathComponent:DATABASENAME_BACKUP];
    NSString *pathStreakFile = [[[Common sharedCommon] restoreFolder] stringByAppendingPathComponent:STREAK_BACKUP];
    
    //remove old file before unzipping for sure
    [[Common sharedCommon] trashFileAtPathAndEmpptyTrash:pathWordFile];
    [[Common sharedCommon] trashFileAtPathAndEmpptyTrash:pathStreakFile];
    
    
    //unzip
    NSString *pathZip = [[[Common sharedCommon] restoreFolder] stringByAppendingPathComponent:DATABASENAME_BACKUPZIP];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:pathZip]) {
        [SSZipArchive unzipFileAtPath:pathZip toDestination:[[Common sharedCommon] restoreFolder]];
        [[Common sharedCommon] trashFileAtPathAndEmpptyTrash:pathZip];
        
        //read word file
        if ([[NSFileManager defaultManager] fileExistsAtPath:pathWordFile]) {
            NSString *fileContent = [NSString stringWithContentsOfFile:pathWordFile encoding:NSASCIIStringEncoding error:nil];
            
            NSArray *rows = [fileContent componentsSeparatedByString:@",\n"];
            
            //open db
            NSString *dbPath = [self getDatabasePath];
            NSURL *storeURL = [NSURL URLWithString:dbPath];
            
            const char *dbFilePathUTF8 = [[storeURL path] UTF8String];
            sqlite3 *db;
            int dbrc; //database return code
            dbrc = sqlite3_open(dbFilePathUTF8, &db);
            
            if (dbrc) {
                return NO;
            }
            sqlite3_stmt *dbps;
            
            NSString *strQuery = @"";
            const char *charQuery = nil;
            NSMutableArray *missingWords = [[NSMutableArray alloc] init];
            
            for (NSString *row in rows) {
                NSArray *values = [row componentsSeparatedByString:@","];
                //word.question, word.queue, word.due, word.revCount, word.lastInterval, word.eFactor, word.userNote, word.level
                
                if ([values count] == 7) {
                    //for test - begin
                    /*
                    int count = 0;
                    strQuery = [NSString stringWithFormat:@"SELECT COUNT(*) FROM 'vocabulary' WHERE gid = '%@'", [values objectAtIndex:0]];
                    charQuery = [strQuery UTF8String];
                    
                    sqlite3_prepare_v2(db, charQuery, -1, &dbps, NULL);
                    
                    if(SQLITE_DONE != sqlite3_step(dbps)) {
                        if (sqlite3_column_int(dbps, 0)) {
                            count = sqlite3_column_int(dbps, 0);
                        }
                    }
                    
                    sqlite3_finalize(dbps);
                    
                    if (count <= 0) {
                        [missingWords addObject:values];
                    }
                    //for test - end
                     */
                    
                    NSString *userNote = [[values objectAtIndex:6] stringByReplacingOccurrencesOfString:@"*#*" withString:@","];
                    
                    strQuery = [NSString stringWithFormat:@"UPDATE 'vocabulary' SET queue = %d, due = %d, rev_count = %d, last_ivl = %d, e_factor = %d, user_note = '%@' where gid = '%@'", [[values objectAtIndex:1] intValue], [[values objectAtIndex:2] intValue], [[values objectAtIndex:3] intValue], [[values objectAtIndex:4] intValue], [[values objectAtIndex:5] intValue], userNote, [values objectAtIndex:0]];
                    
                    charQuery = [strQuery UTF8String];
                    
                    sqlite3_prepare_v2(db, charQuery, -1, &dbps, NULL);
                    NSInteger res = sqlite3_step(dbps);

                    if(SQLITE_DONE != res) {
                        NSLog(@"Error while updating. %s", sqlite3_errmsg(db));
                    }
                    
                    sqlite3_finalize(dbps);
                    
                } else if ([values count] == 8) {   //add a new field to backup data :: level
                    NSString *level = [values objectAtIndex:7];
                    if ([level isEqualToString:@"8"]) {
                        [missingWords addObject:values];
                        
                    } else {
                        NSString *userNote = [[values objectAtIndex:6] stringByReplacingOccurrencesOfString:@"*#*" withString:@","];
                        
                        strQuery = [NSString stringWithFormat:@"UPDATE 'vocabulary' SET queue = %d, due = %d, rev_count = %d, last_ivl = %d, e_factor = %d, user_note = '%@' where gid = '%@'", [[values objectAtIndex:1] intValue], [[values objectAtIndex:2] intValue], [[values objectAtIndex:3] intValue], [[values objectAtIndex:4] intValue], [[values objectAtIndex:5] intValue], userNote, [values objectAtIndex:0]];
                        
                        charQuery = [strQuery UTF8String];
                        
                        sqlite3_prepare_v2(db, charQuery, -1, &dbps, NULL);
                        NSInteger res = sqlite3_step(dbps);
                        
                        if(SQLITE_DONE != res) {
                            NSLog(@"Error while updating. %s", sqlite3_errmsg(db));
                        }
                        
                        sqlite3_finalize(dbps);
                    }
                    
                }
            }
            
            sqlite3_close(db);
            
            //remove file after restore
            [[Common sharedCommon] trashFileAtPathAndEmpptyTrash:pathWordFile];
            lostWords = [[NSMutableArray alloc] init];
            if ([missingWords count] > 0) {
                [self downloadMissingWordsAndUpdate:missingWords];
            }
        }
        
        //read streak file
        if ([[NSFileManager defaultManager] fileExistsAtPath:pathStreakFile]) {
            NSString *fileContent = [NSString stringWithContentsOfFile:pathStreakFile encoding:NSASCIIStringEncoding error:nil];
            
            NSArray *rows = [fileContent componentsSeparatedByString:@",\n"];
            NSMutableArray *streakArr = [[NSMutableArray alloc] init];
            NSNumber *number = nil;
            for (NSString *row in rows) {
                if ([row longLongValue] > 0) {
                    number = [NSNumber numberWithLongLong:[row longLongValue]];
                    
                    [streakArr addObject:number];
                }
            }
            
            NSData* archivedData = [NSKeyedArchiver archivedDataWithRootObject:streakArr];
            
            [[Common sharedCommon] saveDataToUserDefaultStandard:archivedData withKey:KEY_STREAK_INFO];
            
            //remove file after restore
            [[Common sharedCommon] trashFileAtPathAndEmpptyTrash:pathStreakFile];
        }
        
    } else {
        return NO;
    }
    
    return YES;
}

- (void)downloadMissingWordsAndUpdate:(NSMutableArray *)missingWords {

    for (NSArray *wordFields in missingWords) {
        NSString *gid = [wordFields objectAtIndex:0];
        
        static GTLServiceDataServiceApi *service = nil;
        if (!service) {
            service = [[GTLServiceDataServiceApi alloc] init];
            service.retryEnabled = YES;
            //[GTMHTTPFetcher setLoggingEnabled:YES];
        }
        
        GTLQueryDataServiceApi *query = [GTLQueryDataServiceApi queryForGetVocaByIdWithIdentifier:[gid longLongValue]];
        //TODO: Add waiting progress here
        [service executeQuery:query completionHandler:^(GTLServiceTicket *ticket, GTLDataServiceApiVoca *object, NSError *error) {
            if (object != NULL){
                //NSLog(object.JSONString);
                //TODO: Update word: q, a, level, package, (and ee, ev)
                //word.question, word.queue, word.due, word.revCount, word.lastInterval, word.eFactor, word.userNote, word.level
                
                WordObject *wordObj = [[WordObject alloc] init];
                wordObj.question   = object.q;
                wordObj.answers    = object.a;
                wordObj.level      = [NSString stringWithFormat:@"%ld", (long)[object.level integerValue]];
                wordObj.package    = object.packages;
                wordObj.gid        = [NSString stringWithFormat:@"%@", object.gid];
                
                if (object.lEn && object.lEn.length > 0) {
                    wordObj.langEN     = object.lEn;
                }
                
                if (object.lVn && object.lVn.length > 0) {
                    wordObj.langVN     = object.lVn;
                }
                
                wordObj.package    = object.packages;
                
                //update info from backup data
                wordObj.eFactor    = [wordFields objectAtIndex:5];
                wordObj.queue      = [wordFields objectAtIndex:1];
                //                wordObj.isFromServer = YES;   //set YES if dont insert this word to db right here //dont need to do this because we add it right here
                wordObj.due        = [wordFields objectAtIndex:2];
                wordObj.revCount   = [wordFields objectAtIndex:3];
                wordObj.lastInterval = [wordFields objectAtIndex:4];
                wordObj.userNote        = [wordFields objectAtIndex:6];
                
                //insert to db, no need to get from server next time
                [[CommonSqlite sharedCommonSqlite] insertWordToDatabase:wordObj];
                
            } else {
                 [lostWords addObject:gid];
                NSLog(@"%@", lostWords);
            }
        }];
    }
    
}

- (NSDictionary *)getCountOfWordByLevel {
    NSMutableDictionary *resDict = [[NSMutableDictionary alloc] init];
    
    NSString *dbPath = [self getDatabasePath];
    NSURL *storeURL = [NSURL URLWithString:dbPath];
    
    const char *dbFilePathUTF8 = [[storeURL path] UTF8String];
    sqlite3 *db;
    int dbrc; //database return code
    dbrc = sqlite3_open(dbFilePathUTF8, &db);
    
    if (dbrc) {
        return resDict;
    }
    sqlite3_stmt *dbps;
    
    NSString *strQuery = @"";
    const char *charQuery = nil;
    NSInteger count = 0;
    
    for (int level = 1; level <= 8; level++) {
        count = 0;
        strQuery = [NSString stringWithFormat:@"SELECT COUNT(*) FROM 'vocabulary' WHERE level = %d", level];
        charQuery = [strQuery UTF8String];
        
        sqlite3_prepare_v2(db, charQuery, -1, &dbps, NULL);
        
        if(SQLITE_DONE != sqlite3_step(dbps)) {
            if (sqlite3_column_int(dbps, 0)) {
                count = sqlite3_column_int(dbps, 0);
            }
        }
        
        if (count <= 0 || level == 8) {
            count = 5000;
        }
        
        [resDict setObject:[NSNumber numberWithInteger:count] forKey:[NSString stringWithFormat:@"%d", level]];
        
        sqlite3_finalize(dbps);
    }
    
    return resDict;
}
@end
