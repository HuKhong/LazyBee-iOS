//
//  CommonSqlite.h
//  LazzyBee
//
//  Created by HuKhong on 4/19/15.
//  Copyright (c) 2015 HuKhong. All rights reserved.
//

#ifndef LazzyBee_CommonAlert_h
#define LazzyBee_CommonAlert_h
#import <Foundation/Foundation.h>
#import "WordObject.h"

@interface CommonSqlite : NSObject

// a singleton:
+ (CommonSqlite*) sharedCommonSqlite;

- (WordObject *)getWordInformation:(NSString *)word;
- (NSArray *)getStudiedList;
- (void)updateWord:(WordObject *)wordObj;
- (void)saveNoteForWord:(WordObject *)wordObj withNewNote:(NSString *)note;
- (void)insertWordToDatabase:(WordObject *)wordObj;

- (NSArray *)getNewWordsList;
- (NSArray *)getStudyAgainListWithLimit:(NSInteger)limit;
- (NSArray *)getReviewList;
- (NSArray *)getIncomingList;

- (NSArray *)getSearchHintList:(NSString *)searchText;
- (NSArray *)getSearchResultList:(NSString *)searchText;

- (void)prepareWordsToStudyingQueue:(NSInteger)amount inPackage:(NSString *)package;
- (void)pickUpRandom10WordsToStudyingQueue:(NSInteger)amount withForceFlag:(BOOL)force;
- (void)addAWordToStydyingQueue:(WordObject *)wordObj;
- (void)updatePickedWordList:(NSArray *)wordsArr;
- (void)updateInreviewWordList:(NSArray *)wordsArr;
- (NSInteger)getCountOfPickedWord;
- (NSInteger)getCountOfBuffer;
- (NSInteger)getCountOfInreview;
- (NSInteger)getCountOfStudyAgain;
- (NSInteger)getCountOfStudiedWord;
- (void)resetDateOfPickedWordList;
- (BOOL)updateDatabaseWithPath:(NSString *)bdPath;
- (NSArray *)getAllWords;
- (void)addMoreFieldToTable;
- (void)removeWordFromBuffer:(WordObject *)wordObj;
- (NSTimeInterval)getDateInBuffer;

- (void)backupData;
- (BOOL)restoreData;
- (NSString *)getBackupDatabasePath;

- (NSString *)getDatabasePath;

- (NSDictionary *)getCountOfWordByLevel;
@end

#endif
