//
//  CreateCustomListViewController.h
//  LazzyBee
//
//  Created by HuKhong on 8/2/16.
//  Copyright © 2016 Born2go. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CreateCustomListViewController : UIViewController
{
    IBOutlet UITableView *wordsTableView;
    
}

@property (nonatomic, strong) NSMutableArray *wordsArray;

@end
