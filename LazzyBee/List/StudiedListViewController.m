//
//  StudiedListViewController.m
//  LazzyBee
//
//  Created by HuKhong on 8/21/15.
//  Copyright (c) 2015 Born2go. All rights reserved.
//

#import "StudiedListViewController.h"
#import "StudiedTableViewCell.h"
#import "CommonSqlite.h"
#import "Common.h"
#import "StudyWordViewController.h"
#import "TagManagerHelper.h"
#import "SVProgressHUD.h"
#import "DictDetailContainerViewController.h"
#import "MGSwipeTableCell.h"
#import "MGSwipeButton.h"

@interface StudiedListViewController ()
{
    NSMutableDictionary *levelsDictionary;
    NSMutableArray *wordList;
    NSArray *keyArr;
    
    UIRefreshControl *refreshControl;
}
@end

@implementation StudiedListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    if (_screenType == List_Incoming) {
        [TagManagerHelper pushOpenScreenEvent:@"iIncomingScreen"];
        
        [self setTitle:@"Incoming List"];
        
        refreshControl = [[UIRefreshControl alloc] init];
        refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to re-fill"];
        [refreshControl addTarget:self action:@selector(refreshIncomingTable) forControlEvents:UIControlEventValueChanged];
        [wordsTableView addSubview:refreshControl];
        
    } else if (_screenType == List_StudiedList) {
        [TagManagerHelper pushOpenScreenEvent:@"iLeantScreen"];
        
        [self setTitle:@"Learnt List"];
        
    } else if (_screenType == List_SearchHint) {
        [TagManagerHelper pushOpenScreenEvent:@"iSearchHintScreen"];
        
    } else if (_screenType == List_SearchResult) {
        [TagManagerHelper pushOpenScreenEvent:@"iSearchResultScreen"];
        
        [self setTitle:@"Search Result"];
    }
    
    levelsDictionary = [[NSMutableDictionary alloc] init];
    wordList = [[NSMutableArray alloc] init];
    
    [self tableReload];
    
    //in case clicking on Add to learn
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshList)
                                                 name:@"AddToLearn"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(changeMajor)
                                                 name:@"ChangeMajor"
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

#pragma mark data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    if (_screenType == List_StudiedList ||
        _screenType == List_SearchHint ||
        _screenType == List_SearchResult) {
        return [[levelsDictionary allKeys] count];
        
    } else {
        
        return 1;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    
    if (_screenType == List_StudiedList ||
        _screenType == List_SearchHint ||
        _screenType == List_SearchResult) {
        NSString *headerTitle = @"";
        
        if (section < [keyArr count]) {
            NSString *key = [keyArr objectAtIndex:section];
            
            headerTitle = [NSString stringWithFormat:@"Level %@: %ld word(s)", key, [[levelsDictionary objectForKey:key] count]];
        }
        
        return headerTitle;
    } else {
        return nil;
    }
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    if (_screenType == List_StudiedList ||
       _screenType == List_SearchHint ||
       _screenType == List_SearchResult) {
        
        UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
        
        header.textLabel.textColor = [UIColor whiteColor];
        header.textLabel.font = [UIFont boldSystemFontOfSize:15];
        CGRect headerFrame = header.frame;
        header.textLabel.frame = headerFrame;
        header.textLabel.textAlignment = NSTextAlignmentLeft;
        
        header.backgroundView.backgroundColor = [UIColor darkGrayColor];
        
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    // If you're serving data from an array, return the length of the array:
    if (_screenType == List_StudiedList ||
        _screenType == List_SearchHint ||
        _screenType == List_SearchResult) {
        
        if (section < [keyArr count]) {
            NSString *key = [keyArr objectAtIndex:section];
            
            return [[levelsDictionary objectForKey:key] count];
        } else {
            return 0;
        }
        
    } else {
        return [wordList count];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *studiedCellIdentifier = @"StudiedTableViewCell";
    
    StudiedTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:studiedCellIdentifier];
    if (cell == nil) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"StudiedTableViewCell" owner:nil options:nil];
        cell = [nib objectAtIndex:0];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }

    cell.delegate = (id)self;
    
    WordObject *wordObj = nil;
    
    if (_screenType == List_StudiedList ||
        _screenType == List_SearchHint ||
        _screenType == List_SearchResult) {
        NSString *key = [keyArr objectAtIndex:indexPath.section];
        
        NSArray *arrWords = [levelsDictionary objectForKey:key];
        wordObj = [arrWords objectAtIndex:indexPath.row];
        
    } else {
        wordObj = [wordList objectAtIndex:indexPath.row];
    }
    
    //parse the answer to dictionary object
    NSData *data = [wordObj.answers dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *dictAnswer = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    NSString *strPronounciation = [dictAnswer valueForKey:@"pronoun"];
    
    //A word may has many meanings corresponding to many fields (common, it, economic...)
    //The meaning of each field is considered as a package
    NSDictionary *dictPackages = [dictAnswer valueForKey:@"packages"];
    
    NSString *curMajor = [[Common sharedCommon] loadDataFromUserDefaultStandardWithKey:KEY_SELECTED_MAJOR];
    
    if (curMajor == nil || curMajor.length == 0) {
        curMajor = @"common";
    }
    
    curMajor = [curMajor lowercaseString];
    
    NSDictionary *dictSinglePackage = [dictPackages valueForKey:curMajor];
    
    if (dictSinglePackage == nil) {
        dictSinglePackage = [dictPackages valueForKey:@"common"];
    }
    
    //"common":{"meaning":"", "explain":"<p>The edge of something is the part of it that is farthest from the center.</p>", "example":"<p>He ran to the edge of the cliff.</p>"}}
    
    NSString *strMeaning = [dictSinglePackage valueForKey:@"meaning"];
//    strMeaning = [[Common sharedCommon] stringByRemovingHTMLTag:strMeaning];
    
    cell.lbWord.text = wordObj.question;
    cell.lbPronounce.text = strPronounciation;
//    cell.lbMeaning.text = strMeaning;
    
    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithData:[strMeaning dataUsingEncoding:NSUnicodeStringEncoding] options:@{ NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType } documentAttributes:nil error:nil];
    
    cell.lbMeaning.attributedText = attributedString;
    cell.lbMeaning.font = [UIFont systemFontOfSize:15];
    return cell;
}

//- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
//    if (_screenType == List_Incoming) {
//        return YES;
//    }
//    
//    return NO;
//
//}
//
//- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    if (_screenType == List_Incoming) {
//        return UITableViewCellEditingStyleDelete;
//    }
//    
//    return UITableViewCellEditingStyleNone;
//}

#pragma mark table delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    WordObject *wordObj = nil;
    
    if (_screenType == List_StudiedList ||
        _screenType == List_SearchHint ||
        _screenType == List_SearchResult) {
        NSString *key = [keyArr objectAtIndex:indexPath.section];
        
        NSArray *arrWords = [levelsDictionary objectForKey:key];
        wordObj = [arrWords objectAtIndex:indexPath.row];
        
    } else {
        wordObj = [wordList objectAtIndex:indexPath.row];
    }
    
    if (_screenType == List_SearchHint) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"didSelectRowFromSearch" object:wordObj];
        
    } else {
/*        StudyWordViewController *studyViewController = [[StudyWordViewController alloc] initWithNibName:@"StudyWordViewController" bundle:nil];
        studyViewController.isReviewScreen = YES;
        studyViewController.wordObj = wordObj;
        
        [self.navigationController pushViewController:studyViewController animated:YES];*/
        
        DictDetailContainerViewController *dictDetailContainer = [[DictDetailContainerViewController alloc] initWithNibName:@"DictDetailContainerViewController" bundle:nil];
        dictDetailContainer.wordObj = wordObj;
        
        [self.navigationController pushViewController:dictDetailContainer animated:YES];
    }

}

//- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    
//}

- (void)tableReload {
    [wordList removeAllObjects];
    [levelsDictionary removeAllObjects];
    
    if (_screenType == List_Incoming) {
        [wordList addObjectsFromArray:[[CommonSqlite sharedCommonSqlite] getIncomingList]];
        
    } else if (_screenType == List_StudiedList) {
        [wordList addObjectsFromArray:[[CommonSqlite sharedCommonSqlite] getStudiedList]];
        
    } else if (_screenType == List_SearchHint) {
        [wordList addObjectsFromArray:[[CommonSqlite sharedCommonSqlite] getSearchHintList:_searchText]];
        
        if ([wordList count] == 0) {
            [self.view removeFromSuperview];
        }
        
    } else if (_screenType == List_SearchResult) {
        [wordList addObjectsFromArray:[[CommonSqlite sharedCommonSqlite] getSearchResultList:_searchText]];
        
        if ([wordList count] == 0) {
            [self searchOnServer];
        }
    }
    
    if (_screenType != List_Incoming) {
        //group by level
        for (WordObject *wordObj in wordList) {
            NSMutableArray *arr = [levelsDictionary objectForKey:wordObj.level];
            
            if (arr == nil) {
                arr = [[NSMutableArray alloc] init];
            }
            [arr addObject:wordObj];
            
            [levelsDictionary setObject:arr forKey:wordObj.level];
        }
        
        keyArr = [levelsDictionary allKeys];
        keyArr = [keyArr sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    }
    
    lbHeaderInfo.text = [NSString stringWithFormat:@"Total: %lu", (unsigned long)[wordList count]];
        
    
    [wordsTableView reloadData];
}

- (void)refreshList {
    if (_screenType == List_Incoming) {
        [self tableReload];
    }
}

- (void)searchOnServer {
    if ([[Common sharedCommon] networkIsActive]) {
        static GTLServiceDataServiceApi *service = nil;
        if (!service) {
            service = [[GTLServiceDataServiceApi alloc] init];
            service.retryEnabled = YES;
            //[GTMHTTPFetcher setLoggingEnabled:YES];
        }
        
        [SVProgressHUD showWithStatus:nil];
        GTLQueryDataServiceApi *query = [GTLQueryDataServiceApi queryForGetVocaByQWithQ:_searchText];
        //TODO: Add waiting progress here
        [service executeQuery:query completionHandler:^(GTLServiceTicket *ticket, GTLDataServiceApiVoca *object, NSError *error) {
            if (object != nil){
                NSLog(object.JSONString);
                //TODO: Update word: q, a, level, package, (and ee, ev)
                WordObject *wordObj = [[WordObject alloc] init];
                wordObj.question   = object.q;
                wordObj.answers    = object.a;
                wordObj.level      = object.level;
                wordObj.package    = object.packages;
                wordObj.gid        = [NSString stringWithFormat:@"%@", object.gid];
                
                if (object.lEn && object.lEn.length > 0) {
                    wordObj.langEN     = object.lEn;
                }
                
                if (object.lVn && object.lVn.length > 0) {
                    wordObj.langVN     = object.lVn;
                }
                
                wordObj.package    = object.packages;
                wordObj.eFactor    = @"2500";
                wordObj.queue      = @"0";
                wordObj.isFromServer = YES;

                [wordList addObject:wordObj];
                
                //group by level
                for (WordObject *wordObj in wordList) {
                    NSMutableArray *arr = [levelsDictionary objectForKey:wordObj.level];
                    
                    if (arr == nil) {
                        arr = [[NSMutableArray alloc] init];
                    }
                    [arr addObject:wordObj];
                    
                    [levelsDictionary setObject:arr forKey:wordObj.level];
                    
                    keyArr = [levelsDictionary allKeys];
                    keyArr = [keyArr sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
                }
                
                lbHeaderInfo.text = [NSString stringWithFormat:@"Total: %lu", (unsigned long)[wordList count]];
                [wordsTableView reloadData];
                
                [SVProgressHUD dismiss];
                
            } else {
                [SVProgressHUD dismiss];
            }
            
            if ([wordList count] == 0) {
                viewNoresult.hidden = NO;
                lbNoresult.text = [NSString stringWithFormat:@"No result for \"%@\"\nWe will update soon.", _searchText];
            } else {
                viewNoresult.hidden = YES;
            }
        }];
    }
}

#pragma mark swipe delegate
//-(BOOL) swipeTableCell:(MGSwipeTableCell*) cell canSwipe:(MGSwipeDirection) direction;
//{
//    if (_screenType == MyAlbumScreen) {
//        return NO;
//
//    } else {
//        return YES;
//    }
//}

-(NSArray*) swipeTableCell:(StudiedTableViewCell*) cell swipeButtonsForDirection:(MGSwipeDirection)direction
             swipeSettings:(MGSwipeSettings*) swipeSettings expansionSettings:(MGSwipeExpansionSettings*) expansionSettings
{
    if (_screenType == List_Incoming) {
        swipeSettings.transition = MGSwipeTransitionStatic;
        
        if (direction == MGSwipeDirectionRightToLeft) {
            expansionSettings.fillOnTrigger = NO;
            expansionSettings.threshold = 1.1;

            MGSwipeButton *btnDone = nil;

            btnDone = [MGSwipeButton buttonWithTitle:@"Done" backgroundColor:BLUE_COLOR padding:20 callback:^BOOL(MGSwipeTableCell *sender) {
                
                return NO;
            }];
            
            MGSwipeButton *btnIgnore = nil;
            
            btnIgnore = [MGSwipeButton buttonWithTitle:@"Ignore" backgroundColor:[UIColor lightGrayColor] padding:20 callback:^BOOL(MGSwipeTableCell *sender) {
                
                return NO;
            }];

            return @[btnDone, btnIgnore];
        }
        
    }
    
    return nil;
}

-(BOOL) swipeTableCell:(StudiedTableViewCell*) cell tappedButtonAtIndex:(NSInteger) index direction:(MGSwipeDirection)direction fromExpansion:(BOOL) fromExpansion
{
    if (_screenType == List_Incoming) {
        WordObject *wordObj = nil;
        NSIndexPath *indexPath = [wordsTableView indexPathForCell:cell];
        if (direction == MGSwipeDirectionRightToLeft && index == 0) {   //Done
            NSLog(@"Done");
            //update queue value in DB
            indexPath = [wordsTableView indexPathForCell:cell];
            wordObj = [wordList objectAtIndex:indexPath.row];
            
            wordObj.queue = [NSString stringWithFormat:@"%d", QUEUE_DONE];
            
        } else if (direction == MGSwipeDirectionRightToLeft && index == 1) {   //Ignore
            NSLog(@"Ignore");
            //update queue value in DB
            indexPath = [wordsTableView indexPathForCell:cell];
            wordObj = [wordList objectAtIndex:indexPath.row];
            
            wordObj.queue = [NSString stringWithFormat:@"%d", QUEUE_SUSPENDED];
        }
        
        if (wordList) {
            [[CommonSqlite sharedCommonSqlite] updateWord:wordObj];
            
            //remove from buffer
            [[CommonSqlite sharedCommonSqlite] removeWordFromBuffer:wordObj];
            
            [wordList removeObject:wordObj];
            
            lbHeaderInfo.text = [NSString stringWithFormat:@"Total: %lu", (unsigned long)[wordList count]];
            [wordsTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        }
    }
    
    return NO;  //Don't autohide
}

- (void)changeMajor {
    if (_screenType == List_Incoming) {
        [self prepareWordsToStudyingQueue];
        
        [self tableReload];
    }
}

- (void)prepareWordsToStudyingQueue {
    NSString *curMajor = [[Common sharedCommon] loadDataFromUserDefaultStandardWithKey:KEY_SELECTED_MAJOR];
    
    if (curMajor == nil || curMajor.length == 0) {
        curMajor = @"common";
    }
    [[CommonSqlite sharedCommonSqlite] prepareWordsToStudyingQueue:BUFFER_SIZE inPackage:curMajor];
}

- (void)refreshIncomingTable {
    [refreshControl endRefreshing];
    [self prepareWordsToStudyingQueue];
    [self tableReload];
}
@end
