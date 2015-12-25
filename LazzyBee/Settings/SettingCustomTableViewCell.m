//
//  SettingCustomTableViewCell.m
//  LazzyBee
//
//  Created by HuKhong on 12/24/15.
//  Copyright © 2015 Born2go. All rights reserved.
//

#import "SettingCustomTableViewCell.h"

@implementation SettingCustomTableViewCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)startAlertAnimation {
    self.imgRightImage.hidden = NO;
    self.imgRightImage.animationDuration = 1;
    self.imgRightImage.animationRepeatCount = 1000;
    self.imgRightImage.animationImages = @[[UIImage imageNamed:@"ic_alert"], [UIImage imageNamed:@"ic_alert_white"]];
    
    [self.imgRightImage startAnimating];
}

- (void)stopAlertAnimation {
    self.imgRightImage.hidden = YES;
    [self.imgRightImage stopAnimating];
}

@end
