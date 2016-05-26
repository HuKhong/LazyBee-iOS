//
//  ReverseViewController.m
//  LazzyBee
//
//  Created by HuKhong on 5/25/16.
//  Copyright © 2016 Born2go. All rights reserved.
//

#import "ReverseViewController.h"
#import "SearchViewController.h"
#import "DictDetailContainerViewController.h"
#import "StudiedListViewController.h"
#import "CommonSqlite.h"
#import "GTMHTTPFetcher.h"
#import "GTLDataServiceApi.h"
#import "TagManagerHelper.h"
#import "HTMLHelper.h"
#import "LocalizeHelper.h"
#import "AppDelegate.h"
#import "Common.h"
#import "SVProgressHUD.h"
#import "Algorithm.h"


#define AS_REVERSE_BTN_LEARN_AGAIN 0
#define AS_REVERSE_BTN_DICTIONARY  1
#define AS_REVERSE_BTN_UPDATE_WORD   2
#define AS_REVERSE_BTN_REPORT_WORD   3
#define AS_REVERSE_BTN_CANCEL        4

@interface ReverseViewController ()
{
    NSArray *wordArr;
    WordObject *wordObj;
    
    SearchViewController *searchView;
    BOOL isAnswerScreen;
}
@end

@implementation ReverseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [TagManagerHelper pushOpenScreenEvent:@"iReverseScreen"];
    
    //border webview
    //    webViewWord.layer.borderColor = [UIColor darkGrayColor].CGColor;
    //    webViewWord.layer.borderWidth = 1.0f;
    //
    webView.layer.masksToBounds = NO;
    webView.layer.shadowOffset = CGSizeMake(0, 5);
    webView.layer.shadowRadius = 5;
    webView.layer.shadowOpacity = 0.5;
    
    isAnswerScreen = NO;
    
    //admob
    GADRequest *request = [GADRequest request];
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    TAGContainer *container = appDelegate.container;
    
    BOOL enableAds = YES;
    
    NSString *pub_id = [container stringForKey:@"admob_pub_id"];
    NSString *default_id = [container stringForKey:@"adv_default_id"];
    
    NSString *advStr = [NSString stringWithFormat:@"%@/%@", pub_id, default_id ];
    
    adBanner.adUnitID = advStr;//@"ca-app-pub-3940256099942544/2934735716";
    
    adBanner.rootViewController = self;
    
    request.testDevices = @[
                            @"687f0b503566ebb7d84524c1f15e1d16",
                            kGADSimulatorID
                            ];
    
    [adBanner loadRequest:request];
    
    if (pub_id == nil || pub_id.length == 0 ||
        default_id == nil || default_id.length == 0 ||
        ![[Common sharedCommon] networkIsActive]) {
        enableAds = NO;
    }
    //    enableAds = YES; //for test
    if (enableAds) {
        adBanner.hidden = NO;
    } else {
        adBanner.hidden = YES;
    }
    
    //show/hide ads
    CGRect webViewRect = webView.frame;
    CGRect showAnswerrect = viewShowAnswer.frame;
    
    if (!enableAds) {
        webViewRect.origin.y = 0;
        webViewRect.size.height = showAnswerrect.origin.y;
        [webView setFrame:webViewRect];
    }
    
    UIBarButtonItem *searchButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(showSearchBar)];
    UIBarButtonItem *actionButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(showActionsPanel:)];
    
    self.navigationItem.rightBarButtonItems = @[actionButton, searchButton];
    
    [self setTitle:LocalizedString(@"Reverse")];
    
    wordArr = [[CommonSqlite sharedCommonSqlite] getStudiedList];
    
    if ([wordArr count] > 0) {
        int randomIndex = arc4random() % ([wordArr count]);
        wordObj = [wordArr objectAtIndex:randomIndex];
        
        if (wordObj) {
            [self displayQuestion:wordObj];
        }
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
                                             selector:@selector(refreshScreenAfterUpdateWord:)
                                                 name:@"UpdateWord"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(swipeToBackToPrevious)
                                                 name:@"swipeToBackToPrevious"
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

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
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

    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:(id)self cancelButtonTitle:LocalizedString(@"Cancel") destructiveButtonTitle:nil otherButtonTitles:LocalizedString(@"Learn again"), LocalizedString(@"Dictionary"), LocalizedString(@"Update"), LocalizedString(@"Report"), nil];

    actionSheet.tag = 1;
    actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;

    if (IS_IPAD) {
        [actionSheet showFromBarButtonItem:sender animated:YES];
    } else {
        [actionSheet showInView:self.view];
    }

}

#pragma mark actions sheet handle
- (void) actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == AS_REVERSE_BTN_LEARN_AGAIN) {
        [[Algorithm sharedAlgorithm] updateWord:wordObj withEaseLevel:EASE_AGAIN];
        
        [[CommonSqlite sharedCommonSqlite] updateWord:wordObj];
        
        [SVProgressHUD showSuccessWithStatus:LocalizedString(@"Added")];
    
    } else if (buttonIndex == AS_REVERSE_BTN_DICTIONARY) {
        DictDetailContainerViewController *dictDetailContainer = [[DictDetailContainerViewController alloc] initWithNibName:@"DictDetailContainerViewController" bundle:nil];
        dictDetailContainer.wordObj = wordObj;
        dictDetailContainer.showLazzyBeeTab = NO;
        
        [self.navigationController pushViewController:dictDetailContainer animated:YES];
        
        
    } else if (buttonIndex == AS_REVERSE_BTN_UPDATE_WORD) {
        NSLog(@"Update word");
        [self updateWordFromGAE];
        
    }  else if (buttonIndex == AS_REVERSE_BTN_REPORT_WORD) {
        NSLog(@"report");
       
        [self openFacebookToReport];
        
    } else if (buttonIndex == AS_REVERSE_BTN_CANCEL) {
        NSLog(@"Cancel");
        
    }
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
        GTLQueryDataServiceApi *query = [GTLQueryDataServiceApi queryForGetVocaByIdWithIdentifier:[wordObj.gid longLongValue]];
        //TODO: Add waiting progress here
        [service executeQuery:query completionHandler:^(GTLServiceTicket *ticket, GTLDataServiceApiVoca *object, NSError *error) {
            if (object != NULL){
                NSLog(object.JSONString);
                //TODO: Update word: q, a, level, package, (and ee, ev)
                wordObj.question   = object.q;
                wordObj.answers    = object.a;
                wordObj.level      = [NSString stringWithFormat:@"%ld", (long)[object.level integerValue]];
                wordObj.package    = object.packages;
                wordObj.langEN     = object.lEn;
                wordObj.langVN     = object.lVn;
                
                [[CommonSqlite sharedCommonSqlite] updateWord:wordObj];
                
                if (isAnswerScreen == YES) {
                    [self displayAnswer:wordObj];
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

- (void)displayAnswer:(WordObject *)wObj {
    [self stopPlaySoundOnWebview];
    
    //display question
    NSString *path = [[NSBundle mainBundle] bundlePath];
    NSURL *baseURL = [NSURL fileURLWithPath:path];
    
    NSString *htmlString = @"";
    
    if (wObj) {
        MajorObject *curMajorObj = (MajorObject *)[[Common sharedCommon] loadPersonalDataWithKey:KEY_SELECTED_MAJOR];
        
        htmlString = [[HTMLHelper sharedHTMLHelper]createHTMLForAnswer:wordObj withPackage:curMajorObj];
        
    }
    
    [webView loadHTMLString:htmlString baseURL:baseURL];
    
    isAnswerScreen = YES;
    
    [btnShowAnswer setTitle:LocalizedString(@"Next") forState:UIControlStateNormal];
}

- (void)stopPlaySoundOnWebview {
    [webView stringByEvaluatingJavaScriptFromString:@"cancelSpeech()"];
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

- (void)displayQuestion:(WordObject *)wObj {
    [self stopPlaySoundOnWebview];
    
    //display question
    NSString *path = [[NSBundle mainBundle] bundlePath];
    NSURL *baseURL = [NSURL fileURLWithPath:path];
    
    NSString *htmlString = @"";
    
    if (wObj) {
        MajorObject *curMajorObj = (MajorObject *)[[Common sharedCommon] loadPersonalDataWithKey:KEY_SELECTED_MAJOR];
        
        htmlString = [[HTMLHelper sharedHTMLHelper]createHTMLForReverse:wordObj withPackage:curMajorObj];
    }
    
    [webView loadHTMLString:htmlString baseURL:baseURL];
    
    isAnswerScreen = NO;
    
    [btnShowAnswer setTitle:LocalizedString(@"Show answer") forState:UIControlStateNormal];
}

- (IBAction)btnShowAnswerClick:(id)sender {
    if (isAnswerScreen) {
        if ([wordArr count] > 0) {
            int randomIndex = arc4random() % ([wordArr count]);
            wordObj = [wordArr objectAtIndex:randomIndex];
            
            if (wordObj) {
                [self displayQuestion:wordObj];
            }
        }
    } else {
        [self displayAnswer:wordObj];
    }
}

#pragma mark handle notification
- (void)didSelectRowFromSearch:(NSNotification *)notification {
    
    if ([self.navigationController.topViewController isEqual:self]) {
        WordObject *wObj = (WordObject *)notification.object;

        DictDetailContainerViewController *dictDetailContainer = [[DictDetailContainerViewController alloc] initWithNibName:@"DictDetailContainerViewController" bundle:nil];
        dictDetailContainer.wordObj = wObj;
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

- (void)refreshScreenAfterUpdateWord:(NSNotification *)notification {
    WordObject *newWord = (WordObject *)notification.object;
    
    if ([wordObj.question isEqualToString:newWord.question]) {
        wordObj = newWord;
        
        if (isAnswerScreen == YES) {
            [self displayAnswer:wordObj];
        } else {
            [self displayQuestion:wordObj];
        }
    }
    
}

- (void)swipeToBackToPrevious {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)swipeHandle:(id)sender {
    if (isAnswerScreen) {
        DictDetailContainerViewController *dictDetailContainer = [[DictDetailContainerViewController alloc] initWithNibName:@"DictDetailContainerViewController" bundle:nil];
        dictDetailContainer.wordObj = wordObj;
        dictDetailContainer.showLazzyBeeTab = NO;
        [self.navigationController pushViewController:dictDetailContainer animated:YES];
    }
}
@end
