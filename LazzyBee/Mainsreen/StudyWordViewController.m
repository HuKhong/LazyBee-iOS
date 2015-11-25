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
#import "ReportViewController.h"
#import "AppDelegate.h"
#import "CommonDefine.h"
#import "Algorithm.h"
#import "Common.h"
#import "TagManagerHelper.h"
#import "SVProgressHUD.h"
#import "DictDetailContainerViewController.h"
#import "NoteThumbnail.h"
#import "NoteFullView.h"

#define AS_TAG_SEARCH 1
#define AS_TAG_LEARN 2

#define AS_SEARCH_BTN_ADD_TO_LEARN  0
#define AS_SEARCH_BTN_REPORT        1
#define AS_SEARCH_BTN_CANCEL        2

#define AS_LEARN_BTN_IGNORE_WORD   0
#define AS_LEARN_BTN_LEARNT_WORD  1
#define AS_LEARN_BTN_DICTIONARY  2
#define AS_LEARN_BTN_UPDATE_WORD   3
#define AS_LEARN_BTN_REPORT_WORD   4
#define AS_LEARN_BTN_CANCEL        5

#define NOTE_WIDTH 200
#define NOTE_HEIGHT 180
#define NOTE_THUMBNAIL_SIZE 70

@interface StudyWordViewController ()
{
    SearchViewController *searchView;
    NoteThumbnail *noteView;
    NoteFullView *noteFullView;
    BOOL isShowNote;
}

@end

@implementation StudyWordViewController
@synthesize studyScreenMode = _studyScreenMode;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [TagManagerHelper pushOpenScreenEvent:@"iStudyScreen"];
    
    //admob
    GADRequest *request = [GADRequest request];
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    TAGContainer *container = appDelegate.container;
    BOOL enableAds = [[container stringForKey:@"adv_enable"] boolValue];

    if (enableAds) {
        viewReservationForAds.hidden = NO;
        NSString *advStr = [NSString stringWithFormat:@"%@/%@", [container stringForKey:@"admob_pub_id"],[container stringForKey:@"adv_default_id"] ];
        
        self.adBanner.adUnitID = advStr;//@"ca-app-pub-3940256099942544/2934735716";
        
        self.adBanner.rootViewController = self;
        
        request.testDevices = @[
                                @"8466af21f9717b97f0ba30fa23e53e1ba94d3422"
                                ];
        
        [self.adBanner loadRequest:request];
        
    } else {
        viewReservationForAds.hidden = YES;
    }
    
    if (_isReviewScreen == YES) {
        UIBarButtonItem *actionButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(showActionsPanel:)];
        
        self.navigationItem.rightBarButtonItems = @[actionButton];
        
        if (_wordObj) {
            [self displayAnswer:_wordObj];
            
            //hide buttons panel and "show answer" panel, expand webview full screen
            viewButtonsPanel.hidden = YES;
            viewShowAnswer.hidden = YES;

            CGRect webViewRect = webViewWord.frame;
            CGRect showAnswerrect = viewShowAnswer.frame;
            
            if (enableAds) {
                webViewRect.origin.y = 0;
                webViewRect.size.height = showAnswerrect.origin.y;
                [webViewWord setFrame:webViewRect];
                
                [viewReservationForAds setFrame:showAnswerrect];
                
            } else {
                webViewRect.origin.y = 0;
                webViewRect.size.height = showAnswerrect.origin.y + showAnswerrect.size.height;
                [webViewWord setFrame:webViewRect];
            }
            
            //show word
            [self displayAnswer:_wordObj];
        }
        
    } else {
        UIBarButtonItem *searchButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(showSearchBar)];
        UIBarButtonItem *actionButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(showActionsPanel:)];
        
        self.navigationItem.rightBarButtonItems = @[actionButton, searchButton];
        
        NSString *title = @"Learn";
        if (_studyScreenMode == Mode_New_Word) {
            title = @"New Word";
        } else if (_studyScreenMode == Mode_Study) {
            title = @"Learn Again";
        } else if (_studyScreenMode == Mode_Review) {
            title = @"Review";
        }
        
        [self setTitle:title];
        
        
        isShowNote = NO;
        //move buttons panel from the screen
        [self showHideButtonsPanel:NO];
        
        //show/hide ads
        CGRect infoViewRect = viewLearningInfo.frame;
        CGRect webViewRect = webViewWord.frame;
        CGRect showAnswerrect = viewShowAnswer.frame;
        
        if (!enableAds) {
            webViewRect.origin.y = infoViewRect.origin.y + infoViewRect.size.height;
            webViewRect.size.height = showAnswerrect.origin.y - infoViewRect.size.height;
            [webViewWord setFrame:webViewRect];
        }
        
        //init words list
        _nwordList = [[NSMutableArray alloc] init];
        _studyAgainList = [[NSMutableArray alloc] init];
        _reviewWordList = [[NSMutableArray alloc] init];
        
        //have to get review then learn again before get new word
        [_reviewWordList addObjectsFromArray:[[CommonSqlite sharedCommonSqlite] getReviewList]];
        NSInteger countOfReview = [[CommonSqlite sharedCommonSqlite] getCountOfInreview];   //dont use [_reviewWordList count] because it could be changed while learning
        
        NSInteger limit = TOTAL_WORDS_A_DAY_MAX - countOfReview;
        if (limit > 0) {
            [_studyAgainList addObjectsFromArray:[[CommonSqlite sharedCommonSqlite] getStudyAgainListWithLimit:limit]];
        }
        
        NSInteger countOfNew = TOTAL_WORDS_A_DAY_MAX;
        countOfNew = countOfNew - countOfReview - [_studyAgainList count];
       
        if (countOfNew >= 0) {
            if (countOfNew > [[Common sharedCommon] getDailyTarget]) {
                countOfNew = [[Common sharedCommon] getDailyTarget];
            }
        } else {
            countOfNew = 0;
        }
        
        [[CommonSqlite sharedCommonSqlite] pickUpRandom10WordsToStudyingQueue:countOfNew withForceFlag:NO];
        
        [_nwordList addObjectsFromArray:[[CommonSqlite sharedCommonSqlite] getNewWordsList]];
        
        //check if the list is not empty to switch screen mode, review is the highest priority
        if ([_reviewWordList count] > 0) {
            self.studyScreenMode = Mode_Review;
            
        } else if ([_studyAgainList count] > 0) {
            self.studyScreenMode = Mode_Study;
            
        } else if ([_nwordList count] > 0) {
            self.studyScreenMode = Mode_New_Word;
        }
        
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
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(refreshStudyScreen:)
                                                     name:@"refreshStudyScreen"
                                                   object:nil];
        
        //in case clicking on Add to learn
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(refreshAfterAddWord:)
                                                     name:@"AddToLearn"
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(refreshScreenAfterUpdateWord:)
                                                     name:@"UpdateWord"
                                                   object:nil];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidDisappear:(BOOL)animated {
    
    [self stopPlaySoundOnWebview];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    
    [UIView animateWithDuration:0.3 animations:^(void) {
        if (noteFullView != nil && isShowNote) {
            CGRect fullNoteRect = noteFullView.frame;
            
            fullNoteRect.origin.x = (size.width - NOTE_WIDTH)/2;
            fullNoteRect.origin.y = (size.height - NOTE_HEIGHT)/2 - 40;
            
            [noteFullView setFrame:fullNoteRect];
        }
        
        if (noteView != nil) {
            CGRect noteRect = noteView.frame;
            
            noteRect.origin.x = size.width - NOTE_THUMBNAIL_SIZE;
            noteRect.origin.y = size.height - NOTE_THUMBNAIL_SIZE - 2*viewButtonsPanel.frame.size.height;
            
            [noteView setFrame:noteRect];
        }
    }];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)stopPlaySoundOnWebview {
    [webViewWord stringByEvaluatingJavaScriptFromString:@"cancelSpeech()"];
}

- (void)setStudyScreenMode:(STUDY_SCREEN_MODE)studyScreenMode {
    _studyScreenMode = studyScreenMode;
    
    NSString *title = @"Learn";
    if (_studyScreenMode == Mode_New_Word) {
        title = @"New Word";
        
        btnEasy.enabled = YES;
        btnNorm.enabled = YES;
        
    } else if (_studyScreenMode == Mode_Study) {
        title = @"Learn Again";
        
        btnEasy.enabled = NO;
        btnNorm.enabled = NO;
        
    } else if (_studyScreenMode == Mode_Review) {
        title = @"Review";
        
        btnEasy.enabled = YES;
        btnNorm.enabled = YES;
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

- (void)showActionsPanel:(id)sender {
    if (_isReviewScreen) {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:(id)self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Add to learn", @"Report", nil];
        
        actionSheet.tag = AS_TAG_SEARCH;
        actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
//        [actionSheet showInView:self.view];
        if (IS_IPAD) {
            [actionSheet showFromBarButtonItem:sender animated:YES];
        } else {
            [actionSheet showInView:self.view];
        }
        
    } else {

        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:(id)self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Ignore", @"Done", @"Dictionary", @"Update", @"Report", nil];

//        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:(id)self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Ignore", @"Done", @"Update", nil];
        
        actionSheet.tag = AS_TAG_LEARN;
        actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
        //        [actionSheet showInView:self.view];
        if (IS_IPAD) {
            [actionSheet showFromBarButtonItem:sender animated:YES];
        } else {
            [actionSheet showInView:self.view];
        }
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
        CGRect showAnswerrect = viewShowAnswer.frame;
        CGRect buttonsPanelRect = viewButtonsPanel.frame;
        
        if (show) {
            //overlap showAnswer panel
            buttonsPanelRect.origin.y = showAnswerrect.origin.y;
        } else {
            //move buttons panel from the screen
            buttonsPanelRect.origin.y = showAnswerrect.origin.y + buttonsPanelRect.size.height;
        }
        
        [viewButtonsPanel setFrame:buttonsPanelRect];
    }];
}

- (void)displayQuestion:(WordObject *)wordObj {
    //close note
    [self btnCloseClick];
    
    [self stopPlaySoundOnWebview];
    
    //display question
    NSString *path = [[NSBundle mainBundle] bundlePath];
    NSURL *baseURL = [NSURL fileURLWithPath:path];
    
    NSString *htmlString = @"";
    
    if (wordObj) {
        NSString *curMajor = [[Common sharedCommon] loadDataFromUserDefaultStandardWithKey:KEY_SELECTED_MAJOR];
        
        if (curMajor == nil || curMajor.length == 0) {
            curMajor = @"common";
        }
        
        htmlString = [[HTMLHelper sharedHTMLHelper]createHTMLForQuestion:wordObj withPackage:curMajor];
    }
    
    [webViewWord loadHTMLString:htmlString baseURL:baseURL];
    
    NSNumber *autoPlayFlag = [[Common sharedCommon] loadDataFromUserDefaultStandardWithKey:KEY_AUTOPLAY];
    
    if ([autoPlayFlag boolValue]) {
        NSNumber *speedNumberObj = [[Common sharedCommon] loadDataFromUserDefaultStandardWithKey:KEY_SPEAKING_SPEED];
        float speed = [speedNumberObj floatValue];
        [[Common sharedCommon] textToSpeech:wordObj.question withRate:speed];
    }
    _isAnswerScreen = NO;
}

- (void)displayAnswer:(WordObject *)wordObj {
    [self stopPlaySoundOnWebview];
    
    //display question
    NSString *path = [[NSBundle mainBundle] bundlePath];
    NSURL *baseURL = [NSURL fileURLWithPath:path];

    NSString *htmlString = @"";
    
    if (wordObj) {
        NSString *curMajor = [[Common sharedCommon] loadDataFromUserDefaultStandardWithKey:KEY_SELECTED_MAJOR];
        if (curMajor == nil || curMajor.length == 0) {
            curMajor = @"common";
            
        }
        
        htmlString = [[HTMLHelper sharedHTMLHelper]createHTMLForAnswer:wordObj withPackage:curMajor];
        
        //note view
        
        if (noteView == nil) {
            noteView = [[NoteThumbnail alloc] initWithFrame:CGRectMake(webViewWord.frame.size.width -  NOTE_THUMBNAIL_SIZE, webViewWord.frame.size.height - NOTE_THUMBNAIL_SIZE, NOTE_THUMBNAIL_SIZE, NOTE_THUMBNAIL_SIZE)];
            noteView.delegate = (id)self;
            
            [webViewWord addSubview:noteView];
            
        }
    }

    [webViewWord loadHTMLString:htmlString baseURL:baseURL];
    
    _isAnswerScreen = YES;
}

//only need to check sender in case click on Again button
- (WordObject *)getAWordFromCurrentList:(id)sender {
    WordObject *res = nil;
    //remove the old word from array
    if (_studyScreenMode == Mode_Study) {
        if (_wordObj) {
            [_studyAgainList removeObject:_wordObj];
        }
        
    } else if (_studyScreenMode == Mode_Review) {
        if (_wordObj) {
            [_reviewWordList removeObject:_wordObj];
            
            //update inreview key
            [[CommonSqlite sharedCommonSqlite] updateInreviewWordList:_reviewWordList];
        }
        
    } else if (_studyScreenMode == Mode_New_Word) {
        if (_wordObj) {
            [_nwordList removeObject:_wordObj];
            
            //update pickedword key
            [[CommonSqlite sharedCommonSqlite] updatePickedWordList:_nwordList];
        }
        
    }
    
    //get next word, if it's nil then switch array and screen mod
    if (_studyScreenMode == Mode_Study) {
        if ([_studyAgainList count] > 0) {
            res = [_studyAgainList objectAtIndex:0];
        }
        
    } else if (_studyScreenMode == Mode_Review) {
        if ([_reviewWordList count] > 0) {
            res = [_reviewWordList objectAtIndex:0];
        }
        
    } else if (_studyScreenMode == Mode_New_Word) {
        if ([_nwordList count] > 0) {
            res = [_nwordList objectAtIndex:0];
        }
        
    }
    
    if (res == nil) {
        //check if the list is not empty to switch screen mode, review is the highest priority
        if ([_reviewWordList count] > 0) {
            self.studyScreenMode = Mode_Review;
            
        } else if ([_studyAgainList count] > 0) {
            self.studyScreenMode = Mode_Study;
            
        } else if ([_nwordList count] > 0) {
            self.studyScreenMode = Mode_New_Word;
        } else {
            return nil; //back to home in this case
        }
        
        //get next word again
        if (_studyScreenMode == Mode_New_Word) {
            res = [_nwordList objectAtIndex:0];
            
        } else if (_studyScreenMode == Mode_Study) {
            res = [_studyAgainList objectAtIndex:0];
            
        } else if (_studyScreenMode == Mode_Review) {
            res = [_reviewWordList objectAtIndex:0];
        }
    }
    
    //re-add old to again list after set screen mode
    if ([sender isEqual:btnAgain]) {
        [_studyAgainList addObject:_wordObj];
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
    lbNewCount.text = [NSString stringWithFormat:@"New: %ld", (unsigned long)[_nwordList count]];
    lbAgainCount.text = [NSString stringWithFormat:@"Again: %ld", (unsigned long)[_studyAgainList count]];
    lbReviewCount.text = [NSString stringWithFormat:@"Review: %ld", (unsigned long)[_reviewWordList count]];
}

- (void)updateWordFromGAE {
    
    if ([[Common sharedCommon] networkIsActive]) {
        static GTLServiceDataServiceApi *service = nil;
        if (!service) {
            service = [[GTLServiceDataServiceApi alloc] init];
            service.retryEnabled = YES;
            //[GTMHTTPFetcher setLoggingEnabled:YES];
        }
        
        [SVProgressHUD showWithStatus:nil];
        GTLQueryDataServiceApi *query = [GTLQueryDataServiceApi queryForGetVocaByQWithQ:self.wordObj.question];
        //TODO: Add waiting progress here
        [service executeQuery:query completionHandler:^(GTLServiceTicket *ticket, GTLDataServiceApiVoca *object, NSError *error) {
            if (object != NULL){
                NSLog(object.JSONString);
                //TODO: Update word: q, a, level, package, (and ee, ev)
                _wordObj.question   = object.q;
                _wordObj.answers    = object.a;
                _wordObj.level      = object.level;
                _wordObj.package    = object.packages;
                _wordObj.langEN     = object.lEn;
                _wordObj.langVN     = object.lVn;
                
                [[CommonSqlite sharedCommonSqlite] updateWord:_wordObj];
                
                if (_isAnswerScreen == YES) {
                    [self displayAnswer:_wordObj];
                }
            }
            
            [SVProgressHUD dismiss];
        }];
        
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No connection" message:@"Please double check wifi/3G connection." delegate:(id)self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        alert.tag = 2;
        
        [alert show];
    }
}



#pragma mark actions sheet handle
- (void) actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (actionSheet.tag == AS_TAG_SEARCH) {
        if (buttonIndex == AS_SEARCH_BTN_ADD_TO_LEARN) {
            NSLog(@"Add to learn");
            //update queue value to 3 to consider this word as a new word in DB
            _wordObj.queue = [NSString stringWithFormat:@"%d", QUEUE_NEW_WORD];
            
            if (_wordObj.isFromServer) {
                [[CommonSqlite sharedCommonSqlite] insertWordToDatabase:_wordObj];
                
                //because word-id is blank so need to get again after insert it into db
                _wordObj = [[CommonSqlite sharedCommonSqlite] getWordInformation:_wordObj.question];
                
                [[CommonSqlite sharedCommonSqlite] addAWordToStydyingQueue:_wordObj];
                
            } else {
                [[CommonSqlite sharedCommonSqlite] addAWordToStydyingQueue:_wordObj];
                
                //remove from buffer
                [[CommonSqlite sharedCommonSqlite] removeWordFromBuffer:_wordObj];
                
                [[CommonSqlite sharedCommonSqlite] updateWord:_wordObj];
            }
            
            //update incoming list
            [[NSNotificationCenter defaultCenter] postNotificationName:@"AddToLearn" object:_wordObj];
            
        } else if (buttonIndex == AS_SEARCH_BTN_REPORT) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Report" message:@"Open facebook to report this word?" delegate:(id)self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Open", nil];
            alert.tag = 1;
            
            [alert show];
            
        } else if (buttonIndex == AS_SEARCH_BTN_CANCEL) {

            NSLog(@"Cancel");
        }
        
    } else if (actionSheet.tag == AS_TAG_LEARN) {
        
        if (buttonIndex == AS_LEARN_BTN_IGNORE_WORD) {
            NSLog(@"ignore this word");
            //update queue value in DB
            _wordObj.queue = [NSString stringWithFormat:@"%d", QUEUE_SUSPENDED];
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
            
        } else if (buttonIndex == AS_LEARN_BTN_LEARNT_WORD) {
            NSLog(@"learnt");
            //update queue value in DB
            _wordObj.queue = [NSString stringWithFormat:@"%d", QUEUE_DONE];
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
            
        } else if (buttonIndex == AS_LEARN_BTN_DICTIONARY) {
            DictDetailContainerViewController *dictDetailContainer = [[DictDetailContainerViewController alloc] initWithNibName:@"DictDetailContainerViewController" bundle:nil];
            dictDetailContainer.wordObj = _wordObj;
            [self.navigationController pushViewController:dictDetailContainer animated:YES];
            
            
        } else if (buttonIndex == AS_LEARN_BTN_UPDATE_WORD) {
            NSLog(@"Update word");
            [self updateWordFromGAE];
            
        }  else if (buttonIndex == AS_LEARN_BTN_REPORT_WORD) {
            NSLog(@"report");
/*            ReportViewController *reportView = [[ReportViewController alloc] initWithNibName:@"ReportViewController" bundle:nil];
            reportView.wordObj = _wordObj;
            
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:reportView];
            
            [nav setModalPresentationStyle:UIModalPresentationFormSheet];
            [nav setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
            
            [self.navigationController presentViewController:nav animated:YES completion:nil];*/

            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Report" message:@"Open facebook to report this word?" delegate:(id)self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Open", nil];
            alert.tag = 1;
            
            [alert show];
            
            
        } else if (buttonIndex == AS_LEARN_BTN_CANCEL) {
            NSLog(@"Cancel");
            
        }
    }
    
}

#pragma mark handle notification
- (void)didSelectRowFromSearch:(NSNotification *)notification {
    
    if ([self.navigationController.topViewController isEqual:self]) {
        WordObject *wordObj = (WordObject *)notification.object;
        
/*        StudyWordViewController *studyViewController = [[StudyWordViewController alloc] initWithNibName:@"StudyWordViewController" bundle:nil];
        studyViewController.isReviewScreen = YES;
        studyViewController.wordObj = wordObj;
        
        [self.navigationController pushViewController:studyViewController animated:YES];*/
        DictDetailContainerViewController *dictDetailContainer = [[DictDetailContainerViewController alloc] initWithNibName:@"DictDetailContainerViewController" bundle:nil];
        dictDetailContainer.wordObj = wordObj;
        [self.navigationController pushViewController:dictDetailContainer animated:YES];
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

- (void)refreshStudyScreen:(NSNotification *)notification {
    
    if ([self.navigationController.topViewController isEqual:self]) {
        _wordObj = (WordObject *)notification.object;
        
        if (_wordObj) {
            [self displayAnswer:_wordObj];
            [self showHideButtonsPanel:YES];
        }
    }
}

- (void)refreshAfterAddWord:(NSNotification *)notification {
    if ([self.navigationController.viewControllers indexOfObject:self] != NSNotFound) {
        WordObject *newWord = (WordObject *)notification.object;
        
        if (newWord) {
            [_nwordList addObject:newWord];
            
            lbNewCount.text = [NSString stringWithFormat:@"New: %ld", (unsigned long)[_nwordList count]];
        }
    }
}

- (void)refreshScreenAfterUpdateWord:(NSNotification *)notification {
    WordObject *newWord = (WordObject *)notification.object;
    
    _wordObj = newWord;
    
    if (_isAnswerScreen == YES) {
        [self displayAnswer:_wordObj];
    }
}

#pragma mark alert delegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (alertView.tag == 1) {   //report
        if (buttonIndex != 0) {
            NSString *postLink = @"fb://profile/1012100435467230";//fb_comment_url
            
            AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            TAGContainer *container = appDelegate.container;
            postLink = [container stringForKey:@"fb_comment_url"];

            if (postLink == nil || postLink.length == 0) {
                postLink = @"fb://profile/1012100435467230";
            }
            if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:postLink]]) {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:postLink]];
                
            } else {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.facebook.com/lazzybees"]];
            }
        }
    }
}

#pragma mark note delegate
- (void)displayNote:(id)sender {
    
    if (isShowNote == NO) {
        if (noteFullView == nil) {
            noteFullView = [[NoteFullView alloc] initWithFrame:noteView.frame];
            noteFullView.delegate = (id)self;
            noteFullView.word = _wordObj;
            [self.view insertSubview:noteFullView belowSubview:viewShowAnswer];
            
        } else {
            noteFullView.word = _wordObj;
            [noteFullView setFrame:noteView.frame];
            [self.view insertSubview:noteFullView belowSubview:viewShowAnswer];
        }
        
        [UIView animateWithDuration:0.3 animations:^(void) {
            CGRect rect = noteFullView.frame;
            CGRect webRect = webViewWord.frame;
            rect.size.width = NOTE_WIDTH;
            rect.size.height = NOTE_HEIGHT;
            
            rect.origin.x = (webRect.size.width - NOTE_WIDTH)/2;
            
            rect.origin.y = (webRect.size.height - NOTE_HEIGHT)/2 - 40; //40 :: to move the save button from the keyboard
            
            [noteFullView setFrame:rect];
            
            isShowNote = YES;
        }];
    } else {
        if (noteFullView != nil) {
            [UIView animateWithDuration:0.3 animations:^(void) {
                CGRect rect = noteFullView.frame;
                CGRect webRect = webViewWord.frame;
                
                rect.origin.x = (webRect.size.width - NOTE_WIDTH)/2;
                
                rect.origin.y = (webRect.size.height - NOTE_HEIGHT)/2 - 40; //40 :: to move the save button from the keyboard
                
                [noteFullView setFrame:rect];
            }];
        }
    }
}

- (void)btnCloseClick {
    isShowNote = NO;
    
    [UIView animateWithDuration:0.3 animations:^(void) {
        [noteFullView setFrame:noteView.frame];
        
    } completion:^(BOOL finished) {
        [noteFullView removeFromSuperview];
    }];
}

- (void)btnSaveClick {
    isShowNote = NO;
    
    [UIView animateWithDuration:0.3 animations:^(void) {
        [noteFullView setFrame:noteView.frame];
        
    } completion:^(BOOL finished) {
        [noteFullView removeFromSuperview];
    }];
}


@end
