//
//  DailyTargetViewController.m
//  LazzyBee
//
//  Created by HuKhong on 9/10/15.
//  Copyright (c) 2015 Born2go. All rights reserved.
//

#import "DailyTargetViewController.h"
#import "Common.h"
#import "LocalizeHelper.h"

#define NEW_WORD_OPTION_MAX 5
#define TOTAL_OPTION_MAX 5

#define OPTION_VERY_EASY 0
#define OPTION_EASY 1
#define OPTION_NORMAL 2
#define OPTION_HARD 3
#define OPTION_IMPOSSIBLE 4

#define TOTAL_OPTION_VERY_EASY 20
#define TOTAL_OPTION_EASY 30
#define TOTAL_OPTION_NORMAL 40
#define TOTAL_OPTION_HARD 60
#define TOTAL_OPTION_IMPOSSIBLE 80

@interface DailyTargetViewController ()
{
    NSIndexPath *selectedIndexPath;
}
@end

@implementation DailyTargetViewController

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
    
    if (_targetType == NewWordTargetType) {
        [self setTitle:LocalizedString(@"Daily new words")];
        
        NSNumber *targetNumberObj = [[Common sharedCommon] loadDataFromUserDefaultStandardWithKey:KEY_DAILY_TARGET];
        
        if (targetNumberObj) {
            selectedIndexPath = [NSIndexPath indexPathForRow:([targetNumberObj integerValue]/5) inSection:0];
        }
        
    } else {
        [self setTitle:LocalizedString(@"Daily total words")];
        
        NSNumber *targetNumberObj = [[Common sharedCommon] loadDataFromUserDefaultStandardWithKey:KEY_DAILY_TOTAL_TARGET];
        
        if (targetNumberObj) {
            selectedIndexPath = [NSIndexPath indexPathForRow:[self whatRowItIs:[targetNumberObj integerValue]] inSection:0];
        }
    }
    
    UIBarButtonItem *btnCancel = [[UIBarButtonItem alloc] initWithTitle:LocalizedString(@"Cancel") style:UIBarButtonItemStylePlain target:(id)self  action:@selector(cancelButtonClick)];
    self.navigationItem.leftBarButtonItem = btnCancel;
    
    UIBarButtonItem *btnDone = [[UIBarButtonItem alloc] initWithTitle:LocalizedString(@"Done") style:UIBarButtonItemStylePlain target:(id)self  action:@selector(doneButtonClick)];
    self.navigationItem.rightBarButtonItem = btnDone;
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
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)doneButtonClick {
    
    if (_targetType == NewWordTargetType) {
        NSInteger target = (selectedIndexPath.row) * 5;
        NSNumber *targetNumberObj = [NSNumber numberWithInteger:target];
        [[Common sharedCommon] saveDataToUserDefaultStandard:targetNumberObj withKey:KEY_DAILY_TARGET];
        
    } else {
        NSInteger target = [self whatValueItIs:selectedIndexPath.row];
        NSNumber *targetNumberObj = [NSNumber numberWithInteger:target];
        [[Common sharedCommon] saveDataToUserDefaultStandard:targetNumberObj withKey:KEY_DAILY_TOTAL_TARGET];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"updateSettingsScreen" object:nil];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark data source
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 40.0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    // If you're serving data from an array, return the length of the array:
    
    if (_targetType == NewWordTargetType) {
        return NEW_WORD_OPTION_MAX;
        
    } else if (_targetType == TotalTargetType) {
        return TOTAL_OPTION_MAX;
    }
    
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *dailyOptionCellIdentifier = @"DailyOptionCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:dailyOptionCellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:dailyOptionCellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    cell.textLabel.font = [UIFont systemFontOfSize:16];
    cell.textLabel.textColor = [UIColor darkGrayColor];
    
    if (indexPath.row == selectedIndexPath.row) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    if (_targetType == NewWordTargetType) {
        if (indexPath.row == OPTION_VERY_EASY) {
            cell.textLabel.text = [NSString stringWithFormat:@"0 %@ - %@", LocalizedString(@"words"), LocalizedString(@"Relax")];
            
        } else if (indexPath.row == OPTION_EASY) {
            cell.textLabel.text = [NSString stringWithFormat:@"5 %@ - %@", LocalizedString(@"words"), LocalizedString(@"Easy")];
            
        } else if (indexPath.row == OPTION_NORMAL) {
            cell.textLabel.text = [NSString stringWithFormat:@"10 %@ - %@", LocalizedString(@"words"), LocalizedString(@"Normal")];
            
        } else if (indexPath.row == OPTION_HARD) {
            cell.textLabel.text = [NSString stringWithFormat:@"15 %@ - %@", LocalizedString(@"words"), LocalizedString(@"Hard")];
            
        } else if (indexPath.row == OPTION_IMPOSSIBLE) {
            cell.textLabel.text = [NSString stringWithFormat:@"20 %@ - %@", LocalizedString(@"words"), LocalizedString(@"Impossible")];
        }
        
    } else {
        if (indexPath.row == OPTION_VERY_EASY) {
            cell.textLabel.text = [NSString stringWithFormat:@"%d %@ - %@", TOTAL_OPTION_VERY_EASY, LocalizedString(@"words"), LocalizedString(@"Very easy")];
            
        } else if (indexPath.row == OPTION_EASY) {
            cell.textLabel.text = [NSString stringWithFormat:@"%d %@ - %@", TOTAL_OPTION_EASY, LocalizedString(@"words"), LocalizedString(@"Easy")];
            
        } else if (indexPath.row == OPTION_NORMAL) {
            cell.textLabel.text = [NSString stringWithFormat:@"%d %@ - %@", TOTAL_OPTION_NORMAL, LocalizedString(@"words"), LocalizedString(@"Normal")];
            
        } else if (indexPath.row == OPTION_HARD) {
            cell.textLabel.text = [NSString stringWithFormat:@"%d %@ - %@", TOTAL_OPTION_HARD, LocalizedString(@"words"), LocalizedString(@"Hard")];
            
        } else if (indexPath.row == OPTION_IMPOSSIBLE) {
            cell.textLabel.text = [NSString stringWithFormat:@"%d %@ - %@", TOTAL_OPTION_IMPOSSIBLE, LocalizedString(@"words"), LocalizedString(@"Impossible")];
        }
    }
    
    return cell;
}

#pragma mark table delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.row != selectedIndexPath.row) {
        selectedIndexPath = indexPath;
        
        [tableView reloadData];
    }
}

- (NSInteger)whatRowItIs:(NSInteger)value {
    NSInteger row = 0;
    
    if (value == TOTAL_OPTION_VERY_EASY) {
        row = 0;
        
    } else if (value == TOTAL_OPTION_EASY) {
        row = 1;
        
    } else if (value == TOTAL_OPTION_NORMAL) {
        row = 2;
    } else if (value == TOTAL_OPTION_HARD) {
        row = 3;
        
    } else if (value == TOTAL_OPTION_IMPOSSIBLE) {
        row = 4;
    }
    
    return row;
}

- (NSInteger)whatValueItIs:(NSInteger)row {
    NSInteger value = 0;
    
    if (row == 0) {
        value = TOTAL_OPTION_VERY_EASY;
        
    } else if (row == 1) {
        value = TOTAL_OPTION_EASY;
        
    } else if (row == 2) {
        value = TOTAL_OPTION_NORMAL;
        
    } else if (row == 3) {
        value = TOTAL_OPTION_HARD;
        
    } else if (row == 4) {
        value = TOTAL_OPTION_IMPOSSIBLE;
    }
    
    return value;
}
@end
