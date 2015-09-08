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

// Singleton
static CommonSqlite* sharedCommonSqlite = nil;

@implementation CommonSqlite


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
- (WordObject *)getWordInformation:(NSString *)word {
    NSString *strQuery = [NSString stringWithFormat: @"SELECT id, question, answers, subcats, status, package, level, queue, due, rev_count, last_ivl, e_factor FROM \"vocabulary\" WHERE question = '%@'", word];
    
    NSArray *resArr = [self getWordByQueryString:strQuery];
    
    return [resArr objectAtIndex:0];
}

- (NSArray *)getStudiedList {
    NSString *strQuery = @"SELECT id, question, answers, subcats, status, package, level, queue, due, rev_count, last_ivl, e_factor FROM \"vocabulary\" where queue >= 1 ORDER BY level";
    
    NSArray *resArr = [self getWordByQueryString:strQuery];
    
    return resArr;
}

- (NSArray *)getNewWordsList {
    NSArray *resArr = [self fetchPickedWordFromVocabulary];
    
    return resArr;
}

- (NSArray *)getStudyAgainList {
    NSString *strQuery = @"SELECT id, question, answers, subcats, status, package, level, queue, due, rev_count, last_ivl, e_factor FROM \"vocabulary\" where queue = 1 ORDER BY level";
    
    NSArray *resArr = [self getWordByQueryString:strQuery];
    
    return resArr;
}

- (NSArray *)getReviewList {
    NSString *strQuery = [NSString stringWithFormat:@"SELECT id, question, answers, subcats, status, package, level, queue, due, rev_count, last_ivl, e_factor FROM \"vocabulary\" where queue = 2 AND due <= %f ORDER BY level", [self getEndOfDayInSec]];
    
    NSArray *resArr = [self getWordByQueryString:strQuery];
    
    return resArr;
}

- (NSArray *)getSearchHintList:(NSString *)searchText {
    NSString *strQuery = [NSString stringWithFormat:@"SELECT id, question, answers, subcats, status, package, level, queue, due, rev_count, last_ivl, e_factor FROM \"vocabulary\" where question like '%@%%' ORDER BY level LIMIT 10", searchText];
    
    NSArray *resArr = [self getWordByQueryString:strQuery];
    
    return resArr;
}

- (NSArray *)getSearchResultList:(NSString *)searchText {
    NSString *strQuery = [NSString stringWithFormat:@"SELECT id, question, answers, subcats, status, package, level, queue, due, rev_count, last_ivl, e_factor FROM \"vocabulary\" where question like '%@%%' ORDER BY level", searchText];
    
    NSArray *resArr = [self getWordByQueryString:strQuery];
    
    return resArr;
}

//selected fields in the query string must be ordered as: id, question, answers, subcats, status, package, level, queue, due, rev_count, last_ivl, e_factor
- (NSArray *)getWordByQueryString:(NSString *)strQuery {
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

    const char *charQuery = [strQuery UTF8String];
    
    sqlite3_prepare_v2(db, charQuery, -1, &dbps, NULL);
    
    NSMutableArray *resArr = [[NSMutableArray alloc] init];
    
    while(sqlite3_step(dbps) == SQLITE_ROW) {
        WordObject *wordObj = [[WordObject alloc] init];
        
        //id, question, answers, subcats, status, package, level, queue, due, revCount, lastInterval, eFactor
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
        
        [resArr addObject:wordObj];
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
    NSString *strQuery = [NSString stringWithFormat:@"UPDATE \"vocabulary\" SET queue = %d, due = %d, rev_count = %d, last_ivl = %d, e_factor = %d where question = \'%@\'", [wordObj.queue intValue], [wordObj.due intValue], [wordObj.revCount intValue], [wordObj.lastInterval intValue], [wordObj.eFactor intValue], wordObj.question];
    const char *charQuery = [strQuery UTF8String];
    
    sqlite3_prepare_v2(db, charQuery, -1, &dbps, NULL);
    
    if(SQLITE_DONE != sqlite3_step(dbps)) {
        NSLog(@"Error while updating. %s", sqlite3_errmsg(db));
    }
    
    sqlite3_finalize(dbps);
    sqlite3_close(db);

}

- (NSTimeInterval)getEndOfDayInSec {
    NSTimeInterval datetime = [[Common sharedCommon] getCurrentDateInSec];
    
    datetime = datetime + 24*3600;
    
    return datetime;
}

#pragma mark system table
//pick up "amount" news word-ids from vocabulary, then add to buffer
- (void)prepareWordsToStudyingQueue:(NSInteger)amount {
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

    //comment this because dont care what the current buffer is
    //override the current buffer
    /*
    strQuery = @"SELECT value from \"system\" WHERE key = 'buffer'";
    charQuery = [strQuery UTF8String];
    
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
    NSString *strIDList = @"";
    NSArray *idListArr = nil;
    NSData *data = [strJson dataUsingEncoding:NSUTF8StringEncoding];
    if (data) {
        NSDictionary *dictIDList = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        idListArr = [dictIDList valueForKey:@"card"];
        
        if (idListArr) {
            strIDList = [[Common sharedCommon] stringByRemovingSpaceAndNewLineSymbol:[idListArr description]];
        }
    }
*/
    //pick up "amount" news word-ids from vocabulary that not included the old words
//    if (amount > [idListArr count]) {
    NSMutableArray *resArr = [[NSMutableArray alloc] init];
    NSArray *wordAmountByLevel = [[Algorithm sharedAlgorithm] distributeWordByLevel];
    
    for (int i = 1; i < [wordAmountByLevel count]; i++) {
        strQuery = [NSString stringWithFormat:@"SELECT id from \"vocabulary\" WHERE queue = 0 AND level = %d ORDER BY id LIMIT %d", i, [[wordAmountByLevel objectAtIndex:i] intValue]];
        charQuery = [strQuery UTF8String];
        
        sqlite3_prepare_v2(db, charQuery, -1, &dbps, NULL);
        NSLog(@"Error while updating. %s", sqlite3_errmsg(db));
        while(sqlite3_step(dbps) == SQLITE_ROW) {
            if (sqlite3_column_text(dbps, 0)) {
                NSString *wordID = [NSString stringWithUTF8String:(char *)sqlite3_column_text(dbps, 0)];
                
                [resArr addObject:wordID];
            }
        }
        
        sqlite3_finalize(dbps);
    }
    
    //if not enough "amount" words
    int count = 0; //to prevent infinity loop
    while ([resArr count] < amount) {
        NSInteger randomIndex = arc4random() % ([wordAmountByLevel count] - 1);
        
        if (randomIndex == 0) {
            randomIndex ++;
        }

        strQuery = [NSString stringWithFormat:@"SELECT id from \"vocabulary\" WHERE queue = 0 AND level = %ld ORDER BY id LIMIT %ld", (long)randomIndex, amount - [resArr count]];
        charQuery = [strQuery UTF8String];
        
        sqlite3_prepare_v2(db, charQuery, -1, &dbps, NULL);
        
        while(sqlite3_step(dbps) == SQLITE_ROW) {
            if (sqlite3_column_text(dbps, 0)) {
                NSString *wordID = [NSString stringWithUTF8String:(char *)sqlite3_column_text(dbps, 0)];
                
                [resArr addObject:wordID];
            }
        }
        
        sqlite3_finalize(dbps);
        
        count ++;
        if (count == 10) {
            break;
        }
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
//    }
    
    sqlite3_close(db);
}

//pick up "amount" word-ids from buffer, then add to pickedword (this list is to study)
- (void)pickUpRandom10WordsToStudyingQueue:(NSInteger)amount {
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
    NSTimeInterval curDate = [[Common sharedCommon] getCurrentDatetimeInSec];
    
    if (oldDate == 0 || curDate > oldDate + 24*3600) {
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
        
        NSUInteger randomIndex = 0;
        NSMutableArray *pickedIDArr = [[NSMutableArray alloc] init];
        for (int i = 0; i < PICKED_WORDS_QUEUE_SIZE; i++) {
            randomIndex = arc4random() % [idListArr count];
            
            [pickedIDArr addObject:[idListArr objectAtIndex:randomIndex]];
        }
        
        //create json to add to db
        NSMutableDictionary *dictNewWords = [[NSMutableDictionary alloc] init];
        NSString *strDate = [NSString stringWithFormat:@"%f",[[Common sharedCommon] getCurrentDatetimeInSec]];
        
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
    
    //add new word
    [idListArr addObject:wordObj.wordid];
    
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

//update pickedword by wordArr
- (void)updatePickedWordList:(NSArray *)wordsArr {
    NSMutableArray *idListArr = [[NSMutableArray alloc] init];
    
    for (WordObject *wordObj in wordsArr) {
        [idListArr addObject:wordObj.wordid];
    }
    
    //write to db
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
    //create json to add to db
    NSMutableDictionary *dictNewWords = [[NSMutableDictionary alloc] init];
    NSString *strDate = [NSString stringWithFormat:@"%f",[[Common sharedCommon] getCurrentDatetimeInSec]];
    
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
    
    const char *charQuery = [strQuery UTF8String];
    
    sqlite3_prepare_v2(db, charQuery, -1, &dbps, NULL);
    
    if(SQLITE_DONE != sqlite3_step(dbps)) {
        NSLog(@"Error while updating. %s", sqlite3_errmsg(db));
    }
    
    sqlite3_finalize(dbps);
    sqlite3_close(db);
}

//fetch word objects from vocabulary by word-id that contained in pickedword
- (NSArray *)fetchPickedWordFromVocabulary {
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
    
    //get word object  from vocabulary
    strQuery = [NSString stringWithFormat:@"SELECT id, question, answers, subcats, status, package, level from \"vocabulary\" WHERE id IN %@", strIDList];
    charQuery = [strQuery UTF8String];
    
    sqlite3_prepare_v2(db, charQuery, -1, &dbps, NULL);
    NSMutableArray *resArr = [[NSMutableArray alloc] init];
    
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
        
        [resArr addObject:wordObj];
    }
    
    sqlite3_finalize(dbps);
    sqlite3_close(db);
    
    return resArr;
}

- (NSInteger)getCountOfPickedWord {
    //get word id from pickedword
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
    
    //parse the result to get word-id list
    NSMutableArray *idListArr = [[NSMutableArray alloc] init];
    NSData *data = [strJson dataUsingEncoding:NSUTF8StringEncoding];
    
    if (data) {
        NSDictionary *dictIDList = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        [idListArr addObjectsFromArray:[dictIDList valueForKey:@"card"]];
    }
    
    sqlite3_finalize(dbps);
    sqlite3_close(db);
    
    return [idListArr count];
}

- (NSString *)getDatabasePath {
    NSString *dbPath = [[[Common sharedCommon] documentsFolder] stringByAppendingPathComponent:DATABASENAME];
    
//    [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:DATABASENAME]
    if ([[NSFileManager defaultManager] fileExistsAtPath:dbPath]) {
        return dbPath;
    } else {
        return @"";
    }
}
@end