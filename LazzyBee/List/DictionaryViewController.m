//
//  DictionaryViewController.m
//  LazzyBee
//
//  Created by HuKhong on 10/7/15.
//  Copyright © 2015 Born2go. All rights reserved.
//

#import "DictionaryViewController.h"
#import "CommonSqlite.h"
#import "WordObject.h"
#import "CommonDefine.h"
#import "SVProgressHUD.h"
#import "MHTabBarController.h"
#import "DictDetailContainerViewController.h"
#import "StudiedListViewController.h"
#import "TagManagerHelper.h"
#import "LocalizeHelper.h"

@import FirebaseAnalytics;

@interface DictionaryViewController ()
{
    NSMutableArray *wordsArray;
    NSMutableArray *searchResults;
//    NSMutableDictionary *dataDic;
}
@end

@implementation DictionaryViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [TagManagerHelper pushOpenScreenEvent:@"iDictionaryScreen"];
    [FIRAnalytics logEventWithName:@"Open_iDictionaryScreen" parameters:@{
                                                                                  kFIRParameterValue:@(1)
                                                                                  }];
    
    [self.navigationController.navigationBar setTranslucent:NO];
    [self.navigationController.navigationBar setBarTintColor:[UIColor whiteColor]];
    
    [self.navigationController.navigationBar setBarTintColor:COMMON_COLOR];
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor whiteColor]};
    [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
    
    [self setTitle:LocalizedString(@"Dictionary")];
    
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = (id)self;
    
    self.searchController.searchBar.delegate = (id)self;
    self.searchController.delegate = (id)self;
    self.searchController.dimsBackgroundDuringPresentation = NO; // default is YES
    
    dictTableView.tableHeaderView = self.searchController.searchBar;
    self.definesPresentationContext = YES;
    
    [self.searchController.searchBar sizeToFit];
    [self.searchController.searchBar setPlaceholder:LocalizedString(@"Search")];
    
    self.searchController.searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
    
    if (searchResults == nil) {
        searchResults = [[NSMutableArray alloc] init];
    }
    
//    if (dataDic == nil) {
//        dataDic = [[NSMutableDictionary alloc] init];
//    }
    
    if (wordsArray == nil) {
        wordsArray = [[NSMutableArray alloc] init];
    }
    
    [SVProgressHUD show];
    dispatch_queue_t taskQ = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    dispatch_async(taskQ, ^{
        [wordsArray addObjectsFromArray:[[CommonSqlite sharedCommonSqlite] getAllWords]];
        
        NSSortDescriptor *sortWord = [NSSortDescriptor sortDescriptorWithKey:@"question" ascending:YES];
        
        NSArray *sortDescriptionArr = [NSArray arrayWithObjects:sortWord, nil];
        [wordsArray sortUsingDescriptors:sortDescriptionArr];
        NSLog(@"All :: %lu", (unsigned long)[wordsArray count]);
        dispatch_sync(dispatch_get_main_queue(), ^{
            [dictTableView reloadData];
            [SVProgressHUD dismiss];
        });
    });
                   
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

//- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
//    
//    return @"";
//}

//- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
//    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
//    
//    header.textLabel.textColor = [UIColor whiteColor];
//    header.textLabel.font = [UIFont boldSystemFontOfSize:15];
//    CGRect headerFrame = header.frame;
//    header.textLabel.frame = headerFrame;
//    header.textLabel.textAlignment = NSTextAlignmentLeft;
//    
//    header.backgroundView.backgroundColor = [UIColor darkGrayColor];
//}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    // If you're serving data from an array, return the length of the array:
   
    if (self.searchController.active && self.searchController.searchBar.text.length > 0 ) {
        return [searchResults count];
        
    } else {
        return [wordsArray count];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 40.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *dictionaryCellIdentifier = @"DictionaryCellIdentifier";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:dictionaryCellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:dictionaryCellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    cell.textLabel.textColor = [UIColor blackColor];
    cell.textLabel.font = [UIFont systemFontOfSize:16];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    WordObject *wordObj;
    if ([searchResults count] > 0) {
        wordObj = [searchResults objectAtIndex:indexPath.row];
        
    } else {
        wordObj = [wordsArray objectAtIndex:indexPath.row];
    }
    
//    [dataDic setObject:wordObj forKey:wordObj.question];
    
    cell.textLabel.text = wordObj.question;

    return cell;
}

#pragma mark table delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    WordObject *wordObj;
    if ([searchResults count] > 0) {
        wordObj = [searchResults objectAtIndex:indexPath.row];
        
    } else {
        wordObj = [wordsArray objectAtIndex:indexPath.row];
    }
    
    DictDetailContainerViewController *dictDetailContainer = [[DictDetailContainerViewController alloc] initWithNibName:@"DictDetailContainerViewController" bundle:nil];
    dictDetailContainer.wordObj = wordObj;
    dictDetailContainer.showLazzyBeeTab = YES;
    [self.navigationController pushViewController:dictDetailContainer animated:YES];
    
}


#pragma mark - UISearchBarDelegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
    
    StudiedListViewController *searchResultViewController = [[StudiedListViewController alloc] initWithNibName:@"StudiedListViewController" bundle:nil];
    searchResultViewController.screenType = List_SearchResult;
    searchResultViewController.searchText = searchBar.text;
    
    [self.navigationController pushViewController:searchResultViewController animated:YES];
}


#pragma mark - UISearchControllerDelegate

// Called after the search controller's search bar has agreed to begin editing or when
// 'active' is set to YES.
// If you choose not to present the controller yourself or do not implement this method,
// a default presentation is performed on your behalf.
//
// Implement this method if the default presentation is not adequate for your purposes.
//
- (void)presentSearchController:(UISearchController *)searchController {
    
}

- (void)willPresentSearchController:(UISearchController *)searchController {
    // do something before the search controller is presented
    searchController.searchBar.showsCancelButton = YES;
    
    for (UIView *subView in searchController.searchBar.subviews){
        for (UIView *subView2 in subView.subviews){
            if([subView2 isKindOfClass:[UIButton class]]){
                [(UIButton*)subView2 setTitle:LocalizedString(@"Cancel") forState:UIControlStateNormal];
            }
        }
    }
}

- (void)didPresentSearchController:(UISearchController *)searchController {
    // do something after the search controller is presented
}

- (void)willDismissSearchController:(UISearchController *)searchController {
    // do something before the search controller is dismissed
}

- (void)didDismissSearchController:(UISearchController *)searchController {
    // do something after the search controller is dismissed
}

#pragma mark - UISearchResultsUpdating

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    // update the filtered array based on the search text
    NSString *searchString = self.searchController.searchBar.text;
    
    [self->searchResults removeAllObjects]; // First clear the filtered array.
    
    if (searchString == nil || searchString.length == 0) {
        self->searchResults = [wordsArray mutableCopy];
        
    } else {
        NSPredicate *filterPredicate = [NSPredicate predicateWithFormat:@"question CONTAINS[cd] %@", searchString];
        
        NSArray *filterKeys = [wordsArray filteredArrayUsingPredicate:filterPredicate];
        self->searchResults = [NSMutableArray arrayWithArray:filterKeys];
    }
    
    [dictTableView reloadData];
}
@end
