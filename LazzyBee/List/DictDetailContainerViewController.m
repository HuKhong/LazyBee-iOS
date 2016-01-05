//
//  DictDetailContainerViewController.m
//  LazzyBee
//
//  Created by HuKhong on 10/8/15.
//  Copyright © 2015 Born2go. All rights reserved.
//

#import "DictDetailContainerViewController.h"
#import "DictDetailViewController.h"
#import "MHTabBarController.h"
#import "TagManagerHelper.h"
#import "CommonSqlite.h"
#import "AppDelegate.h"
#import "Common.h"
#import "SVProgressHUD.h"
#import "GTMHTTPFetcher.h"
#import "GTLDataServiceApi.h"
#import "LocalizeHelper.h"

@interface DictDetailContainerViewController ()
{
    MHTabBarController *tabViewController;
}
@end

@implementation DictDetailContainerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [TagManagerHelper pushOpenScreenEvent:@"iDictionaryViewWordScreen"];
    
    [self setTitle:_wordObj.question];
    
    UIBarButtonItem *actionButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(showActionsPanel:)];
    
    self.navigationItem.rightBarButtonItems = @[actionButton];
    
    //admob
    GADRequest *request = [GADRequest request];
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    TAGContainer *container = appDelegate.container;
//    BOOL enableAds = [[container stringForKey:@"adv_enable"] boolValue];
    BOOL enableAds = YES;
//    if (enableAds) {
    
        NSString *pub_id = [container stringForKey:@"admob_pub_id"];
        NSString *dictionary_id = [container stringForKey:@"adv_dictionary_id"];

        NSString *advStr = [NSString stringWithFormat:@"%@/%@", pub_id,dictionary_id ];
        
        self.adBanner.adUnitID = advStr;//@"ca-app-pub-3940256099942544/2934735716";
        
        self.adBanner.rootViewController = self;
        
        request.testDevices = @[
                                @"687f0b503566ebb7d84524c1f15e1d16"
                                ];
        
        [self.adBanner loadRequest:request];
    
    if (pub_id == nil || pub_id.length == 0 ||
        dictionary_id == nil || dictionary_id.length == 0 ||
        ![[Common sharedCommon] networkIsActive]) {
        enableAds = NO;
    }
    
    if (enableAds) {
        _adBanner.hidden = NO;
    } else {
        _adBanner.hidden = YES;
    }
    
    DictDetailViewController *vnViewController = [[DictDetailViewController alloc] initWithNibName:@"DictDetailViewController" bundle:nil];
    vnViewController.dictType = DictVietnam;
    vnViewController.wordObj = _wordObj;
    vnViewController.title = @"VN";
    
    DictDetailViewController *enViewController = [[DictDetailViewController alloc] initWithNibName:@"DictDetailViewController" bundle:nil];
    enViewController.dictType = DictEnglish;
    enViewController.wordObj = _wordObj;
    enViewController.title = @"EN";
    
    DictDetailViewController *lazzyViewController = [[DictDetailViewController alloc] initWithNibName:@"DictDetailViewController" bundle:nil];
    lazzyViewController.dictType = DictLazzyBee;
    lazzyViewController.wordObj = _wordObj;
    lazzyViewController.title = @"Lazzy Bee";
    
    NSArray *viewControllers = nil;
    
    if (_showLazzyBeeTab) {
        viewControllers = @[vnViewController, enViewController, lazzyViewController];
    } else {
        viewControllers = @[vnViewController, enViewController];
    }
    
    tabViewController = [[MHTabBarController alloc] init];
    
    tabViewController.delegate = (id)self;
    tabViewController.viewControllers = viewControllers;
    
    CGRect rect;

    if (enableAds) {
        rect = self.view.frame;
        rect.size.height = _adBanner.frame.origin.y - 10;
    } else {
        rect = self.view.frame;
    }
    
    [tabViewController.view setFrame:rect];
    
    tabViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth |
                                                UIViewAutoresizingFlexibleHeight |
                                                UIViewAutoresizingFlexibleLeftMargin |
                                                UIViewAutoresizingFlexibleRightMargin |
                                                UIViewAutoresizingFlexibleBottomMargin |
                                                UIViewAutoresizingFlexibleTopMargin;
    
    [self.view addSubview:tabViewController.view];
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

- (void)showActionsPanel:(id)sender {
    UIActionSheet *actionSheet = nil;
    
    if (_showLazzyBeeTab) {
        actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:(id)self cancelButtonTitle:LocalizedString(@"Cancel") destructiveButtonTitle:nil otherButtonTitles:LocalizedString(@"Add to learn"), LocalizedString(@"Update"), LocalizedString(@"Report"), nil];
    } else {
        actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:(id)self cancelButtonTitle:LocalizedString(@"Cancel") destructiveButtonTitle:nil otherButtonTitles:LocalizedString(@"Update"), LocalizedString(@"Report"), nil];

    }
    
    actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
//    [actionSheet showInView:self.view];
    if (IS_IPAD) {
        [actionSheet showFromBarButtonItem:sender animated:YES];
    } else {
        [actionSheet showInView:self.view];
    }
}

- (void) actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {

    //in case showing Lazzybee tab, have 3 buttons on actionsheet
    if (buttonIndex == 0) {
        if (_showLazzyBeeTab) {
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
            
        } else {
            [self updateWordFromGAE];
        }
        
        
    } else if (buttonIndex == 1) {
        if (_showLazzyBeeTab) {
            NSLog(@"Update");
            [self updateWordFromGAE];
            
        } else {
            [self openFacebookToReport];
        }
        
    } else if (buttonIndex == 2) {
        
        if (_showLazzyBeeTab) {
            NSLog(@"Report");
            [self openFacebookToReport];
            
        } else {
            NSLog(@"Cancel");
        }
        
    } else if (buttonIndex == [actionSheet cancelButtonIndex]) {
        
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
                
                [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateWord" object:_wordObj];
            }
            
            [SVProgressHUD dismiss];
        }];
        
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:LocalizedString(@"No connection") message:LocalizedString(@"Please double check wifi/3G connection") delegate:(id)self cancelButtonTitle:LocalizedString(@"OK") otherButtonTitles:nil];
        alert.tag = 2;
        
        [alert show];
    }
}

#pragma mark alert delegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (alertView.tag == 1) {   //report
        if (buttonIndex != 0) {
            
        }
    }
}

- (void)openFacebookToReport {
    NSString *postLink = @"fb://profile/1012100435467230";
    
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:postLink]]) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:postLink]];
        
    } else {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.facebook.com/lazzybees"]];
    }
}
@end
