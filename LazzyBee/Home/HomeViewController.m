//
//  HomeViewController.m
//  LazzyBee
//
//  Created by nobody on 8/3/15.
//  Copyright (c) 2015 Born2go. All rights reserved.
//

#import "HomeViewController.h"
#import "StudyWordViewController.h"
#import "StudiedListViewController.h"
#import "SearchViewController.h"
#import "HelpViewController.h"
#import "CommonDefine.h"
#import "CommonSqlite.h"
#import "Common.h"
#import "AppDelegate.h"
#import "TagManagerHelper.h"
#import "DictDetailContainerViewController.h"
#import "StreakViewController.h"
#import "PopupView.h"
#import "LocalizeHelper.h"
#import "MajorObject.h"
#import "UploadToServer.h"
#import "ReverseViewController.h"


@interface HomeViewController ()<GADInterstitialDelegate>
{
    SearchViewController *searchView;
    PopupView *popupView;
    
    NSTimer *hintTimer;
    NSInteger hintCountDown;
    
    StudiedListViewController *searchHintViewController;
    
    UploadToServer *uploadToServer;
}

/// The interstitial ad.
@property(nonatomic, strong) GADInterstitial *interstitial;

@end

@implementation HomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [TagManagerHelper pushOpenScreenEvent:@"iHomeScreen"];
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)
    {
        [self.navigationController.navigationBar setTranslucent:NO];
    }
#endif
    [self.navigationController.navigationBar setBarTintColor:COMMON_COLOR];
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor whiteColor]};
    [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
    
    [self setTitle:LocalizedString(@"Lazzy Bee")];
    [btnStudy setTitle:LocalizedString(@"Start learning") forState:UIControlStateNormal];
    [btnIncoming setTitle:LocalizedString(@"Incoming list") forState:UIControlStateNormal];
    [btnMore setTitle:LocalizedString(@"More words") forState:UIControlStateNormal];

//    UIBarButtonItem *searchButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(showSearchBar)];
    
//    self.navigationItem.rightBarButtonItem = searchButton;
//    [txtSearchbox setLeftViewMode:UITextFieldViewModeAlways];
//    txtSearchbox.leftView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ic_search_gray"]];
    
//    [viewInformation setBackgroundColor:COMMON_COLOR];
    
    //make avatar round
    btnReverse.layer.cornerRadius = btnReverse.frame.size.width/2;
    btnReverse.clipsToBounds = YES;
    
    viewSearchContainer.layer.borderColor = [[UIColor lightGrayColor] CGColor];
    viewSearchContainer.layer.borderWidth = 1.0f;
    
    [txtSearchbox setPlaceholder:LocalizedString(@"Dictionary")];
    
    //prepare 100 words
    [self prepareWordsToStudyingQueue];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(completedDailyTarget)
                                                 name:@"completedDailyTarget"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(noWordToStudyToday)
                                                 name:@"noWordToStudyToday"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(searchBarSearchButtonClicked:)
                                                 name:@"searchBarSearchButtonClicked"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didSelectRowFromSearch:)
                                                 name:@"didSelectRowFromSearch"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(prepareWordsToStudyingQueue)
                                                 name:@"ChangeMajor"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(needToCheckReviewList)
                                                 name:@"NeedToCheckReviewList"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(needToBackupData)
                                                 name:@"NeedToBackupData"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(toggleView)
                                                 name:@"toggleView"
                                               object:nil];
    
    
    NSNumber *isFirstRunObj = [[Common sharedCommon] loadDataFromUserDefaultStandardWithKey:IS_FIRST_RUN];
    
    if (isFirstRunObj == nil || [isFirstRunObj boolValue] == YES) {
        HelpViewController *helpViewController = [[HelpViewController alloc] initWithNibName:@"HelpViewController" bundle:nil];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:helpViewController];
        
        [nav setModalPresentationStyle:UIModalPresentationFormSheet];
        [nav setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
        
        [self presentViewController:nav animated:YES completion:nil];
        
        [[Common sharedCommon] saveDataToUserDefaultStandard:[NSNumber numberWithBool:NO] withKey:IS_FIRST_RUN];
    }
    
    //admob
/*    GADRequest *request = [GADRequest request];
    self.adBanner.adUnitID = @"ca-app-pub-3940256099942544/2934735716";
    self.adBanner.rootViewController = self;
    [self.adBanner loadRequest:request];*/
    [self createAndLoadInterstitial];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated {
    dispatch_queue_t taskQ = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(taskQ, ^{
        [NSThread sleepForTimeInterval:0.3];
        dispatch_sync(dispatch_get_main_queue(), ^{
            AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            TAGContainer *container = appDelegate.container;
            NSString *popupText = nil;
            NSString *popupURL = nil;
            NSString *popupNumber = [container stringForKey:@"popup_maxnum"];
            
            if (popupNumber != nil && popupNumber.length > 0) {
                int popupInt = [popupNumber intValue];
                if (popupInt < 1) {
                    popupInt = 1;
                }
                
                int randomIndex = arc4random() % (popupInt);
                popupText = [container stringForKey:[NSString stringWithFormat:@"popup_text%d", randomIndex + 1]];
                popupURL = [container stringForKey:[NSString stringWithFormat:@"popup_url%d", randomIndex + 1]];
//                NSLog(@"popupText :: %@", popupText);
//                NSLog(@"popupURL :: %@", popupURL);
                
            }
            
            if (popupText == nil || popupURL == nil ||
                popupText.length == 0 || popupURL.length == 0) {
                popupText = [container stringForKey:@"popup_text"];
                popupURL = [container stringForKey:@"popup_url"];
//                NSLog(@"popupText :: %@", popupText);
//                NSLog(@"popupURL :: %@", popupURL);
            }
            
            if (popupText && popupURL &&
                popupText.length > 0 && popupURL.length > 0) {
                [self displayPopupView:popupText withURL:popupURL];
            }
        });
    });
    
    //check to activate reverse button
    NSNumber *reverseFlag = [[Common sharedCommon] loadDataFromUserDefaultStandardWithKey:KEY_REVERSE_ENABLE];
    
    if (reverseFlag && [reverseFlag boolValue] == YES) {
        [btnReverse setBackgroundColor:COMMON_COLOR];
        
    } else {
        NSInteger count = [[CommonSqlite sharedCommonSqlite] getCountOfStudiedWord];
        
        if (count >= NUMBER_OF_WORD_TO_ACTIVATE_REVERSE) {
            reverseFlag = [NSNumber numberWithBool:YES];
            [btnReverse setBackgroundColor:COMMON_COLOR];
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:LocalizedString(@"Congratulation") message:LocalizedString(@"\"Reverse\" function have been unlocked. Try it now.") delegate:(id)self cancelButtonTitle:LocalizedString(@"Close") otherButtonTitles:LocalizedString(@"Try now"), nil];
            alert.tag = 10;
            
            [alert show];
            
        } else {
            reverseFlag = [NSNumber numberWithBool:NO];
            [btnReverse setBackgroundColor:[UIColor darkGrayColor]];
        }
        
        [[Common sharedCommon] saveDataToUserDefaultStandard:reverseFlag withKey:KEY_REVERSE_ENABLE];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    if (popupView) {
        popupView.alpha = 0;
        [popupView removeFromSuperview];
    }
}

- (void)displayPopupView:(NSString *)popupText withURL:(NSString *)popupURL {
    CGRect rect = CGRectMake(self.view.frame.size.width/6, self.view.frame.size.height - 65, self.view.frame.size.width/1.5, 50);
    
    if (!popupView) {
        popupView = [[PopupView alloc] initWithFrame:rect];
    }
    
    [popupView setFrame:rect];
    
    popupView.popupText = popupText;
    popupView.popupURL = popupURL;
    popupView.lbInfo.text = popupText;
    
    popupView.alpha = 0;
    [self.view addSubview:popupView];

    [UIView animateWithDuration:1 animations:^(void) {
        popupView.alpha = 1;
    } completion:nil];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return TRUE;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    popupView.alpha = 0;
    [popupView removeFromSuperview];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"rotateScreen" object:nil];

    [txtSearchbox resignFirstResponder];
}

//tap on left top button
- (void)toggleView {
    [txtSearchbox resignFirstResponder];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [txtSearchbox resignFirstResponder];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if ([textField isEqual:txtSearchbox]) {
        [textField resignFirstResponder];
        
        NSString *searchText = [txtSearchbox.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        if (searchText.length > 0) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"searchBarSearchButtonClicked" object:searchText];
        }
        
    }
    
    return NO;
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

- (IBAction)textEditingExit:(id)sender {
//    [searchHintViewController.view removeFromSuperview];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    [searchHintViewController.view removeFromSuperview];
}

- (IBAction)textEditingChanged:(id)sender {
    hintCountDown = 1;
    [hintTimer invalidate];
    hintTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(hintCounter) userInfo:nil repeats:YES];
    [self hintCounter];
}

- (void)hintCounter {
    hintCountDown--;
    
    if (hintCountDown == 0) {
        [hintTimer invalidate];
        NSString *searchText = [txtSearchbox.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        if (searchText.length > 0) {
            
            if (!searchHintViewController) {
                //add searching result view, use studiedlistviewcontroller
                searchHintViewController = [[StudiedListViewController alloc] initWithNibName:@"StudiedListViewController" bundle:nil];
                searchHintViewController.screenType = List_SearchHintHome;
                
                searchHintViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth |                                             UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin;
            }
            
            CGRect rect = viewResultContainer.frame;
            
            [searchHintViewController.view setFrame:rect];
            
            [self.view insertSubview:searchHintViewController.view aboveSubview:viewResultContainer];
            
            searchHintViewController.searchText = searchText;
            
            [searchHintViewController tableReload];
            
        } else {
            [searchHintViewController.view removeFromSuperview];
        }
    }
}

- (IBAction)btnSearchClick:(id)sender {
    [txtSearchbox resignFirstResponder];
    
    NSString *searchText = [txtSearchbox.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if (searchText.length > 0) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"searchBarSearchButtonClicked" object:searchText];
    }
}


#pragma mark buttons handle
- (IBAction)btnStudyClick:(id)sender {
    [txtSearchbox resignFirstResponder];
    
    //check and pick new words
    if ([[CommonSqlite sharedCommonSqlite] getCountOfBuffer] < [[Common sharedCommon] getDailyTarget]) {
        [self prepareWordsToStudyingQueue];
    }
    
//    [[CommonSqlite sharedCommonSqlite] pickUpRandom10WordsToStudyingQueue:[[Common sharedCommon] getDailyTarget] withForceFlag:NO];
    
    StudyWordViewController *studyViewController = nil;
    
    if (IS_IPAD) {
        studyViewController = [[StudyWordViewController alloc] initWithNibName:@"StudyWordViewController_iPad" bundle:nil];
    } else {
        studyViewController = [[StudyWordViewController alloc] initWithNibName:@"StudyWordViewController" bundle:nil];
    }
    
    studyViewController.isReviewScreen = NO;
    
    [self.navigationController pushViewController:studyViewController animated:YES];
}

- (IBAction)btnStudiedListClick:(id)sender {
    [txtSearchbox resignFirstResponder];
    
    StudiedListViewController *studiedListViewController = [[StudiedListViewController alloc] initWithNibName:@"StudiedListViewController" bundle:nil];
    studiedListViewController.screenType = List_Incoming;
    
    [self.navigationController pushViewController:studiedListViewController animated:YES];
}

- (IBAction)btnMoreWordClick:(id)sender {
    [txtSearchbox resignFirstResponder];
    
    NSInteger count = [[CommonSqlite sharedCommonSqlite] getCountOfPickedWord];
    count = count + [[CommonSqlite sharedCommonSqlite] getCountOfInreview];
    count = count + [[CommonSqlite sharedCommonSqlite] getCountOfStudyAgain];
    
    if (count > 0) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:LocalizedString(@"Notice") message:LocalizedString(@"Need to complete current taret") delegate:(id)self cancelButtonTitle:LocalizedString(@"Cancel") otherButtonTitles:LocalizedString(@"Learn now"), nil];
        alert.tag = 1;
        
        [alert show];
        
    } else {
        //pick more words from buffer
        if ([[CommonSqlite sharedCommonSqlite] getCountOfBuffer] < [[Common sharedCommon] getDailyTarget]) {
            
            [self prepareWordsToStudyingQueue];
        }
        
        [[CommonSqlite sharedCommonSqlite] pickUpRandom10WordsToStudyingQueue:[[Common sharedCommon] getDailyTarget] withForceFlag:YES];
        
        //transfer to study screen
        StudyWordViewController *studyViewController = nil;
        
        if (IS_IPAD) {
            studyViewController = [[StudyWordViewController alloc] initWithNibName:@"StudyWordViewController_iPad" bundle:nil];
        } else {
            studyViewController = [[StudyWordViewController alloc] initWithNibName:@"StudyWordViewController" bundle:nil];
        }
        
        studyViewController.isReviewScreen = NO;
        
        [self.navigationController pushViewController:studyViewController animated:YES];
        
        //show ad full screen
        if (self.interstitial.isReady) {
            [self.interstitial presentFromRootViewController:self];
        }
    }
}


- (IBAction)btnReverseClick:(id)sender {
    //check
    NSNumber *reverseFlag = [[Common sharedCommon] loadDataFromUserDefaultStandardWithKey:KEY_REVERSE_ENABLE];
    
    if (reverseFlag && [reverseFlag boolValue] == YES) {
        [self openReverseScreen];
        
    } else {
        //need to show alert congratulation after unlocked new function
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:LocalizedString(@"Locked") message:LocalizedString(@"To unlock this function, you need to learn at lease 50 words.") delegate:(id)self cancelButtonTitle:LocalizedString(@"OK") otherButtonTitles:nil];
        alert.tag = 9;
        
        [alert show];
    }
}

- (void)openReverseScreen {
    NSNumber *completeTargetFlag = [[Common sharedCommon] loadDataFromUserDefaultStandardWithKey:KEY_COMPLETED_FLAG];
    
    if ([completeTargetFlag boolValue]) {
        ReverseViewController *reverseViewController = nil;
        
        if (IS_IPAD) {
            reverseViewController = [[ReverseViewController alloc] initWithNibName:@"ReverseViewController_iPad" bundle:nil];
        } else {
            reverseViewController = [[ReverseViewController alloc] initWithNibName:@"ReverseViewController" bundle:nil];
        }
        
        [self.navigationController pushViewController:reverseViewController animated:YES];
        
    } else {
        NSString *alertContent = LocalizedString(@"Please come back after finishing your daily target.");
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:LocalizedString(@"Oops!") message:alertContent delegate:(id)self cancelButtonTitle:LocalizedString(@"OK") otherButtonTitles: nil];
        alert.tag = 11;
        
        [alert show];
    }
}

#pragma mark alert delegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (alertView.tag == 1) {   //add more words alert
        if (buttonIndex != 0) {
            //transfer to study screen
            StudyWordViewController *studyViewController = nil;
            
            if (IS_IPAD) {
                studyViewController = [[StudyWordViewController alloc] initWithNibName:@"StudyWordViewController_iPad" bundle:nil];
            } else {
                studyViewController = [[StudyWordViewController alloc] initWithNibName:@"StudyWordViewController" bundle:nil];
            }
            
            studyViewController.isReviewScreen = NO;
            
            [self.navigationController pushViewController:studyViewController animated:YES];
        }
        
    } else if (alertView.tag == 4) {   //still have a few words need to review
        if (buttonIndex != 0) {
            //transfer to study screen
            StudyWordViewController *studyViewController = nil;
            
            if (IS_IPAD) {
                studyViewController = [[StudyWordViewController alloc] initWithNibName:@"StudyWordViewController_iPad" bundle:nil];
            } else {
                studyViewController = [[StudyWordViewController alloc] initWithNibName:@"StudyWordViewController" bundle:nil];
            }
            
            studyViewController.isReviewScreen = NO;
            
            [self.navigationController pushViewController:studyViewController animated:YES];
        }
        
    } else if (alertView.tag == 5) { //confirm to backup data
        if (buttonIndex != 0) {
            if ([[Common sharedCommon] networkIsActive]) {
                if (uploadToServer == nil) {
                    uploadToServer = [[UploadToServer alloc] init];
                    uploadToServer.delegate = (id)self;
                }
                
                [[CommonSqlite sharedCommonSqlite] backupData];
                
                [uploadToServer uploadDatabaseToServer];
                
            } else {
                [self noConnectionAlert];
            }
        }
    } else if (alertView.tag == 10) { //try now
        if (buttonIndex != 0) {
            dfdff
        }
    }
}

- (void)completedDailyTarget {
    NSNumber *completeTargetFlag = [[Common sharedCommon] loadDataFromUserDefaultStandardWithKey:KEY_COMPLETED_FLAG];
    NSString *alertContent = @"";
    
    if (![completeTargetFlag boolValue]) {
        //in case user complete previous daily target in next day
        //so need to compare current date with date in pickedword
        NSTimeInterval oldDate = [[CommonSqlite sharedCommonSqlite] getDateInBuffer];
        NSTimeInterval curDate = [[Common sharedCommon] getBeginOfDayInSec];
        
        
        if (curDate == oldDate) {
            [[Common sharedCommon] saveDataToUserDefaultStandard:[NSNumber numberWithBool:YES] withKey:KEY_COMPLETED_FLAG];
            
            //save streak info
            [[Common sharedCommon] saveStreak:curDate];
            
            //show streak view
            StreakViewController *streak = [[StreakViewController alloc] initWithNibName:@"StreakViewController" bundle:nil];
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:streak];
            [nav setModalPresentationStyle:UIModalPresentationFormSheet];
            [nav setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
            
            [self.navigationController presentViewController:nav animated:YES completion:nil];
            
        } else {
            
        }
        
    } else {
        
//        NSArray *reviewList = [[CommonSqlite sharedCommonSqlite] getReviewList];
//        
//        if ([reviewList count] > 0) {
//            NSString *alertContent = LocalizedString(@"Still have some words need to review");
//            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:LocalizedString(@"Notice") message:alertContent delegate:(id)self cancelButtonTitle:LocalizedString(@"Later") otherButtonTitles:LocalizedString(@"Learn now"), nil];
//            alert.tag = 4;
//            
//            [alert show];
//            
//        } else {
            NSTimeInterval oldDate = [[CommonSqlite sharedCommonSqlite] getDateInBuffer];
            NSTimeInterval curDate = [[Common sharedCommon] getBeginOfDayInSec];
            
            if (curDate == oldDate) {
                alertContent = LocalizedString(@"Learnt hard. Relax now");
                
                //show alert to congrat
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:LocalizedString(@"Congratulation") message:alertContent delegate:(id)self cancelButtonTitle:LocalizedString(@"OK") otherButtonTitles:nil];
                alert.tag = 2;
                
                [alert show];
            }
//        }
    }
}

- (void)noWordToStudyToday {
    //show alert to congrat
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:LocalizedString(@"Oops!") message:LocalizedString(@"No more word. Click More Words") delegate:(id)self cancelButtonTitle:LocalizedString(@"OK") otherButtonTitles:nil];
    alert.tag = 3;
    
    [alert show];
}

- (void)noConnectionAlert {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:LocalizedString(@"No connection") message:LocalizedString(@"Please double check wifi/3G connection") delegate:(id)self cancelButtonTitle:LocalizedString(@"OK") otherButtonTitles:nil];
    alert.tag = 6;
    
    [alert show];
}

#pragma mark to server delegate
- (void)failedToConnectToServerAlert {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:LocalizedString(@"Failed") message:LocalizedString(@"Failed to connect to server") delegate:(id)self cancelButtonTitle:LocalizedString(@"OK") otherButtonTitles:nil];
    alert.tag = 7;
    
    [alert show];
}

- (void)backupSuccessfullyAlert {
    NSString *content = @"";
    NSString *uniqueIdentifier = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    NSString *code = [uniqueIdentifier substringFromIndex:(uniqueIdentifier.length - BACKUP_CODE_LENGTH)];
    
    [[Common sharedCommon] saveDataToUserDefaultStandard:code withKey:KEY_BACKUP_CODE];
    
    content = [NSString stringWithFormat:@"%@:\n%@", LocalizedString(@"Your database will be archived on server in 7 days"), code];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:LocalizedString(@"Successfully") message:content delegate:(id)self cancelButtonTitle:LocalizedString(@"OK") otherButtonTitles:nil];
    alert.tag = 8;
    
    [alert show];
}

#pragma mark admob
- (void)createAndLoadInterstitial {
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    TAGContainer *container = appDelegate.container;
//    BOOL enableAds = [[container stringForKey:@"adv_enable"] boolValue];

//    if (enableAds) {
        NSString *advStr = [NSString stringWithFormat:@"%@/%@", [container stringForKey:@"admob_pub_id"],[container stringForKey:@"adv_fullscreen_id"] ];
//        advStr = @"ca-app-pub-5245864792816840/9210342219";
        self.interstitial = [[GADInterstitial alloc] initWithAdUnitID:advStr]; //@"ca-app-pub-3940256099942544/4411468910"
        self.interstitial.delegate = self;
    
        GADRequest *request = [GADRequest request];
        // Request test ads on devices you specify. Your test device ID is printed to the console when
        // an ad request is made. GADInterstitial automatically returns test ads when running on a
        // simulator.
        request.testDevices = @[
                                @"687f0b503566ebb7d84524c1f15e1d16",
                                kGADSimulatorID
                                ];
        [self.interstitial loadRequest:request];
//    }
}

- (void)interstitial:(GADInterstitial *)interstitial
didFailToReceiveAdWithError:(GADRequestError *)error {
    NSLog(@"interstitialDidFailToReceiveAdWithError: %@", [error localizedDescription]);
}

- (void)interstitialDidDismissScreen:(GADInterstitial *)interstitial {
    NSLog(@"interstitialDidDismissScreen");
}

#pragma mark handle notification
- (void)didSelectRowFromSearch:(NSNotification *)notification {
    [txtSearchbox resignFirstResponder];
    [searchHintViewController.view removeFromSuperview];
    
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

- (void)needToCheckReviewList {
    NSArray *reviewList = [[CommonSqlite sharedCommonSqlite] getReviewList];
    
    if ([reviewList count] > 0) {
        NSString *alertContent = LocalizedString(@"Still have some words need to review");
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:LocalizedString(@"Notice") message:alertContent delegate:(id)self cancelButtonTitle:LocalizedString(@"Later") otherButtonTitles:LocalizedString(@"Learn now"), nil];
        alert.tag = 4;
        
        [alert show];
    }
}

- (void)needToBackupData {
    NSString *alertContent = LocalizedString(@"Do you want to backup your learning progress?");
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:alertContent delegate:(id)self cancelButtonTitle:LocalizedString(@"No") otherButtonTitles:LocalizedString(@"Yes"), nil];
    alert.tag = 5;
    
    [alert show];
    
}
@end
