//
//  AboutViewController.m
//  LazzyBee
//
//  Created by HuKhong on 3/3/15.
//  Copyright (c) 2015 HuKhong. All rights reserved.
//

#import "AboutViewController.h"
#import "TagManagerHelper.h"
#import "Common.h"
#import "LocalizeHelper.h"

@import FirebaseAnalytics;

@interface AboutViewController ()

@end

@implementation AboutViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [TagManagerHelper pushOpenScreenEvent:@"iAbout"];
    [FIRAnalytics logEventWithName:@"Open_iAbout" parameters:@{
                                                             kFIRParameterQuantity:@(1)
                                                             }];
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
    
    [self setTitle:LocalizedString(@"About")];
    
    [self getAboutFromFile];
    
    [loadingIndicator setColor:COMMON_COLOR];
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

- (void)getAboutFromFile {
    NSString* path = @"";

    path = [[NSBundle mainBundle] pathForResource:@"About"
                                               ofType:@"txt"];
    
    NSString* contentFile = [NSString stringWithContentsOfFile:path
                                                      encoding:NSUTF8StringEncoding
                                                         error:NULL];
    
    txtAboutContent.text = contentFile;
    
    [txtAboutContent setFont:[UIFont systemFontOfSize:16]];
}
@end
