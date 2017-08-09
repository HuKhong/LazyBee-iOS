//
//  SaveStreakView.m
//  LazzyBee
//
//  Created by HuKhong on 6/4/15.
//  Copyright (c) 2015 HuKhong. All rights reserved.
//

#import "SaveStreakView.h"
#import "LocalizeHelper.h"
#import "CommonDefine.h"

#define TEXT_PLACEHOLDER LocalizedString(@"Comment")

@interface SaveStreakView ()
{

}
@end

@implementation SaveStreakView
@synthesize viewContainer = _viewContainer;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.

    _viewContainer.layer.borderColor = COMMON_COLOR.CGColor;
    _viewContainer.layer.borderWidth = 1.0f;
    _viewContainer.layer.cornerRadius = 5.0f;
    _viewContainer.clipsToBounds = YES;
    
    _viewContainer.layer.masksToBounds = NO;
    _viewContainer.layer.shadowOffset = CGSizeMake(-5, 10);
    _viewContainer.layer.shadowRadius = 5;
    _viewContainer.layer.shadowOpacity = 0.5;
    
    NSString *content = LocalizedString(@"Watch ads to save streak");
    content = [NSString stringWithFormat:content, _missingCount];
    
    [btnSubmit setTitle:LocalizedString(@"Watch Ads") forState:UIControlStateNormal];
    saveStreakGuide.text = content;
    lbSaveStreakTitle.text = LocalizedString(@"Save streak");

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

- (void)viewDidAppear:(BOOL)animated {
    
}

- (IBAction)tapGestureHandle:(id)sender {

}

- (IBAction)cancelBtnClick:(id)sender {
    
    [UIView animateWithDuration:0.3 animations:^(void) {
        self.view.alpha = 0;
    } completion:^(BOOL finished) {
        [self.view removeFromSuperview];
    }];
}

- (IBAction)btnWatchClick:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"WatchAds" object:nil];
    
    [UIView animateWithDuration:0.3 animations:^(void) {
        self.view.alpha = 0;
    } completion:^(BOOL finished) {
        [self.view removeFromSuperview];
    }];
}
@end
