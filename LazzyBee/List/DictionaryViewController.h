//
//  DictionaryViewController.h
//  LazzyBee
//
//  Created by HuKhong on 10/7/15.
//  Copyright © 2015 Born2go. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DictionaryViewController : UIViewController<UISearchDisplayDelegate, UISearchBarDelegate>
{
    IBOutlet UITableView *dictTableView;
    
}

@property (strong, nonatomic) UISearchController *searchController;
@end
