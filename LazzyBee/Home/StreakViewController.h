//
//  StreakViewController.h
//  LazzyBee
//
//  Created by HuKhong on 11/8/15.
//  Copyright © 2015 Born2go. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface StreakViewController : UIViewController
{
    IBOutlet UILabel *lbStreakCount;
    IBOutlet UILabel *lbCongratulation;
    IBOutlet UIImageView *imgRingStreak;
    IBOutlet UILabel *lbLink;
    
    
    IBOutlet UIView *viewDayOne;
    IBOutlet UIView *viewDayTwo;
    IBOutlet UIView *viewDayThree;
    IBOutlet UIView *viewDayFour;
    IBOutlet UIView *viewDayFive;
    IBOutlet UIView *viewDaySix;
    IBOutlet UIView *viewDaySeven;
    IBOutlet UIView *dayContainer;
    
    
    IBOutlet UIScrollView *scrollViewContainer;
    IBOutlet UIButton *btnContinue;
}
@end
