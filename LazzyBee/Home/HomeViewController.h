//
//  HomeViewController.h
//  LazzyBee
//
//  Created by nobody on 8/3/15.
//  Copyright (c) 2015 Born2go. All rights reserved.
//

#import <UIKit/UIKit.h>
@import GoogleMobileAds;

@interface HomeViewController : UIViewController
{
    IBOutlet UIButton *btnStudy;
    IBOutlet UIButton *btnIncoming;
    IBOutlet UIButton *btnMore;
    IBOutlet UIView *viewInformation;
    IBOutlet UITextField *txtSearchbox;
    IBOutlet UIView *viewResultContainer;
    IBOutlet UIView *viewSearchContainer;

}

@property (weak, nonatomic) IBOutlet GADBannerView *adBanner;

@end
