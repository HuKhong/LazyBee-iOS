//
//  RearTableViewCell.h
//  LazzyBee
//
//  Created by HuKhong on 3/4/15.
//  Copyright (c) 2015 HuKhong. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RearTableViewCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UIImageView *imgIcon;
@property (strong, nonatomic) IBOutlet UILabel *lbTitle;
@property (strong, nonatomic) IBOutlet UIImageView *imgArrow;

- (void)startAlertAnimation;
- (void)stopAlertAnimation;
@end
