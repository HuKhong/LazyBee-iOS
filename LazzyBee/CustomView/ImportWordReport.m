//
//  ImportWordReport.m
//  LazzyBee
//
//  Created by HuKhong on 6/4/15.
//  Copyright (c) 2015 HuKhong. All rights reserved.
//

#import "ImportWordReport.h"
#import "CommonSqlite.h"
#import "WordObject.h"
#import "CommonDefine.h"
#import "TagManagerHelper.h"
#import "LocalizeHelper.h"


@import FirebaseAnalytics;

@interface ImportWordReport ()
{

}
@end

@implementation ImportWordReport

- (void)viewDidLoad {
    [super viewDidLoad];
    [TagManagerHelper pushOpenScreenEvent:@"iImportWordReport"];
    [FIRAnalytics logEventWithName:@"Open_iImportWordReport" parameters:@{
                                                                      kFIRParameterValue:@(1)
                                                                      }];
    
    // Do any additional setup after loading the view from its nib.
    [viewTitle setBackgroundColor:COMMON_COLOR];
    lbTitle.text = LocalizedString(@"Import completed");
    
    lbNewWord.text = LocalizedString(@"New word:");
    lbNotFound.text = LocalizedString(@"Not found:");
    
    lbNewWordCount.text = [NSString stringWithFormat:@"%ld %@", (long)_newWordCount, LocalizedString(@"word(s)")];
    lbNotFoundCount.text = [NSString stringWithFormat:@"%ld %@", (long)[_notFoundArray count], LocalizedString(@"word(s)")];
    
    if ([_notFoundArray count] > 0) {
        NSString *content = @"";
        NSString *w = @"";
        for (int i = 0; i < [_notFoundArray count]; i++) {
            w = [_notFoundArray objectAtIndex:i];
            
            if (i == 0) {
                content = w;
                
            } else {
                content = [content stringByAppendingFormat:@" - %@", w];
            }
        }
        
        txtContent.text = content;
        [txtContent setTextColor:[UIColor darkGrayColor]];
        
    } else {
        txtContent.text = LocalizedString(@"Your custom list has been imported successfully.");
        [txtContent setTextColor:[UIColor darkGrayColor]];
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
- (IBAction)tapGestureHandle:(id)sender {
    [UIView animateWithDuration:0.3 animations:^(void) {
        self.view.alpha = 0;
    } completion:^(BOOL finished) {
        [self.view removeFromSuperview];
    }];
}

- (IBAction)cancelBtnClick:(id)sender {
    
    [UIView animateWithDuration:0.3 animations:^(void) {
        self.view.alpha = 0;
    } completion:^(BOOL finished) {
        [self.view removeFromSuperview];
    }];
}

- (void)loadInformation {

}

- (IBAction)btnContinueClick:(id)sender {
    [UIView animateWithDuration:0.3 animations:^(void) {
        self.view.alpha = 0;
    } completion:^(BOOL finished) {
        [self.view removeFromSuperview];
    }];
}
@end
