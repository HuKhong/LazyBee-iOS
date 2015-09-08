//
//  StudyWordViewController.m
//  LazzyBee
//
//  Created by HuKhong on 8/20/15.
//  Copyright (c) 2015 Born2go. All rights reserved.
//

#import "StudyWordViewController.h"
#import "CommonSqlite.h"
#import "HTMLHelper.h"
#import "SearchViewController.h"
#import "StudiedListViewController.h"
#import "AppDelegate.h"
#import "CommonDefine.h"
#import "Algorithm.h"

@interface StudyWordViewController ()
{
    SearchViewController *searchView;
}
@end

@implementation StudyWordViewController
@synthesize studyScreenMode = _studyScreenMode;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    if (_isReviewScreen == YES) {
        UIBarButtonItem *actionButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(showActionsPanel)];
        
        self.navigationItem.rightBarButtonItems = @[actionButton];
        
        if (_wordObj) {
            [self displayAnswer:_wordObj];
            
            //hide buttons panel and "show answer" panel, expand webview full screen
            viewButtonsPanel.hidden = YES;
            viewShowAnswer.hidden = YES;
            
            CGRect mainRect = [UIScreen mainScreen].bounds;
            CGRect adsViewRect = viewReservationForAds.frame;
            CGRect webViewRect = webViewWord.frame;
            
            webViewRect.origin.y = 0;
            webViewRect.size.height = mainRect.size.height - adsViewRect.size.height;
            [webViewWord setFrame:webViewRect];
            
            adsViewRect.origin.y = webViewRect.size.height;
            [viewReservationForAds setFrame:adsViewRect];
            
            //show word
            [self displayAnswer:_wordObj];
        }
        
    } else {
        UIBarButtonItem *searchButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(showSearchBar)];
        UIBarButtonItem *actionButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(showActionsPanel)];
        
        self.navigationItem.rightBarButtonItems = @[actionButton, searchButton];
        
        NSString *title = @"Study";
        if (_studyScreenMode == Mode_New_Word) {
            title = @"New Word";
        } else if (_studyScreenMode == Mode_Study) {
            title = @"Study Again";
        } else if (_studyScreenMode == Mode_Review) {
            title = @"Review";
        }
        
        [self setTitle:title];
        
        //move buttons panel from the screen
        [self showHideButtonsPanel:NO];
        
        //init words list
        _nwordList = [[NSMutableArray alloc] init];
        _studyAgainList = [[NSMutableArray alloc] init];
        _reviewWordList = [[NSMutableArray alloc] init];
        
        [_nwordList addObjectsFromArray:[[CommonSqlite sharedCommonSqlite] getNewWordsList]];
        [_studyAgainList addObjectsFromArray:[[CommonSqlite sharedCommonSqlite] getStudyAgainList]];
        [_reviewWordList addObjectsFromArray:[[CommonSqlite sharedCommonSqlite] getReviewList]];
        
        [self updateHeaderInfo];
        
        _wordObj = [self getAWordFromCurrentList:nil];
        if (_wordObj) {
            [self displayQuestion:_wordObj];
            
            [self showHideButtonsPanel:NO];
        } else {
            [self.navigationController popViewControllerAnimated:YES];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"noWordToStudyToday" object:nil];
        }
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(searchBarSearchButtonClicked:)
                                                     name:@"searchBarSearchButtonClicked"
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didSelectRowFromSearch:)
                                                     name:@"didSelectRowFromSearch"
                                                   object:nil];
    }
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

- (void)setStudyScreenMode:(STUDY_SCREEN_MODE)studyScreenMode {
    _studyScreenMode = studyScreenMode;
    
    NSString *title = @"Study";
    if (_studyScreenMode == Mode_New_Word) {
        title = @"New Word";
    } else if (_studyScreenMode == Mode_Study) {
        title = @"Study Again";
    } else if (_studyScreenMode == Mode_Review) {
        title = @"Review";
    }
    
    [self setTitle:title];
}

- (void)showSearchBar {
    searchView = [[SearchViewController alloc] initWithNibName:@"SearchViewController" bundle:nil];
    
    searchView.view.alpha = 0;
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    CGRect rect = appDelegate.window.frame;
    [searchView.view setFrame:rect];
    
    [appDelegate.window addSubview:searchView.view];
    
    [UIView animateWithDuration:0.3 animations:^(void) {
        searchView.view.alpha = 1;
    }];
}

- (void)showActionsPanel {
    if (_isReviewScreen) {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:(id)self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Add to study" otherButtonTitles: nil];
        
        actionSheet.tag = 1;
        actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
        [actionSheet showInView:self.view];
        
    } else {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:(id)self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Ignore this word" otherButtonTitles: nil];
        
        actionSheet.tag = 2;
        actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
        [actionSheet showInView:self.view];
    }
}

- (void)showHideButtonsPanel:(BOOL)show {
    //update buttons's title
    NSArray *arrTitle = [[Algorithm sharedAlgorithm] nextIvlStrLst:_wordObj];
    
    [btnAgain setTitle:[NSString stringWithFormat:@"%@\n(Again)", [arrTitle objectAtIndex:0]] forState:UIControlStateNormal];
    [btnHard setTitle:[NSString stringWithFormat:@"%@\n(Hard)", [arrTitle objectAtIndex:1]] forState:UIControlStateNormal];
    [btnNorm setTitle:[NSString stringWithFormat:@"%@\n(Norm)", [arrTitle objectAtIndex:2]] forState:UIControlStateNormal];
    [btnEasy setTitle:[NSString stringWithFormat:@"%@\n(Easy)", [arrTitle objectAtIndex:3]] forState:UIControlStateNormal];
    
    [UIView animateWithDuration:0.3 animations:^(void) {
        CGRect mainRect = [UIScreen mainScreen].bounds;
        CGRect showAnswerrect = viewShowAnswer.frame;
        CGRect buttonsPanelRect = viewButtonsPanel.frame;
        
        if (show) {
            //overlap showAnswer panel
            buttonsPanelRect.origin.y = showAnswerrect.origin.y;
        } else {
            //move buttons panel from the screen
            buttonsPanelRect.origin.y = mainRect.size.height;
        }
        
        [viewButtonsPanel setFrame:buttonsPanelRect];
    }];
}

- (void)displayQuestion:(WordObject *)wordObj {
    //display question
    NSString *path = [[NSBundle mainBundle] bundlePath];
    NSURL *baseURL = [NSURL fileURLWithPath:path];
    
    NSString *htmlString = @"";
    
    if (wordObj) {
        htmlString = [[HTMLHelper sharedHTMLHelper]createHTMLForQuestion:wordObj.question];
    }
    
    [webViewWord loadHTMLString:htmlString baseURL:baseURL];
}

- (void)displayAnswer:(WordObject *)wordObj {
    //display question
    NSString *path = [[NSBundle mainBundle] bundlePath];
    NSURL *baseURL = [NSURL fileURLWithPath:path];

    NSString *htmlString = @"";
    
    if (wordObj) {
        htmlString = [[HTMLHelper sharedHTMLHelper]createHTMLForAnswer:wordObj withPackage:@"common"];
    }
    
    [webViewWord loadHTMLString:htmlString baseURL:baseURL];
}

//only need to check sender in case click on Again button
- (WordObject *)getAWordFromCurrentList:(id)sender {
    WordObject *res = nil;
    //remove the old word from array
    if (_studyScreenMode == Mode_New_Word) {
        if (_wordObj) {
            [_nwordList removeObject:_wordObj];
            
            //update pickedword field
            [[CommonSqlite sharedCommonSqlite] updatePickedWordList:_nwordList];
        }

    } else if (_studyScreenMode == Mode_Study) {
        if (_wordObj) {
            [_studyAgainList removeObject:_wordObj];
            
            if ([sender isEqual:btnAgain]) {
                [_studyAgainList addObject:_wordObj];
            }
        }
        
    } else if (_studyScreenMode == Mode_Review) {
        if (_wordObj) {
            [_reviewWordList removeObject:_wordObj];
        }
    }
    
    //check if the list is not empty
    if ([_studyAgainList count] > 0) {
        self.studyScreenMode = Mode_Study;
        
    } else if ([_reviewWordList count] > 0) {
        self.studyScreenMode = Mode_Review;
        
    } else if ([_nwordList count] > 0) {
        self.studyScreenMode = Mode_New_Word;
    } else {
        return nil; //back to home in this case
    }
    
    //switch screen mode
    if (_studyScreenMode == Mode_New_Word) {
        res = [_nwordList objectAtIndex:0];
        
    } else if (_studyScreenMode == Mode_Study) {
        res = [_studyAgainList objectAtIndex:0];
        
    } else if (_studyScreenMode == Mode_Review) {
        res = [_reviewWordList objectAtIndex:0];
    }
    
    [self updateHeaderInfo];
    
    return res;
}

#pragma mark buttons handle
- (IBAction)btnShowAnswerClick:(id)sender {
    if (_wordObj) {
        [self displayAnswer:_wordObj];
        [self showHideButtonsPanel:YES];
    }
}

- (IBAction)btnAgainClick:(id)sender {
    //update word and update db
    if (_wordObj) {
        [[Algorithm sharedAlgorithm] updateWord:_wordObj withEaseLevel:EASE_AGAIN];
        
        [[CommonSqlite sharedCommonSqlite] updateWord:_wordObj];
    }
    
    //show next word
    _wordObj = [self getAWordFromCurrentList:sender];
    
    if (_wordObj) {
        [self displayQuestion:_wordObj];
        
        [self showHideButtonsPanel:NO];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"completedDailyTarget" object:nil];
    }
}

- (IBAction)btnHardClick:(id)sender {
    //update word and update db
    if (_wordObj) {
        [[Algorithm sharedAlgorithm] updateWord:_wordObj withEaseLevel:EASE_HARD];
        
        [[CommonSqlite sharedCommonSqlite] updateWord:_wordObj];
    }
    
    //show next word
    _wordObj = [self getAWordFromCurrentList:sender];
    
    if (_wordObj) {
        [self displayQuestion:_wordObj];
        
        [self showHideButtonsPanel:NO];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"completedDailyTarget" object:nil];
    }
}

- (IBAction)btnNormClick:(id)sender {
    //update word and update db
    if (_wordObj) {
        [[Algorithm sharedAlgorithm] updateWord:_wordObj withEaseLevel:EASE_GOOD];
        
        [[CommonSqlite sharedCommonSqlite] updateWord:_wordObj];
    }
    
    //show next word
    _wordObj = [self getAWordFromCurrentList:sender];
    
    if (_wordObj) {
        [self displayQuestion:_wordObj];
        
        [self showHideButtonsPanel:NO];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"completedDailyTarget" object:nil];
    }
}

- (IBAction)btnEasyClick:(id)sender {
    //update word and update db
    if (_wordObj) {
        [[Algorithm sharedAlgorithm] updateWord:_wordObj withEaseLevel:EASE_EASY];
        
        [[CommonSqlite sharedCommonSqlite] updateWord:_wordObj];
    }
    
    //show next word
    _wordObj = [self getAWordFromCurrentList:sender];
    
    if (_wordObj) {
        [self displayQuestion:_wordObj];
        
        [self showHideButtonsPanel:NO];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"completedDailyTarget" object:nil];
    }
}

- (void)updateHeaderInfo {
    lbNewCount.text = [NSString stringWithFormat:@"New: %ld", [_nwordList count]];
    lbAgainCount.text = [NSString stringWithFormat:@"Again: %ld", [_studyAgainList count]];
    lbReviewCount.text = [NSString stringWithFormat:@"Review: %ld", [_reviewWordList count]];
}

#pragma mark actions sheet handle
- (void) actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (actionSheet.tag == 1) {
        if (buttonIndex == 0) {
            NSLog(@"Add to study");
            [[CommonSqlite sharedCommonSqlite] addAWordToStydyingQueue:_wordObj];
            
        } else if (buttonIndex == 3) {
            NSLog(@"Cancel");
        }
    } else if (actionSheet.tag == 2) {
        if (buttonIndex == 0) {
            NSLog(@"ignore this word");
            //update queue value in DB
            _wordObj.queue = @"-2";
            [[CommonSqlite sharedCommonSqlite] updateWord:_wordObj];
            
            //remove this word from list, display the next one
            _wordObj = [self getAWordFromCurrentList:nil];
            
            if (_wordObj) {
                [self displayQuestion:_wordObj];
                
                [self showHideButtonsPanel:NO];
            } else {
                [self.navigationController popViewControllerAnimated:YES];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:@"completedDailyTarget" object:nil];
            }
            
        } else if (buttonIndex == 3) {
            NSLog(@"Cancel");
        }
    }
    
}

#pragma mark handle notification
- (void)didSelectRowFromSearch:(NSNotification *)notification {
    
    if ([self.navigationController.topViewController isEqual:self]) {
        WordObject *wordObj = (WordObject *)notification.object;
        
        StudyWordViewController *studyViewController = [[StudyWordViewController alloc] initWithNibName:@"StudyWordViewController" bundle:nil];
        studyViewController.isReviewScreen = YES;
        studyViewController.wordObj = wordObj;
        
        [self.navigationController pushViewController:studyViewController animated:YES];
    }
}


- (void)searchBarSearchButtonClicked:(NSNotification *)notification {
    NSString *text = (NSString *)notification.object;
    if ([self.navigationController.topViewController isEqual:self]) {
        StudiedListViewController *searchResultViewController = [[StudiedListViewController alloc] initWithNibName:@"StudiedListViewController" bundle:nil];
        searchResultViewController.screenType = List_SearchResult;
        searchResultViewController.searchText = text;
        
        [self.navigationController pushViewController:searchResultViewController animated:YES];
    }
}

@end