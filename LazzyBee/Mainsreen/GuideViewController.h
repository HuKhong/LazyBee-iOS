//
//  GuideViewController.h
//  LazzyBee
//
//  Created by HuKhong on 9/11/15.
//  Copyright (c) 2015 Born2go. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol TimerPickerViewDelegate <NSObject>

@optional // Delegate protocols

@end

@interface GuideViewController : UIViewController
{
    IBOutlet UIView *viewContainer;
    IBOutlet UIButton *btnClose;
    IBOutlet UIButton *btnGotIt;
    IBOutlet UILabel *lbGuide;

    IBOutlet UIView *viewButtonsPanel;
    
}

@end
