//
//  ReverseViewController.m
//  LazzyBee
//
//  Created by HuKhong on 5/25/16.
//  Copyright © 2016 Born2go. All rights reserved.
//

#import "ReverseViewController.h"
#import "SearchViewController.h"
#import "CommonSqlite.h"
#import "GTMHTTPFetcher.h"
#import "GTLDataServiceApi.h"
#import "TagManagerHelper.h"
#import "HTMLHelper.h"
#import "LocalizeHelper.h"
#import "AppDelegate.h"
#import "Common.h"

@interface ReverseViewController ()
{
    NSArray *wordArr;
    WordObject *wordObj;
    
    SearchViewController *searchView;
}
@end

@implementation ReverseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [TagManagerHelper pushOpenScreenEvent:@"iStudyScreen"];
    
    //border webview
    //    webViewWord.layer.borderColor = [UIColor darkGrayColor].CGColor;
    //    webViewWord.layer.borderWidth = 1.0f;
    //
    webView.layer.masksToBounds = NO;
    webView.layer.shadowOffset = CGSizeMake(0, 5);
    webView.layer.shadowRadius = 5;
    webView.layer.shadowOpacity = 0.5;
    
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
    
    UIBarButtonItem *searchButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(showSearchBar)];
    UIBarButtonItem *actionButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(showActionsPanel:)];
    
    self.navigationItem.rightBarButtonItems = @[actionButton, searchButton];
    
    [self setTitle:LocalizedString(@"Reverse")];
    
    wordArr = [[CommonSqlite sharedCommonSqlite] getStudiedList];
    
    if ([wordArr count] > 0) {
        int randomIndex = arc4random() % ([wordArr count]);
        wordObj = [wordArr objectAtIndex:randomIndex];
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

    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:(id)self cancelButtonTitle:LocalizedString(@"Cancel") destructiveButtonTitle:nil otherButtonTitles:LocalizedString(@"Learn again"), LocalizedString(@"Ignore"), LocalizedString(@"Done"), LocalizedString(@"Dictionary"), LocalizedString(@"Update"), LocalizedString(@"Report"), nil];

    actionSheet.tag = 1;
    actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;

    if (IS_IPAD) {
        [actionSheet showFromBarButtonItem:sender animated:YES];
    } else {
        [actionSheet showInView:self.view];
    }

}
@end
