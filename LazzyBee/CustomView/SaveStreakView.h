//
//  SaveStreakView.h
//  LazzyBee
//
//  Created by HuKhong on 6/4/15.
//  Copyright (c) 2015 HuKhong. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SaveStreakView : UIViewController
{
    IBOutlet UIButton *btnSubmit;

    IBOutlet UILabel *lbSaveStreakTitle;
    IBOutlet UILabel *saveStreakGuide;
//    IBOutlet UIView *viewContainer;
}

@property (strong, nonatomic) IBOutlet UIView *viewContainer;
@property (assign, nonatomic) NSInteger missingCount;
@end
