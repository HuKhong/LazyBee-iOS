//
//  ChangeLanguageViewController.m
//  LazzyBee
//
//  Created by HuKhong on 3/3/15.
//  Copyright (c) 2015 HuKhong. All rights reserved.
//

#import "ChangeLanguageViewController.h"
#import "LocalizeHelper.h"
#import "CommonDefine.h"

@import FirebaseAnalytics;

@interface ChangeLanguageViewController ()

@end

@implementation ChangeLanguageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self setTitle:LocalizedString(@"Language")];
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

#pragma table delegate
//Data Source
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
    
    return LanguageMax;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *changeLanguageCellId = @"ChangeLanguageCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:changeLanguageCellId];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:changeLanguageCellId];
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    cell.textLabel.textColor = [UIColor darkGrayColor];
    cell.textLabel.font = [UIFont systemFontOfSize:16];
    
    NSString *curLang = [[NSUserDefaults standardUserDefaults] objectForKey:@"CurrentLanguageInApp"];
    
    switch (indexPath.row) {
        case LanguageEnglish:
            cell.textLabel.text = LocalizedString(@"English");

            if (curLang && [curLang isEqualToString:@"en"]) {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            } else {
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
            break;
            
        case LanguageViet:
            cell.textLabel.text = LocalizedString(@"Tiếng Việt");

            if (curLang && [curLang isEqualToString:@"vi"]) {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            } else {
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
            break;
            
        default:
            break;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    UITableViewCell *selectedCell = [tableView cellForRowAtIndexPath:indexPath];
    selectedCell.accessoryType = UITableViewCellAccessoryCheckmark;
    
    switch (indexPath.row) {
        case LanguageEnglish:
            LocalizationSetLanguage(@"en");
            [[NSUserDefaults standardUserDefaults] setObject:@"en" forKey:@"CurrentLanguageInApp"];
            
            [FIRAnalytics setUserPropertyString:@"en" forName:PROPERTY_SELECTED_LANG];
            
            break;
            
        case LanguageViet:
            LocalizationSetLanguage(@"vi");
            [[NSUserDefaults standardUserDefaults] setObject:@"vi" forKey:@"CurrentLanguageInApp"];
            
            [FIRAnalytics setUserPropertyString:@"vi" forName:PROPERTY_SELECTED_LANG];
            
            break;
            
        default:
            break;
    }
    
    [tableView reloadData];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"changeLanguage" object:nil];
    [self setTitle:LocalizedString(@"Language")];
}
@end
