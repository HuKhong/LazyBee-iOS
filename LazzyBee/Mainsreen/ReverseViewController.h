//
//  ReverseViewController.h
//  LazzyBee
//
//  Created by HuKhong on 5/25/16.
//  Copyright © 2016 Born2go. All rights reserved.
//

#import <UIKit/UIKit.h>
@import GoogleMobileAds;

@interface ReverseViewController : UIViewController
{
    IBOutlet GADBannerView *adBanner;
    IBOutlet UIWebView *webView;
    IBOutlet UIView *viewShowAnswer;
    IBOutlet UIButton *btnShowAnswer;
    
}
@end
