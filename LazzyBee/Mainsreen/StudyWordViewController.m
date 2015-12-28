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
#import "MajorObject.h"
#import "LocalizeHelper.h"

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
    
    NSTimer *timer;
    int countDown;
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
//    BOOL enableAds = [[container stringForKey:@"adv_enable"] boolValue];
    BOOL enableAds = YES;
//    if (enableAds) {
//        viewReservationForAds.hidden = NO;
    NSString *pub_id = [container stringForKey:@"admob_pub_id"];
    NSString *default_id = [container stringForKey:@"adv_default_id"];

        NSString *advStr = [NSString stringWithFormat:@"%@/%@", pub_id, default_id ];
        
        self.adBanner.adUnitID = advStr;//@"ca-app-pub-3940256099942544/2934735716";
        
        self.adBanner.rootViewController = self;
        
        request.testDevices = @[
                                @"687f0b503566ebb7d84524c1f15e1d16"
                                ];
        
        [self.adBanner loadRequest:request];
    
    if (pub_id == nil || pub_id.length == 0 ||
        default_id == nil || default_id.length == 0) {
        enableAds = NO;
    }
    
    if (enableAds) {
        viewReservationForAds.hidden = NO;
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
        
        NSString *title = LocalizedString(@"Learn");
        if (_studyScreenMode == Mode_New_Word) {
            title = LocalizedString(@"New word");
        } else if (_studyScreenMode == Mode_Study) {
            title = LocalizedString(@"Learn again");
        } else if (_studyScreenMode == Mode_Review) {
            title = LocalizedString(@"Review");
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
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(swipeToBackToPrevious)
                                                     name:@"swipeToBackToPrevious"
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
    
    NSString *title = LocalizedString(@"Learn");
    if (_studyScreenMode == Mode_New_Word) {
        title = LocalizedString(@"New word");
        
        btnEasy.enabled = YES;
        btnNorm.enabled = YES;
        
    } else if (_studyScreenMode == Mode_Study) {
        title = LocalizedString(@"Learn again");
        
        btnEasy.enabled = NO;
        btnNorm.enabled = NO;
        
    } else if (_studyScreenMode == Mode_Review) {
        title = LocalizedString(@"Review");
        
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
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:(id)self cancelButtonTitle:LocalizedString(@"Cancel") destructiveButtonTitle:nil otherButtonTitles:LocalizedString(@"Add to learn"), LocalizedString(@"Report"), nil];
        
        actionSheet.tag = AS_TAG_SEARCH;
        actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
//        [actionSheet showInView:self.view];
        if (IS_IPAD) {
            [actionSheet showFromBarButtonItem:sender animated:YES];
        } else {
            [actionSheet showInView:self.view];
        }
        
    } else {

        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:(id)self cancelButtonTitle:LocalizedString(@"Cancel") destructiveButtonTitle:nil otherButtonTitles:LocalizedString(@"Ignore"), LocalizedString(@"Done"), LocalizedString(@"Dictionary"), LocalizedString(@"Update"), LocalizedString(@"Report"), nil];

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
    
    [btnAgain setTitle:[NSString stringWithFormat:@"%@\n(%@)", [arrTitle objectAtIndex:0], LocalizedString(@"Again")] forState:UIControlStateNormal];
    
    [btnHard setTitle:[NSString stringWithFormat:@"%@\n(%@)", [arrTitle objectAtIndex:1], LocalizedString(@"Hard")] forState:UIControlStateNormal];
    
    [btnNorm setTitle:[NSString stringWithFormat:@"%@\n(%@)", [arrTitle objectAtIndex:2], LocalizedString(@"Normal")] forState:UIControlStateNormal];
    
    [btnEasy setTitle:[NSString stringWithFormat:@"%@\n(%@)", [arrTitle objectAtIndex:3], LocalizedString(@"Easy")] forState:UIControlStateNormal];
    
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
    
    //hide note button
    if (noteView != nil) {
        noteView.delegate = nil;
        [noteView removeFromSuperview];
    }
    
    //set timer
    if (timer) {
        [timer invalidate];
    }

    NSString *time = [[Common sharedCommon] loadDataFromUserDefaultStandardWithKey:KEY_TIME_TO_SHOW_ANSWER];
    
    if ([time intValue] == 0) {
        btnShowAnswer.enabled = YES;
        [btnShowAnswer setTitle:LocalizedString(@"Show answer") forState:UIControlStateNormal];
        
    } else {
        countDown = [time intValue];
        
        btnShowAnswer.enabled = NO;
        [btnShowAnswer setTitle:[NSString stringWithFormat:@"%d", countDown] forState:UIControlStateNormal];
        
        timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(timerHandler) userInfo:nil repeats:YES];
    }
    
    [self stopPlaySoundOnWebview];
    
    //display question
    NSString *path = [[NSBundle mainBundle] bundlePath];
    NSURL *baseURL = [NSURL fileURLWithPath:path];
    
    NSString *htmlString = @"";
    
    if (wordObj) {
        MajorObject *curMajorObj = (MajorObject *)[[Common sharedCommon] loadPersonalDataWithKey:KEY_SELECTED_MAJOR];
        
        htmlString = [[HTMLHelper sharedHTMLHelper]createHTMLForQuestion:wordObj withPackage:curMajorObj];
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

- (void)timerHandler {
    countDown--;
    
    [btnShowAnswer setTitle:[NSString stringWithFormat:@"%d", countDown] forState:UIControlStateNormal];
    
    if (countDown == 0) {
        [timer invalidate];
        [btnShowAnswer setTitle:LocalizedString(@"Show answer") forState:UIControlStateNormal];
        btnShowAnswer.enabled = YES;
    }
}

- (void)displayAnswer:(WordObject *)wordObj {
    [self stopPlaySoundOnWebview];
    
    //display question
    NSString *path = [[NSBundle mainBundle] bundlePath];
    NSURL *baseURL = [NSURL fileURLWithPath:path];

    NSString *htmlString = @"";
    
    if (wordObj) {
        MajorObject *curMajorObj = (MajorObject *)[[Common sharedCommon] loadPersonalDataWithKey:KEY_SELECTED_MAJOR];
        
        htmlString = [[HTMLHelper sharedHTMLHelper]createHTMLForAnswer:wordObj withPackage:curMajorObj];
        
        //note view
        
        if (noteView == nil) {
            noteView = [[NoteThumbnail alloc] initWithFrame:CGRectMake(webViewWord.frame.size.width -  NOTE_THUMBNAIL_SIZE, webViewWord.frame.size.height - NOTE_THUMBNAIL_SIZE, NOTE_THUMBNAIL_SIZE, NOTE_THUMBNAIL_SIZE)];
            noteView.delegate = (id)self;
            
            [webViewWord addSubview:noteView];
            
        } else {
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
            res = [_reviewWordList objectAtIndex:0];
            
        } else if ([_studyAgainList count] > 0) {
            self.studyScreenMode = Mode_Study;
            res = [_studyAgainList objectAtIndex:0];
            
        } else if ([_nwordList count] > 0) {
            self.studyScreenMode = Mode_New_Word;
            res = [_nwordList objectAtIndex:0];
            
        } else {
            //back to home in this case
        }

    }
    
    //re-add old to again list after set screen mode
    if ([sender isEqual:btnAgain]) {
        [_studyAgainList addObject:_wordObj];
        
        if (res == nil) {
            self.studyScreenMode = Mode_Study;
            res = [_studyAgainList objectAtIndex:0];
        }
    }
    
    [self updateHeaderInfo];
    
    return res;
}

#pragma mark gesture handle
- (IBAction)edgePanHandle:(id)sender {
    UIScreenEdgePanGestureRecognizer *edgeGest = (UIScreenEdgePanGestureRecognizer *)sender;
    
    if (edgeGest.state == UIGestureRecognizerStateBegan) {
        if (_isAnswerScreen) {
            DictDetailContainerViewController *dictDetailContainer = [[DictDetailContainerViewController alloc] initWithNibName:@"DictDetailContainerViewController" bundle:nil];
            dictDetailContainer.wordObj = _wordObj;
            dictDetailContainer.showLazzyBeeTab = NO;
            [self.navigationController pushViewController:dictDetailContainer animated:YES];
        }
    }
}

- (IBAction)swipeHandle:(id)sender {
    if (_isAnswerScreen) {
        DictDetailContainerViewController *dictDetailContainer = [[DictDetailContainerViewController alloc] initWithNibName:@"DictDetailContainerViewController" bundle:nil];
        dictDetailContainer.wordObj = _wordObj;
        dictDetailContainer.showLazzyBeeTab = NO;
        [self.navigationController pushViewController:dictDetailContainer animated:YES];
    }
}

- (void)swipeToBackToPrevious {
    [self.navigationController popViewControllerAnimated:YES];
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
    lbNewCount.text = [NSString stringWithFormat:@"%@: %ld", LocalizedString(@"New"), (unsigned long)[_nwordList count]];
    lbAgainCount.text = [NSString stringWithFormat:@"%@: %ld", LocalizedString(@"Again"),(unsigned long)[_studyAgainList count]];
    lbReviewCount.text = [NSString stringWithFormat:@"%@: %ld", LocalizedString(@"Review"),(unsigned long)[_reviewWordList count]];
}

- (void)updateWordFromGAE {
    
    if ([[Common sharedCommon] networkIsActive]) {
        static GTLServiceDataServiceApi *service = nil;
        if (!service) {
            service = [[GTLServiceDataServiceApi alloc] init];
            service.retryEnabled = YES;
            //[GTMHTTPFetcher setLoggingEnabled:YES];
        }
        
        [SVProgressHUD show];
        GTLQueryDataServiceApi *query = [GTLQueryDataServiceApi queryForGetVocaByIdWithIdentifier:[self.wordObj.gid longLongValue]];
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
                
                [SVProgressHUD showSuccessWithStatus:LocalizedString(@"Update successfully")];
            } else {
                [SVProgressHUD showErrorWithStatus:LocalizedString(@"Update failed")];
            }
        }];
        
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:LocalizedString(@"No connection") message:LocalizedString(@"Please double check wifi/3G connection") delegate:(id)self cancelButtonTitle:LocalizedString(@"OK") otherButtonTitles:nil];
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
            [self openFacebookToReport];
            
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
            dictDetailContainer.showLazzyBeeTab = NO;
            
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

            [self openFacebookToReport];
            
            
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
        dictDetailContainer.showLazzyBeeTab = YES;
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
            BOOL found = NO;
            for (WordObject *word in _nwordList) {
                if ([newWord.question isEqualToString:word.question]) {
                    found = YES;
                }
            }
            
            if (found == NO) {
                [_nwordList addObject:newWord];
                
                lbNewCount.text = [NSString stringWithFormat:@"%@: %ld", LocalizedString(@"New"), (unsigned long)[_nwordList count]];
            }
        }
    }
}

- (void)refreshScreenAfterUpdateWord:(NSNotification *)notification {
    WordObject *newWord = (WordObject *)notification.object;
    
    if ([_wordObj.question isEqualToString:newWord.question]) {
        _wordObj = newWord;
        
        if (_isAnswerScreen == YES) {
            [self displayAnswer:_wordObj];
        }
    }
    
}

#pragma mark alert delegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (alertView.tag == 1) {   //report
        if (buttonIndex != 0) {
//            [self openFacebookToReport];
        }
    }
}

- (void)openFacebookToReport {
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
