//
//  SearchViewController.m
//  LazzyBee
//
//  Created by HuKhong on 6/4/15.
//  Copyright (c) 2015 HuKhong. All rights reserved.
//

#import "SearchViewController.h"
#import "StudiedListViewController.h"
#import "CommonDefine.h"

@interface SearchViewController ()
{
    NSTimer *hintTimer;
    NSInteger hintCountDown;
    
    StudiedListViewController *searchHintViewController;
}
@end

@implementation SearchViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [searchBarControl becomeFirstResponder];
    
    searchBarControl.autocapitalizationType = UITextAutocapitalizationTypeNone;
    
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didSelectRowFromSearch:)
                                                 name:@"didSelectRowFromSearch"
                                               object:nil];
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

//- (void)viewDidAppear:(BOOL)animated {
   // [searchBarContainer setBackgroundColor:[UIColor whiteColor]];
 //   [searchBarControl setBarTintColor:COMMON_COLOR];
 //   [searchBarControl setBackgroundColor:[UIColor whiteColor]];
 //   [searchBarControl setTintColor:[UIColor whiteColor]];
//}


#pragma mark - keyboard movements
//- (void)keyboardWillShow:(NSNotification *)notification {
//    CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
//    
//    [UIView animateWithDuration:0.3 animations:^{
//
//    }];
//}
//
//-(void)keyboardWillHide:(NSNotification *)notification {
//    [UIView animateWithDuration:0.3 animations:^{
//
//    }];
//}

- (IBAction)tapGestureHandle:(id)sender {
    [self.view removeFromSuperview];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)uisearchBar {
    [self.view removeFromSuperview];

    NSString *searchText = [searchBarControl.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if (searchText.length > 0) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"searchBarSearchButtonClicked" object:searchText];
    }
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)uisearchBar {
    [self.view removeFromSuperview];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    hintCountDown = 1;
    [hintTimer invalidate];
    hintTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(hintCounter) userInfo:nil repeats:YES];
    [self hintCounter];
}

- (void)hintCounter {
    hintCountDown--;
    
    if (hintCountDown == 0) {
        [hintTimer invalidate];
        NSString *searchText = [searchBarControl.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        if (searchText.length > 0) {
            
            if (!searchHintViewController) {
                //add searching result view, use studiedlistviewcontroller
                searchHintViewController = [[StudiedListViewController alloc] initWithNibName:@"StudiedListViewController" bundle:nil];
                searchHintViewController.screenType = List_SearchHint;
                
                searchHintViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth |                                             UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin;
                
                [searchHintViewController.view setFrame:searchResultView.frame];
            }
            
            [self.view insertSubview:searchHintViewController.view belowSubview:searchBarContainer];

            
            searchHintViewController.searchText = searchText;
            
            [searchHintViewController tableReload];
            
        } else {
            [searchHintViewController.view removeFromSuperview];
        }
    }
}

- (void)didSelectRowFromSearch:(NSNotification *)notification {
    [self.view removeFromSuperview];
}
@end
