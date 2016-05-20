//
//  GuideViewController.m
//  LazzyBee
//
//  Created by HuKhong on 9/11/15.
//  Copyright (c) 2015 Born2go. All rights reserved.
//

#import "GuideViewController.h"
#import "CommonDefine.h"
#import "Common.h"
#import "LocalizeHelper.h"

#define DATE_FORMATE @"yyyy-MM-dd EEEE"

@interface GuideViewController ()
{
    NSTimer *timer;
}
@end

@implementation GuideViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.

    viewContainer.layer.borderColor = [UIColor darkGrayColor].CGColor;
    viewContainer.layer.borderWidth = 3.0f;
    
    viewContainer.layer.cornerRadius = 5.0f;
    viewContainer.clipsToBounds = YES;
    
    viewContainer.layer.masksToBounds = NO;
    viewContainer.layer.shadowOffset = CGSizeMake(-5, 10);
    viewContainer.layer.shadowRadius = 5;
    viewContainer.layer.shadowOpacity = 0.5;

    viewButtonsPanel.layer.borderColor = [COMMON_COLOR CGColor];
    viewButtonsPanel.layer.borderWidth = 3.0f;
    
    viewButtonsPanel.layer.cornerRadius = 5.0f;
    viewButtonsPanel.clipsToBounds = YES;
    
    lbGuide.text = LocalizedString(@"Learning guide");
    [btnClose setTitle:LocalizedString(@"Close") forState:UIControlStateNormal];
    [btnGotIt setTitle:LocalizedString(@"Got it") forState:UIControlStateNormal];
    
    timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(blinkView) userInfo:nil repeats:YES];
    
    
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


- (IBAction)tapGestureHandle:(id)sender {
    /*
    [UIView animateWithDuration:0.3 animations:^(void) {
        self.view.alpha = 0;
    } completion:^(BOOL finished) {
        [self.view removeFromSuperview];
    }];
     */
}

- (IBAction)btnCloseClick:(id)sender {
    [timer invalidate];
    [UIView animateWithDuration:0.3 animations:^(void) {
        self.view.alpha = 0;
    } completion:^(BOOL finished) {
        [self.view removeFromSuperview];
    }];
}


- (IBAction)btnGotItClick:(id)sender {
    [timer invalidate];
    [UIView animateWithDuration:0.3 animations:^(void) {
        self.view.alpha = 0;
        
        //update flag
        [[Common sharedCommon] saveDataToUserDefaultStandard:[NSNumber numberWithBool:NO] withKey:KEY_SHOW_GUIDE];
        
    } completion:^(BOOL finished) {
        [self.view removeFromSuperview];
    }];
}

- (void)blinkView {

    [UIView animateWithDuration:0.3 animations:^(void) {
        viewButtonsPanel.alpha = 0;
        
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.3 animations:^(void) {
            viewButtonsPanel.alpha = 1;
            
        }];
    }];
}
@end
