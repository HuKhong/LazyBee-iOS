//
//  RearTableViewCell.m
//  LazzyBee
//
//  Created by HuKhong on 3/4/15.
//  Copyright (c) 2015 HuKhong. All rights reserved.
//

#import "RearTableViewCell.h"

@implementation RearTableViewCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)startAlertAnimation {
    self.imgArrow.hidden = NO;
    self.imgArrow.animationDuration = 1;
    self.imgArrow.animationRepeatCount = 1000;
    self.imgArrow.animationImages = @[[UIImage imageNamed:@"ic_alert"], [UIImage imageNamed:@"ic_alert_white"]];
    
    [self.imgArrow startAnimating];
}

- (void)stopAlertAnimation {
    self.imgArrow.hidden = YES;
    [self.imgArrow stopAnimating];
}
@end
