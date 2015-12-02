//
//  DictDetailContainerViewController.h
//  LazzyBee
//
//  Created by HuKhong on 10/8/15.
//  Copyright © 2015 Born2go. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WordObject.h"
@import GoogleMobileAds;

@interface DictDetailContainerViewController : UIViewController
{
    
}

@property (nonatomic, strong) WordObject *wordObj;
@property (nonatomic, assign) BOOL showLazzyBeeTab;

@property (weak, nonatomic) IBOutlet GADBannerView *adBanner;
@end
