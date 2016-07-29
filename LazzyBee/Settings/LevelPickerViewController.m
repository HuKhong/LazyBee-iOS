//
//  LevelPickerViewController.m
//  LazzyBee
//
//  Created by HuKhong on 10/2/15.
//  Copyright © 2015 Born2go. All rights reserved.
//

#import "LevelPickerViewController.h"
#import "Common.h"
#import "LocalizeHelper.h"

@import FirebaseAnalytics;

#define MAX_LEVEL 6
#define MAX_TIME 11

@interface LevelPickerViewController ()

@end

@implementation LevelPickerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [btnDone setTitle:LocalizedString(@"Done") forState:UIControlStateNormal];
    
    if (_pickerType == LevelPicker) {
        NSString *level = [[Common sharedCommon] loadDataFromUserDefaultStandardWithKey:KEY_LOWEST_LEVEL];
        
        if (!level) {
            level = @"2";
            [[Common sharedCommon] saveDataToUserDefaultStandard:level withKey:KEY_LOWEST_LEVEL];
        }
        
        [levelPicker selectRow:[level integerValue] - 1 inComponent:0 animated:YES];
        
    } else if (_pickerType == WaitingTimePicker) {
        NSString *time = [[Common sharedCommon] loadDataFromUserDefaultStandardWithKey:KEY_TIME_TO_SHOW_ANSWER];
        
        if (!time) {
            time = @"3";
            [[Common sharedCommon] saveDataToUserDefaultStandard:time withKey:KEY_TIME_TO_SHOW_ANSWER];
        }
        
        [levelPicker selectRow:[time integerValue] inComponent:0 animated:YES];
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

- (IBAction)btnDoneClick:(id)sender {
    if (_pickerType == LevelPicker) {
        NSString *level = [NSString stringWithFormat:@"%ld", [levelPicker selectedRowInComponent:0] + 1];
        [[Common sharedCommon] saveDataToUserDefaultStandard:level withKey:KEY_LOWEST_LEVEL];

        [FIRAnalytics setUserPropertyString:level forName:PROPERTY_SELECTED_LEVEL];

    } else if (_pickerType == WaitingTimePicker) {
        NSString *time = [NSString stringWithFormat:@"%ld", (long)[levelPicker selectedRowInComponent:0]];
        [[Common sharedCommon] saveDataToUserDefaultStandard:time withKey:KEY_TIME_TO_SHOW_ANSWER];
        
        [FIRAnalytics setUserPropertyString:time forName:PROPERTY_SELECTED_WAITING_TIME];

    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"updateSettingsScreen" object:nil];
    
    [UIView animateWithDuration:0.3 animations:^(void) {
        self.view.alpha = 0;
    } completion:^(BOOL finished) {
        [self.view removeFromSuperview];
    }];
}

#pragma mark picker datasource
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    if (_pickerType == LevelPicker) {
        return MAX_LEVEL;
        
    } else if (_pickerType == WaitingTimePicker) {
        return MAX_TIME;
    }
    
    return 0;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    if (_pickerType == LevelPicker) {
        return [NSString stringWithFormat:@"%d", row + 1];
        
    } else if (_pickerType == WaitingTimePicker) {
        return [NSString stringWithFormat:@"%ld", (long)row];
    }
    
    return @"";
}

#pragma mark picker delegate
- (void)pickerView:(UIPickerView *)pV didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
/*    NSString *level = [NSString stringWithFormat:@"%ld", [levelPicker selectedRowInComponent:0] + 1];
    [[Common sharedCommon] saveDataToUserDefaultStandard:level withKey:KEY_LOWEST_LEVEL];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"updateSettingsScreen" object:nil];
    
    [UIView animateWithDuration:0.3 animations:^(void) {
        self.view.alpha = 0;
    } completion:^(BOOL finished) {
        [self.view removeFromSuperview];
    }];
 */
}
@end
