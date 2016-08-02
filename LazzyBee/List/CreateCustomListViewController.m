//
//  CreateCustomListViewController.m
//  LazzyBee
//
//  Created by HuKhong on 8/2/16.
//  Copyright © 2016 Born2go. All rights reserved.
//

#import "CreateCustomListViewController.h"
#import "AddMoreCell.h"
#import "AddWordCell.h"

@interface CreateCustomListViewController ()

@end

@implementation CreateCustomListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    if (_wordsArray == nil) {
        _wordsArray = [[NSMutableArray alloc] init];
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

#pragma mark data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    // Return the number of sections.
    
    return 1;
    
}



- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    // Return the number of rows in the section.
    
    // If you're serving data from an array, return the length of the array:
    
    return [_wordsArray count] + 1; //+1 for "add" cell
    
}



- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return 44.0;
    
}



- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.row < [_wordsArray count]) {
        static NSString *addWordCellIdentifier = @"AddWordCell";
        
        AddWordCell *cell = [tableView dequeueReusableCellWithIdentifier:addWordCellIdentifier];
        if (cell == nil) {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"AddWordCell" owner:self options:nil];
            cell = [nib objectAtIndex:0];
        }
        
        // Set the data for this cell:
        cell.txtOther.text = [_wordsArray objectAtIndex:indexPath.row];
        
        return cell;
        
    } else {
        static NSString *addMoreCellIdentifier = @"AddMoreCell";
        
        AddMoreCell *cell = [tableView dequeueReusableCellWithIdentifier:addMoreCellIdentifier];
        if (cell == nil) {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"AddMoreCell" owner:self options:nil];
            cell = [nib objectAtIndex:0];
        }
        
        return cell;
    }
    
}



#pragma mark table delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
 
}
@end
