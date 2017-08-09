//
//  AdsViewController.m
//  LazzyBee
//
//  Created by HuKhong on 8/4/17.
//  Copyright © 2017 Born2go. All rights reserved.
//

#import "AdsViewController.h"
#import "AppDelegate.h"
#import "TagManagerHelper.h"
@import GoogleMobileAds;

@interface AdsViewController ()
{
    
    IBOutlet GADBannerView *bannerView;
}

@end

@implementation AdsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    TAGContainer *container = appDelegate.container;
    
    NSString *pubKey = @"admob_pub_id";
    NSString *adsKey = @"sponsor_unit";
    
    NSString *pub_id = [container stringForKey:pubKey];
    NSString *adv_id = [container stringForKey:adsKey];
    adv_id = @"4954513019";
    NSString *advStr = [NSString stringWithFormat:@"%@/%@", pub_id,adv_id ];
    
    GADRequest *request = [GADRequest request];
    
    bannerView.adUnitID = advStr;//@"ca-app-pub-3940256099942544/4954513019";
    bannerView.rootViewController = self;
    
//    request.testDevices = @[
//                            @"687f0b503566ebb7d84524c1f15e1d16",
//                            kGADSimulatorID
//                            ];
    
    [bannerView loadRequest:request];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/




- (IBAction)showVideo:(id)sender {
    if ([[GADRewardBasedVideoAd sharedInstance] isReady]) {
        [[GADRewardBasedVideoAd sharedInstance] presentFromRootViewController:self];
    } else {
        [[[UIAlertView alloc]
          initWithTitle:@"Interstitial not ready"
          message:@"The interstitial didn't finish " @"loading or failed to load"
          delegate:self
          cancelButtonTitle:@"Drat"
          otherButtonTitles:nil] show];
    }
}

/// Tells the delegate an ad request loaded an ad.
- (void)adViewDidReceiveAd:(GADBannerView *)adView {
    NSLog(@"adViewDidReceiveAd");
}

/// Tells the delegate an ad request failed.
- (void)adView:(GADBannerView *)adView
didFailToReceiveAdWithError:(GADRequestError *)error {
    NSLog(@"adView:didFailToReceiveAdWithError: %@", [error localizedDescription]);
}

/// Tells the delegate that a full screen view will be presented in response
/// to the user clicking on an ad.
- (void)adViewWillPresentScreen:(GADBannerView *)adView {
    NSLog(@"adViewWillPresentScreen");
}

/// Tells the delegate that the full screen view will be dismissed.
- (void)adViewWillDismissScreen:(GADBannerView *)adView {
    NSLog(@"adViewWillDismissScreen");
}

/// Tells the delegate that the full screen view has been dismissed.
- (void)adViewDidDismissScreen:(GADBannerView *)adView {
    NSLog(@"adViewDidDismissScreen");
}

/// Tells the delegate that a user click will open another app (such as
/// the App Store), backgrounding the current app.
- (void)adViewWillLeaveApplication:(GADBannerView *)adView {
    NSLog(@"adViewWillLeaveApplication");
}
@end
