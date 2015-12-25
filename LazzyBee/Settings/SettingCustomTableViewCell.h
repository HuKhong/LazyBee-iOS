//
//  SettingCustomTableViewCell.h
//  LazzyBee
//
//  Created by HuKhong on 12/24/15.
//  Copyright © 2015 Born2go. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SettingCustomTableViewCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UILabel *lbTitle;
@property (strong, nonatomic) IBOutlet UIImageView *imgRightImage;

- (void)startAlertAnimation;
- (void)stopAlertAnimation;
@end
