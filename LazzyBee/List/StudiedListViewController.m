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
#import "MajorObject.h"
#import "LocalizeHelper.h"
#import "GTMHTTPFetcher.h"
#import "GTLDataServiceApi.h"
#import "AppDelegate.h"
#import "Algorithm.h"

#import "EditWordListViewController.h"

@import GoogleMobileAds;
@import FirebaseAnalytics;

@interface StudiedListViewController ()
{
    NSMutableDictionary *levelsDictionary;
    NSMutableArray *wordList;
    NSArray *keyArr;
    
    UIRefreshControl *refreshControl;
    
    IBOutlet GADBannerView *adBanner;
    IBOutlet UIView *viewHeaderContainer;
}
@end

@implementation StudiedListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [wordsTableView setKeyboardDismissMode:UIScrollViewKeyboardDismissModeOnDrag];
    
    //admob
    GADRequest *request = [GADRequest request];
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    TAGContainer *container = appDelegate.container;

    BOOL enableAds = YES;
    
    NSString *pub_id = [container stringForKey:@"admob_pub_id"];
    NSString *dictionary_id = [container stringForKey:@"adv_dictionary_id"];
    
    NSString *advStr = [NSString stringWithFormat:@"%@/%@", pub_id,dictionary_id ];
    
    adBanner.adUnitID = advStr;//@"ca-app-pub-3940256099942544/2934735716";
    
    adBanner.rootViewController = self;

//    request.testDevices = @[
//                            @"687f0b503566ebb7d84524c1f15e1d16",
//                            kGADSimulatorID
//                            ];
    
    [adBanner loadRequest:request];
    
    if (pub_id == nil || pub_id.length == 0 ||
        dictionary_id == nil || dictionary_id.length == 0 ||
        ![[Common sharedCommon] networkIsActive]) {
        enableAds = NO;
    }
    
    // Do any additional setup after loading the view from its nib.
    if (_screenType == List_Incoming) {
        [TagManagerHelper pushOpenScreenEvent:@"iIncomingScreen"];
        [FIRAnalytics logEventWithName:@"Open_iIncomingScreen" parameters:@{
                                                                                  kFIRParameterValue:@(1)
                                                                                  }];
        
        [self setTitle:LocalizedString(@"Incoming list")];
        
        refreshControl = [[UIRefreshControl alloc] init];
        refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:LocalizedString(@"Pull to re-fill")];
        [refreshControl addTarget:self action:@selector(refreshIncomingTable) forControlEvents:UIControlEventValueChanged];
        [wordsTableView addSubview:refreshControl];
        
        UIBarButtonItem *actionButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(showAddOptions:)];
        
        self.navigationItem.rightBarButtonItems = @[actionButton];
        
    } else if (_screenType == List_StudiedList) {
        [TagManagerHelper pushOpenScreenEvent:@"iLearntScreen"];
        [FIRAnalytics logEventWithName:@"Open_iLearntScreen" parameters:@{
                                                                            kFIRParameterValue:@(1)
                                                                            }];
        
        [self setTitle:LocalizedString(@"Learnt List")];
        
    } else if (_screenType == List_SearchHint) {
        [TagManagerHelper pushOpenScreenEvent:@"iSearchHintScreen"];
        [FIRAnalytics logEventWithName:@"Open_iSearchHintScreen" parameters:@{
                                                                          kFIRParameterValue:@(1)
                                                                          }];
        
    } else if (_screenType == List_SearchHintHome) {
        [self.view.layer setBorderColor:[[UIColor lightGrayColor] CGColor]];
        [self.view.layer setBorderWidth:1];
        
        [TagManagerHelper pushOpenScreenEvent:@"iSearchHintScreen"];
        [FIRAnalytics logEventWithName:@"Open_iSearchHintHomeScreen" parameters:@{
                                                                              kFIRParameterValue:@(1)
                                                                              }];
        
        [wordsTableView setKeyboardDismissMode:UIScrollViewKeyboardDismissModeNone];
        
        enableAds = NO;
        
    } else if (_screenType == List_SearchResult) {
        [TagManagerHelper pushOpenScreenEvent:@"iSearchResultScreen"];
        [FIRAnalytics logEventWithName:@"Open_iSearchResultScreen" parameters:@{
                                                                                  kFIRParameterValue:@(1)
                                                                                  }];
        
        [self setTitle:LocalizedString(@"Search Result")];
        
        refreshControl = [[UIRefreshControl alloc] init];
        [refreshControl addTarget:self action:@selector(refreshSearchResult) forControlEvents:UIControlEventValueChanged];
        [wordsTableView addSubview:refreshControl];
    }
    
    if (enableAds) {
        adBanner.hidden = NO;
        
        viewTableContainer.layer.masksToBounds = NO;
        viewTableContainer.layer.shadowOffset = CGSizeMake(0, 5);
        viewTableContainer.layer.shadowRadius = 5;
        viewTableContainer.layer.shadowOpacity = 0.5;
        
    } else {
        adBanner.hidden = YES;
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(dismissImportReport)
                                                 name:@"DismissImportReport"
                                               object:nil];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    if (_screenType == List_SearchHintHome ||
        _screenType == List_SearchHint) {
        CGRect tableRect = viewTableContainer.frame;
        CGRect headerRect = viewHeaderContainer.frame;
        CGRect adRect = adBanner.frame;
        
        tableRect.origin.x = headerRect.origin.x;
        tableRect.origin.y = headerRect.origin.y;
        tableRect.size.height = adRect.origin.y - 3; //offset for separating
        
        [viewTableContainer setFrame:tableRect];
    }
    
    if (adBanner.hidden == YES) {
        CGRect tableRect = viewTableContainer.frame;
        CGRect adRect = adBanner.frame;
        
        tableRect.size.height = adRect.origin.y + adRect.size.height - tableRect.origin.y;
        
        [viewTableContainer setFrame:tableRect];
    }
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
        _screenType == List_SearchHintHome ||
        _screenType == List_SearchResult) {
        return [[levelsDictionary allKeys] count];
        
    } else {
        return [[levelsDictionary allKeys] count];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    
    if (_screenType == List_StudiedList ||
        _screenType == List_SearchHint ||
        _screenType == List_SearchHintHome ||
        _screenType == List_SearchResult) {
        NSString *headerTitle = @"";
        
        if (section < [keyArr count]) {
            NSString *key = [keyArr objectAtIndex:section];
            
            headerTitle = [NSString stringWithFormat:@"%@ %@: %lu %@", LocalizedString(@"Level"), key, [[levelsDictionary objectForKey:key] count], LocalizedString(@"word")];
        }
        
        return headerTitle;
        
    } else {
        
        if ([keyArr count] > 1) {
            NSString *headerTitle = @"";
            NSString *key = [keyArr objectAtIndex:section];
            
            if (section == 0) {
                
                headerTitle = [NSString stringWithFormat:@"%@ : %lu %@", LocalizedString(@"Custom list"), [[levelsDictionary objectForKey:key] count], LocalizedString(@"word")];
                
            } else {
                headerTitle = [NSString stringWithFormat:@"%@ : %lu %@", LocalizedString(@"Normal list"), [[levelsDictionary objectForKey:key] count], LocalizedString(@"word")];
            }
            
            return headerTitle;
        } else {
            return nil;
        }
    }
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    if (_screenType == List_StudiedList ||
       _screenType == List_SearchHint ||
        _screenType == List_SearchHintHome ||
        _screenType == List_SearchResult ||
        _screenType == List_Incoming) {
        
        UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
        
        header.textLabel.textColor = [UIColor whiteColor];
        header.textLabel.font = [UIFont boldSystemFontOfSize:15];
        CGRect headerFrame = header.textLabel.frame;
        headerFrame.size.width = header.frame.size.width;
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
        _screenType == List_SearchHintHome ||
        _screenType == List_SearchResult ||
        _screenType == List_Incoming) {
        
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
    
    StudiedTableViewCell *cell = [wordsTableView dequeueReusableCellWithIdentifier:studiedCellIdentifier];
    if (cell == nil) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"StudiedTableViewCell" owner:nil options:nil];
        cell = [nib objectAtIndex:0];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }

    cell.delegate = (id)self;
    
    WordObject *wordObj = nil;
    
    if (_screenType == List_StudiedList ||
        _screenType == List_SearchHint ||
        _screenType == List_SearchHintHome ||
        _screenType == List_SearchResult) {
        NSString *key = [keyArr objectAtIndex:indexPath.section];
        
        NSArray *arrWords = [levelsDictionary objectForKey:key];
        wordObj = [arrWords objectAtIndex:indexPath.row];
        
        cell.lbLevel.hidden = YES;
        
        CGRect rect = cell.lbMeaning.frame;
        CGRect rectLbLevel = cell.lbLevel.frame;
        rect.size.width = rectLbLevel.origin.x + rectLbLevel.size.width;
        
        [cell.lbMeaning setFrame:rect];
        
        
    } else {
//        wordObj = [wordList objectAtIndex:indexPath.row];
        NSString *key = [keyArr objectAtIndex:indexPath.section];
        
        NSArray *arrWords = [levelsDictionary objectForKey:key];
        wordObj = [arrWords objectAtIndex:indexPath.row];
        
        cell.lbLevel.hidden = NO;
    }
    
    //parse the answer to dictionary object
    NSData *data = [wordObj.answers dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *dictAnswer = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    NSString *strPronounciation = [dictAnswer valueForKey:@"pronoun"];
    
    if ([strPronounciation isEqualToString:@"//"]) {
        strPronounciation = @"";
    }
    
    //A word may has many meanings corresponding to many fields (common, it, economic...)
    //The meaning of each field is considered as a package
    NSDictionary *dictPackages = [dictAnswer valueForKey:@"packages"];
    
    MajorObject *curMajorObj = (MajorObject *)[[Common sharedCommon] loadPersonalDataWithKey:KEY_SELECTED_MAJOR];
    
    NSString *curMajor = curMajorObj.majorName;
    
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
    
    cell.lbLevel.text = [NSString stringWithFormat:@"Level: %@", wordObj.level];
    
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
        _screenType == List_SearchHintHome ||
        _screenType == List_SearchResult) {
        NSString *key = [keyArr objectAtIndex:indexPath.section];
        
        NSArray *arrWords = [levelsDictionary objectForKey:key];
        wordObj = [arrWords objectAtIndex:indexPath.row];
        
    } else {
        NSString *key = [keyArr objectAtIndex:indexPath.section];
        
        NSArray *arrWords = [levelsDictionary objectForKey:key];
        wordObj = [arrWords objectAtIndex:indexPath.row];
        
//        wordObj = [wordList objectAtIndex:indexPath.row];
    }
    
    if (_screenType == List_SearchHint || _screenType == List_SearchHintHome) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"didSelectRowFromSearch" object:wordObj];
        
    } else {
/*        StudyWordViewController *studyViewController = [[StudyWordViewController alloc] initWithNibName:@"StudyWordViewController" bundle:nil];
        studyViewController.isReviewScreen = YES;
        studyViewController.wordObj = wordObj;
        
        [self.navigationController pushViewController:studyViewController animated:YES];*/
        
        DictDetailContainerViewController *dictDetailContainer = [[DictDetailContainerViewController alloc] initWithNibName:@"DictDetailContainerViewController" bundle:nil];
        dictDetailContainer.wordObj = wordObj;
        dictDetailContainer.showLazzyBeeTab = YES;
        
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
        
    } else if (_screenType == List_SearchHint || _screenType == List_SearchHintHome) {
        [wordList addObjectsFromArray:[[CommonSqlite sharedCommonSqlite] getSearchHintList:_searchText]];
        
        if ([wordList count] == 0) {
            [self.view removeFromSuperview];
        }
        
    } else if (_screenType == List_SearchResult) {
        [wordList addObjectsFromArray:[[CommonSqlite sharedCommonSqlite] getSearchResultList:_searchText]];
        
        if ([wordList count] == 0) {
            [self searchOnServer];
        } else {
            BOOL found = NO;
            for (WordObject *wordObj in wordList) {
                if ([[wordObj.question lowercaseString] isEqualToString:[_searchText lowercaseString]]) {
                    found = YES;
                    break;
                }
            }
            
            if (found ==  NO) {
                [self searchOnServer];
            }
        }
    }
    
    if (_screenType == List_Incoming) {
        //group by priority
        for (WordObject *wordObj in wordList) {
            NSMutableArray *arr = [levelsDictionary objectForKey:[NSString stringWithFormat:@"%ld", wordObj.priority]];
            
            if (arr == nil) {
                arr = [[NSMutableArray alloc] init];
            }
            [arr addObject:wordObj];
            
            [levelsDictionary setObject:arr forKey:[NSString stringWithFormat:@"%ld", wordObj.priority]];
        }
        
        keyArr = [levelsDictionary allKeys];
        NSSortDescriptor* sortOrder = [NSSortDescriptor sortDescriptorWithKey: @"self"
                                                                    ascending: NO];
        keyArr = [keyArr sortedArrayUsingDescriptors:@[sortOrder]];
        
    } else {
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
    
    lbHeaderInfo.text = [NSString stringWithFormat:@"%@: %lu", LocalizedString(@"Total"), (unsigned long)[wordList count]];
        
    
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
        
        [SVProgressHUD show];
        GTLQueryDataServiceApi *query = [GTLQueryDataServiceApi queryForGetVocaByQWithQ:_searchText];
        //TODO: Add waiting progress here
        [service executeQuery:query completionHandler:^(GTLServiceTicket *ticket, GTLDataServiceApiVoca *object, NSError *error) {
            if (object != nil){
//                NSLog(object.JSONString);
                //TODO: Update word: q, a, level, package, (and ee, ev)
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
                wordObj.eFactor    = @"2500";
//                wordObj.queue      = @"0";
//                wordObj.isFromServer = YES;   //set YES if dont insert this word to db right here //dont need to do this because we add it right here
                wordObj.queue = [NSString stringWithFormat:@"%d", QUEUE_UNKNOWN];
               
                //insert to db, no need to get from server next time
                [[CommonSqlite sharedCommonSqlite] insertWordToDatabase:wordObj];
                
                //because word-id is blank so need to get again after insert it into db
                wordObj = [[CommonSqlite sharedCommonSqlite] getWordInformation:wordObj.question];
                
                [wordList addObject:wordObj];
                
                //group by level
                [levelsDictionary removeAllObjects];
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
                
                lbHeaderInfo.text = [NSString stringWithFormat:@"%@: %lu", LocalizedString(@"Total"), (unsigned long)[wordList count]];
                [wordsTableView reloadData];
                
                [SVProgressHUD dismiss];
                
            } else {
                [SVProgressHUD dismiss];
            }
            
            if ([wordList count] == 0) {
                viewNoresult.hidden = NO;
                lbNoresult.text = [NSString stringWithFormat:LocalizedString(@"No result format"), _searchText];
                
                [FIRAnalytics logEventWithName:EVENT_SEARCH_NOT_FOUND parameters:@{
                                                                      kFIRParameterSearchTerm:_searchText
                                                                      }];
                                
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

            btnDone = [MGSwipeButton buttonWithTitle:LocalizedString(@"Done") backgroundColor:BLUE_COLOR padding:20 callback:^BOOL(MGSwipeTableCell *sender) {
                
                return NO;
            }];
            
            MGSwipeButton *btnIgnore = nil;
            
            btnIgnore = [MGSwipeButton buttonWithTitle:LocalizedString(@"Ignore") backgroundColor:[UIColor lightGrayColor] padding:20 callback:^BOOL(MGSwipeTableCell *sender) {
                
                return NO;
            }];

            return @[btnDone, btnIgnore];
        }
        
    } else if (_screenType == List_SearchResult ||
               _screenType == List_SearchHint ||
               _screenType == List_SearchHintHome) {
        swipeSettings.transition = MGSwipeTransitionStatic;
        
        if (direction == MGSwipeDirectionRightToLeft) {
            expansionSettings.fillOnTrigger = NO;
            expansionSettings.threshold = 1.1;
            
            MGSwipeButton *btnAdd = nil;
            
            btnAdd = [MGSwipeButton buttonWithTitle:LocalizedString(@"Add") backgroundColor:GREEN_COLOR padding:20 callback:^BOOL(MGSwipeTableCell *sender) {
                
                return NO;
            }];
            
            return @[btnAdd];
        }
    }
    
    return nil;
}

-(BOOL) swipeTableCell:(StudiedTableViewCell*) cell tappedButtonAtIndex:(NSInteger) index direction:(MGSwipeDirection)direction fromExpansion:(BOOL) fromExpansion
{
    if (_screenType == List_Incoming) {
        WordObject *wordObj = nil;
        NSIndexPath *indexPath = [wordsTableView indexPathForCell:cell];
        NSString *key = [keyArr objectAtIndex:indexPath.section];
        
        NSMutableArray *arrWords = [[NSMutableArray alloc] initWithArray:[levelsDictionary objectForKey:key]];
        wordObj = [arrWords objectAtIndex:indexPath.row];
        
        if (direction == MGSwipeDirectionRightToLeft && index == 0) {   //Done
            NSLog(@"Done");
            //update queue value in DB
            wordObj.queue = [NSString stringWithFormat:@"%d", QUEUE_DONE];
            
        } else if (direction == MGSwipeDirectionRightToLeft && index == 1) {   //Ignore
            NSLog(@"Ignore");
            //update queue value in DB
            wordObj.queue = [NSString stringWithFormat:@"%d", QUEUE_SUSPENDED];
        }
        

        [[CommonSqlite sharedCommonSqlite] updateWord:wordObj];
        
        //remove from buffer
        [[CommonSqlite sharedCommonSqlite] removeWordFromBuffer:wordObj];
        
        [wordList removeObject:wordObj];
        [arrWords removeObject:wordObj];
        
        [levelsDictionary setObject:arrWords forKey:key];
        
        lbHeaderInfo.text = [NSString stringWithFormat:@"%@: %lu", LocalizedString(@"Total"), (unsigned long)[wordList count]];
        [wordsTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        
        UITableViewHeaderFooterView *header = [wordsTableView headerViewForSection:indexPath.section];
        
        if (indexPath.section == 0) {
            
            header.textLabel.text = [NSString stringWithFormat:@"%@ : %lu %@", LocalizedString(@"Custom list"), [[levelsDictionary objectForKey:key] count], LocalizedString(@"word")];
            
        } else {
            header.textLabel.text = [NSString stringWithFormat:@"%@ : %lu %@", LocalizedString(@"Normal list"), [[levelsDictionary objectForKey:key] count], LocalizedString(@"word")];
            
        }
        
        CGRect headerFrame = header.textLabel.frame;
        headerFrame.size.width = header.frame.size.width;
        header.textLabel.frame = headerFrame;
        
    } else if (_screenType == List_SearchResult ||
               _screenType == List_SearchHint ||
               _screenType == List_SearchHintHome) {
        NSLog(@"Add to learn");
        WordObject *wordObj = nil;
        NSIndexPath *indexPath = [wordsTableView indexPathForCell:cell];
        
        indexPath = [wordsTableView indexPathForCell:cell];
        wordObj = [wordList objectAtIndex:indexPath.row];
        
        //update queue value to 3 to consider this word as a new word in DB
        //wordObj.queue = [NSString stringWithFormat:@"%d", QUEUE_AGAIN];     //call [[Algorithm sharedAlgorithm] updateWord] instead of
        
        if (wordObj.isFromServer) {
            [[CommonSqlite sharedCommonSqlite] insertWordToDatabase:wordObj];
            
            //because word-id is blank so need to get again after insert it into db
            wordObj = [[CommonSqlite sharedCommonSqlite] getWordInformation:wordObj.question];
            
        //    [[CommonSqlite sharedCommonSqlite] addAWordToStydyingQueue:wordObj];
            
        } else {
        //    [[CommonSqlite sharedCommonSqlite] addAWordToStydyingQueue:wordObj];
            
            //remove from buffer
            [[CommonSqlite sharedCommonSqlite] removeWordFromBuffer:wordObj];
            
            [[Algorithm sharedAlgorithm] updateWord:wordObj withEaseLevel:EASE_AGAIN];

            
            [[CommonSqlite sharedCommonSqlite] updateWord:wordObj];
        }
        
        //update incoming list
        [[NSNotificationCenter defaultCenter] postNotificationName:@"AddToLearn" object:wordObj];
        
        [SVProgressHUD showSuccessWithStatus:LocalizedString(@"Added")];
        
        return YES;
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
    MajorObject *curMajorObj = (MajorObject *)[[Common sharedCommon] loadPersonalDataWithKey:KEY_SELECTED_MAJOR];
    
    NSString *curMajor = curMajorObj.majorName;
    
    if (curMajor == nil || curMajor.length == 0) {
        curMajor = @"common";
        
    } else {
        curMajor = [curMajor lowercaseString];
    }
    [[CommonSqlite sharedCommonSqlite] prepareWordsToStudyingQueue:BUFFER_SIZE inPackage:curMajor];
}

- (void)refreshIncomingTable {
    [refreshControl endRefreshing];
    [self prepareWordsToStudyingQueue];
    [self tableReload];
}

- (void)refreshSearchResult {
    [refreshControl endRefreshing];
    [self tableReload];
}

#pragma mark add custom list
- (void)showAddOptions:(id)sender {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:LocalizedString(@"Import custom list") delegate:(id)self cancelButtonTitle:LocalizedString(@"Cancel") destructiveButtonTitle:nil otherButtonTitles:LocalizedString(@"Create new list"), LocalizedString(@"Import from existed list"), nil];

    
    actionSheet.tag = 1;
    actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;

    if (IS_IPAD) {
        [actionSheet showFromBarButtonItem:sender animated:YES];
    } else {
        [actionSheet showInView:self.view];
    }
}

- (void) actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (actionSheet.tag == 1) {
        if (buttonIndex == 0) {			
            NSLog(@"Create new list");
            dispatch_queue_t taskQ = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
            dispatch_async(taskQ, ^{
                
                dispatch_sync(dispatch_get_main_queue(), ^{
                    EditWordListViewController *createView = [[EditWordListViewController alloc] initWithNibName:@"EditWordListViewController" bundle:nil];
                    createView.wordsArray = nil;
                    
                    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:createView];
                    [nav setModalPresentationStyle:UIModalPresentationFormSheet];
                    [nav setModalTransitionStyle:UIModalTransitionStyleCrossDissolve];
                    
                    [self.navigationController presentViewController:nav animated:YES completion:nil];
                });
            });
            
        } else if (buttonIndex == 1) {
            NSLog(@"Add from existed list");
            
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:LocalizedString(@"Enter code")
                                                                message:LocalizedString(@"Enter the code that you received when creating the custom word list by web browser")
                                                               delegate:self
                                                      cancelButtonTitle:LocalizedString(@"Cancel")
                                                      otherButtonTitles:LocalizedString(@"OK"), nil];
            
            alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
            UITextField * alertTextField = [alertView textFieldAtIndex:0];
            alertTextField.keyboardType = UIKeyboardTypeNumberPad;
            
            alertView.tag = 1;
            [alertView show];
            
        } else {
            NSLog(@"Cancel");
        }
    }
}

#pragma mark alert delegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (alertView.tag == 1) {
        if (buttonIndex != 0) {
            UITextField *textField = [alertView textFieldAtIndex:0];
            
            if ([[Common sharedCommon] networkIsActive]) {
                [self downloadWordListFromServerWithCode:textField.text];
                
            } else {
                [self noConnectionAlert];
            }
        }
    }
    
    return;
}

- (void)downloadWordListFromServerWithCode:(NSString *)stringCode {
    [SVProgressHUD show];
    
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
            long long code = [stringCode integerValue];
            
            if (code != 0) {
                GTLQueryDataServiceApi *query = [GTLQueryDataServiceApi queryForGetGroupVocaWithIdentifier:code];
                //TODO: Add waiting progress here
                [service executeQuery:query completionHandler:^(GTLServiceTicket *ticket, GTLDataServiceApiGroupVoca *object, NSError *error) {
                    if (object){
                        NSString *wordsString  = object.listVoca;
                        
                        NSArray *wordsArr = [wordsString componentsSeparatedByString:@"\n"];
                        
                        if ([wordsArr count] > 0) {
                            EditWordListViewController *createView = [[EditWordListViewController alloc] initWithNibName:@"EditWordListViewController" bundle:nil];
                            createView.wordsArray = wordsArr;
                            
                            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:createView];
                            [nav setModalPresentationStyle:UIModalPresentationFormSheet];
                            [nav setModalTransitionStyle:UIModalTransitionStyleCrossDissolve];
                            
                            [self.navigationController presentViewController:nav animated:YES completion:nil];
                            
                        } else {
                            [self noWordFoundAlert];
                        }
                        
                        [SVProgressHUD dismiss];
                        
                    } else {
                        [self wrongCodeAlert];
                        [SVProgressHUD dismiss];
                    }
                }];
                
            } else {
                [self wrongCodeAlert];
                [SVProgressHUD dismiss];
            }
            
        });
    });
}

- (void)wrongCodeAlert {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:LocalizedString(@"Failed") message:LocalizedString(@"Wrong code, please try again") delegate:(id)self cancelButtonTitle:LocalizedString(@"Cancel") otherButtonTitles:LocalizedString(@"Try again"), nil];
    alert.tag = 2;
    
    [alert show];
}

- (void)noWordFoundAlert {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:LocalizedString(@"Attention") message:LocalizedString(@"There is no word in the custom list.") delegate:(id)self cancelButtonTitle:LocalizedString(@"OK") otherButtonTitles:nil];
    alert.tag = 3;
    
    [alert show];
}

- (void)noConnectionAlert {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:LocalizedString(@"No connection") message:LocalizedString(@"Please double check wifi/3G connection") delegate:(id)self cancelButtonTitle:LocalizedString(@"OK") otherButtonTitles:nil];
    alert.tag = 4;
    
    [alert show];
}

- (void)dismissImportReport {
    if (_screenType == List_Incoming) {
        [self prepareWordsToStudyingQueue];
        [self tableReload];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
