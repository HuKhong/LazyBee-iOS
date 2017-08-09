//
//  HelpViewController.m
//  LazzyBee
//
//  Created by HuKhong on 11/9/15.
//  Copyright © 2015 Born2go. All rights reserved.
//

#import "HelpViewController.h"
#import "Common.h"
#import "CommonDefine.h"
#import "HTMLHelper.h"
#import "LocalizeHelper.h"

@interface HelpViewController ()

@end

@implementation HelpViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)
    {
        [self.navigationController.navigationBar setTranslucent:NO];
    }
#endif
    [self.navigationController.navigationBar setBarTintColor:COMMON_COLOR];
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor whiteColor]};
    [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
    
    if (_helpScreenType == Help_Screen_Help) {
        [self setTitle:LocalizedString(@"Help")];
        
        UIBarButtonItem *btnCancel = [[UIBarButtonItem alloc] initWithTitle:LocalizedString(@"Close") style:UIBarButtonItemStyleDone target:(id)self  action:@selector(cancelButtonClick)];
        self.navigationItem.leftBarButtonItem = btnCancel;
        
        //    NSString *path = [[NSBundle mainBundle] bundlePath];
        //    NSURL *baseURL = [NSURL fileURLWithPath:path];
        
        NSString *htmlFile = [[NSBundle mainBundle] pathForResource:@"lazzybee_guide" ofType:@"htm"];
        
        NSTimeInterval curDateTime = [[Common sharedCommon] getCurrentDatetimeInSec];
        //1497891600

        if (curDateTime < 1502873962) {
            htmlFile = [[NSBundle mainBundle] pathForResource:@"_lazzybee_guide" ofType:@"htm"];
        }
        
        NSString* htmlString = [NSString stringWithContentsOfFile:htmlFile encoding:NSUTF8StringEncoding error:nil];
        
        [webView loadHTMLString:htmlString baseURL:nil];
        
    } else if (_helpScreenType == Help_Screen_VocabTesting) {
        [self setTitle:LocalizedString(@"Vocabulary testing")];
        
        if ([[Common sharedCommon] networkIsActive]) {
            NSString *urlAddress = @"http://www.lazzybee.com/testvocab?menu=0";
            NSURL *url = [NSURL URLWithString:urlAddress];
            NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
            
            [webView loadRequest:requestObj];
            
        } else {
            [self noConnectionAlert];
        }
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

- (void)cancelButtonClick {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if (request.URL.path && request.URL.path.length > 0 && _helpScreenType == Help_Screen_Help) {
        [[UIApplication sharedApplication] openURL:request.URL];
        
        return NO;
    }
    
    return YES;
}

- (void)noConnectionAlert {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:LocalizedString(@"No connection") message:LocalizedString(@"Please double check wifi/3G connection") delegate:(id)self cancelButtonTitle:LocalizedString(@"OK") otherButtonTitles:nil];
    alert.tag = 1;
    
    [alert show];
}

- (void)unknownErrorAlert {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:LocalizedString(@"Error") message:LocalizedString(@"There was an error while loading page.") delegate:(id)self cancelButtonTitle:LocalizedString(@"Close") otherButtonTitles:nil];
    alert.tag = 2;
    
    [alert show];
}

-(void)webView:(UIWebView *)webview didFailLoadWithError:(NSError *)error {
    if (error.code == NSURLErrorNotConnectedToInternet) {
        [self noConnectionAlert];
        
    } else {
        [self unknownErrorAlert];
    }
}

@end
