//
//  StreakViewController.m
//  LazzyBee
//
//  Created by HuKhong on 11/8/15.
//  Copyright © 2015 Born2go. All rights reserved.
//

#import "StreakViewController.h"
#import "DayStatus.h"
#import "Common.h"
#import "PlaySoundLib.h"
#import "TagManagerHelper.h"
#import "LocalizeHelper.h"
#import "AppDelegate.h"
#import "SaveStreakView.h"

@import FirebaseAnalytics;
@import GoogleMobileAds;

#define NUMBER_OF_DAYS 7
// This is defined in Math.h
#define M_PI   3.14159265358979323846264338327950288   /* pi */

// Our conversion definition
#define DEGREES_TO_RADIANS(angle) (angle / 180.0 * M_PI)

@interface StreakViewController ()
{
    GADInterstitial *interstitial;
    NSMutableArray *missingDays;
    
    SaveStreakView *saveStreakView;
}
@end

@implementation StreakViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [TagManagerHelper pushOpenScreenEvent:@"iStreakCongratulation"];
    [FIRAnalytics logEventWithName:@"Open_iStreakCongratulation" parameters:@{
                                                                  kFIRParameterValue:@(1)
                                                                  }];
    
    // Do any additional setup after loading the view from its nib.
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)
    {
        [self.navigationController.navigationBar setTranslucent:NO];
    }
#endif
    [self.navigationController.navigationBar setBarTintColor:COMMON_COLOR];
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor whiteColor]};
    [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
    
    [self setTitle:LocalizedString(@"Daily target completed")];
    [btnContinue setTitle:LocalizedString(@"Continue") forState:UIControlStateNormal];
    
    missingDays = [[NSMutableArray alloc] init];
    
    [self displayContent];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(showAdsContent)
                                                 name:@"WatchAds"
                                               object:nil];
    
    [self createAndLoadInterstitial];
    [self prepareRewardedVideo];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)viewDidAppear:(BOOL)animated {
    
    [self playEffect];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)displayContent {
    NSInteger streakCount = [[Common sharedCommon] getCountOfStreak];
    
    lbStreakCount.text = [NSString stringWithFormat:@"%ld %@", (long)streakCount, LocalizedString(@"day")];
    
    lbCongratulation.text = [NSString stringWithFormat:LocalizedString(@"Streack congratulation"), (long)streakCount];
    
    [missingDays removeAllObjects];
    [self displayDaysWithStreakStatus];
    
    NSMutableAttributedString *attributeString = [[NSMutableAttributedString alloc] initWithString:LocalizedString(@"2000 words/year with 5 minutes per day")];
    [attributeString addAttribute:NSUnderlineStyleAttributeName
                            value:[NSNumber numberWithInt:1]
                            range:(NSRange){0,[attributeString length]}];
    
    [lbLink setAttributedText:attributeString];
    
    [FIRAnalytics logEventWithName:EVENT_STREAK parameters:@{
                                                             kFIRParameterValue:@(streakCount)
                                                             }];
}

- (void)playEffect {
    CGRect rect = scrollViewContainer.frame;
    
    rect.size.height = btnContinue.frame.origin.y + btnContinue.frame.size.height + 10;
    [scrollViewContainer setContentSize:rect.size];
    
    [self rotateImage:imgRingStreak duration:2.0
                curve:UIViewAnimationCurveLinear degrees:0];
    
    [[PlaySoundLib sharedPlaySoundLib] playFileInResource:@"magic.mp3"];
}

- (void)rotateImage:(UIImageView *)image duration:(NSTimeInterval)duration
              curve:(int)curve degrees:(CGFloat)degrees
{
    // Setup the animation
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:duration];
    [UIView setAnimationCurve:curve];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromLeft forView:image cache:YES];
    // The transform matrix
    CGAffineTransform transform =
    CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(degrees));
    image.transform = transform;
    
    // Commit the changes
    [UIView commitAnimations];
}

- (void)displayDaysWithStreakStatus {
    //remove subviews
    if ([viewDayOne.subviews count] > 0) {
        [[viewDayOne.subviews objectAtIndex:0] removeFromSuperview];
    }
    
    if ([viewDayTwo.subviews count] > 0) {
        [[viewDayTwo.subviews objectAtIndex:0] removeFromSuperview];
    }
    
    if ([viewDayThree.subviews count] > 0) {
        [[viewDayThree.subviews objectAtIndex:0] removeFromSuperview];
    }
    
    if ([viewDayFour.subviews count] > 0) {
        [[viewDayFour.subviews objectAtIndex:0] removeFromSuperview];
    }
    
    if ([viewDayFive.subviews count] > 0) {
        [[viewDayFive.subviews objectAtIndex:0] removeFromSuperview];
    }
    
    if ([viewDaySix.subviews count] > 0) {
        [[viewDaySix.subviews objectAtIndex:0] removeFromSuperview];
    }
    
    if ([viewDaySeven.subviews count] > 0) {
        [[viewDaySeven.subviews objectAtIndex:0] removeFromSuperview];
    }
    
    NSArray *streakArr = [[Common sharedCommon] loadStreak];
    NSMutableArray *dayStatusViewArray = [[NSMutableArray alloc] init];
//    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
//    [dateFormatter setDateFormat:@"EEEE"];
    
    NSTimeInterval dayInInterval = [[Common sharedCommon] getBeginOfDayInSec];
    
    DayStatus *statusView = nil;
    NSDate *date = nil;
    NSNumber *streakNumber = nil;
    
    for (int i = 0; i < NUMBER_OF_DAYS; i++) {
        date = [NSDate dateWithTimeIntervalSince1970:dayInInterval];
//        NSLog(@"double: %f", dayInInterval);
//        NSLog(@"day: %@", [[Common sharedCommon] getDayOfWeek:date]);
        
        BOOL status = NO;
        NSTimeInterval offset = 0;
        
        for (int j = 0; j < NUMBER_OF_DAYS; j++) {
            if ([streakArr count] > j) {
                streakNumber = [streakArr objectAtIndex:[streakArr count] - 1 - j];
                
                
                if (dayInInterval >= [streakNumber doubleValue]) {
                    offset = dayInInterval - [streakNumber doubleValue];
                    
                } else {
                    offset = [streakNumber doubleValue] - dayInInterval;
                }
                
                if (offset < SECONDS_OF_HALFDAY) {
                    status = YES;
                    break;
                }
            }
        }
        
        
        if (NUMBER_OF_DAYS - 1 - i == 0) {
            statusView = [[DayStatus alloc] initWithFrame:viewDayOne.frame];
            [viewDayOne addSubview:statusView];
            
        } else if (NUMBER_OF_DAYS - 1 - i  == 1) {
            statusView = [[DayStatus alloc] initWithFrame:viewDayTwo.frame];
            [viewDayTwo addSubview:statusView];
            
        } else if (NUMBER_OF_DAYS - 1 - i  == 2) {
            statusView = [[DayStatus alloc] initWithFrame:viewDayThree.frame];
            [viewDayThree addSubview:statusView];
            
        } else if (NUMBER_OF_DAYS - 1 - i  == 3) {
            statusView = [[DayStatus alloc] initWithFrame:viewDayFour.frame];
            [viewDayFour addSubview:statusView];
            
        } else if (NUMBER_OF_DAYS - 1 - i  == 4) {
            statusView = [[DayStatus alloc] initWithFrame:viewDayFive.frame];
            [viewDayFive addSubview:statusView];
            
        } else if (NUMBER_OF_DAYS - 1 - i  == 5) {
            statusView = [[DayStatus alloc] initWithFrame:viewDaySix.frame];
            [viewDaySix addSubview:statusView];
            
        } else if (NUMBER_OF_DAYS - 1 - i  == 6) {
            statusView = [[DayStatus alloc] initWithFrame:viewDaySeven.frame];
            [viewDaySeven addSubview:statusView];
        }
        CGRect rect = statusView.frame;
        rect.origin.x = 0;
        rect.origin.y = 0;
        [statusView setFrame:rect];
        
        statusView.strDay = [[Common sharedCommon] getDayOfWeek:date];
        statusView.streakStatus = status;
        
        if (status == NO) {
            
            [missingDays addObject:[NSNumber numberWithInteger:dayInInterval]]; //save expected day
        }
        
        [dayStatusViewArray addObject:statusView];
        
        dayInInterval = dayInInterval - SECONDS_OF_DAY;
    }
    
    //check missing days
    BOOL found = NO;
    NSTimeInterval day = 0;
    NSMutableArray *tmps = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < [missingDays count]; i++) {
        day = [[missingDays objectAtIndex:i] doubleValue];
        found = NO;
        
        for (int j = 0; j <= NUMBER_OF_DAYS; j++) {
            if ([streakArr count] > j) {
                if (day >= [[streakArr objectAtIndex:[streakArr count] - 1 - j] doubleValue]) {
                    found = YES;
                    break;
                }
            }
        }
        
        if (found == NO) {
            [tmps addObject:[missingDays objectAtIndex:i]];
        }
    }
    
    if ([tmps count] > 0) {
        [missingDays removeObjectsInArray:tmps];
    }
    
    [self showStreakSaver];
}

- (void)showStreakSaver {
    if ([missingDays count] > 0) {
        if (saveStreakView == nil) {
            saveStreakView = [[SaveStreakView alloc] initWithNibName:@"SaveStreakView" bundle:nil];
            saveStreakView.missingCount = [missingDays count];
            
            saveStreakView.view.alpha = 0;
            saveStreakView.viewContainer.alpha = 0;
            
            AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            
            CGRect rect = appDelegate.window.frame;
            [saveStreakView.view setFrame:rect];
            
            [appDelegate.window addSubview:saveStreakView.view];
            
            [UIView animateWithDuration:0.3 animations:^(void) {
                saveStreakView.view.alpha = 1;
                
            } completion:^(BOOL finished) {
                [UIView animateWithDuration:0.3 animations:^(void) {
                    saveStreakView.viewContainer.alpha = 0.9;
                }];
            }];
        }
    }
}

- (IBAction)btnContinueClick:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"NeedToCheckReviewList" object:nil];
    
    NSInteger streakCount = [[Common sharedCommon] getCountOfStreak];
    if (streakCount % NUMBER_OF_STREAK_TO_BACKUP == 0) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"NeedToBackupData" object:nil];
    }
    
}

- (IBAction)tapOnLinkHandle:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.lazzybee.com/blog/can_you_learn_2000_words_per_year"]];
}

#pragma mark admob
- (void)createAndLoadInterstitial {
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    TAGContainer *container = appDelegate.container;

    NSString *advStr = [NSString stringWithFormat:@"%@/%@", [container stringForKey:@"admob_pub_id"],[container stringForKey:@"adv_fullscreen_id"] ];

    interstitial = [[GADInterstitial alloc] initWithAdUnitID:advStr]; //@"ca-app-pub-3940256099942544/4411468910"
    interstitial.delegate = (id)self;
    
    GADRequest *request = [GADRequest request];
    // Request test ads on devices you specify. Your test device ID is printed to the console when
    // an ad request is made. GADInterstitial automatically returns test ads when running on a
    // simulator.
//    request.testDevices = @[
//                            @"687f0b503566ebb7d84524c1f15e1d16",
//                            kGADSimulatorID
//                            ];
    [interstitial loadRequest:request];
}

- (void)interstitial:(GADInterstitial *)interstitial
didFailToReceiveAdWithError:(GADRequestError *)error {
    NSLog(@"interstitialDidFailToReceiveAdWithError: %@", [error localizedDescription]);
}

- (void)interstitialDidDismissScreen:(GADInterstitial *)interstitial {
    NSLog(@"interstitialDidDismissScreen");
}

- (void)prepareRewardedVideo {
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    TAGContainer *container = appDelegate.container;
    
    NSString *advStr = [NSString stringWithFormat:@"%@/%@", [container stringForKey:@"admob_pub_id"], @"9736066402" ];
    
    [GADRewardBasedVideoAd sharedInstance].delegate = (id)self;
    [[GADRewardBasedVideoAd sharedInstance] loadRequest:[GADRequest request]
                                           withAdUnitID:advStr];
}

- (void)rewardBasedVideoAd:(GADRewardBasedVideoAd *)rewardBasedVideoAd
   didRewardUserWithReward:(GADAdReward *)reward {
//    NSString *rewardMessage = [NSString stringWithFormat:@"Reward received with currency %@ , amount %lf",
//     reward.type,
//     [reward.amount doubleValue]];
//    NSLog(@"%@", rewardMessage);
}

- (void)rewardBasedVideoAdDidReceiveAd:(GADRewardBasedVideoAd *)rewardBasedVideoAd {
    NSLog(@"Reward based video ad is received.");
}

- (void)rewardBasedVideoAdDidOpen:(GADRewardBasedVideoAd *)rewardBasedVideoAd {
    NSLog(@"Opened reward based video ad.");
}

- (void)rewardBasedVideoAdDidStartPlaying:(GADRewardBasedVideoAd *)rewardBasedVideoAd {
    NSLog(@"Reward based video ad started playing.");
}

- (void)rewardBasedVideoAdDidClose:(GADRewardBasedVideoAd *)rewardBasedVideoAd {
    NSLog(@"Reward based video ad is closed.");
}

- (void)rewardBasedVideoAdWillLeaveApplication:(GADRewardBasedVideoAd *)rewardBasedVideoAd {
    NSLog(@"Reward based video ad will leave application.");
}

- (void)rewardBasedVideoAd:(GADRewardBasedVideoAd *)rewardBasedVideoAd
    didFailToLoadWithError:(NSError *)error {
    NSLog(@"Reward based video ad failed to load.");
}

- (void)showAdsContent {
    //update one day streak
    NSNumber *missingday = nil;
    
    if ([missingDays count] > 0) {
        missingday = [missingDays objectAtIndex:0];
        
        [[Common sharedCommon] saveStreak:[missingday doubleValue]];
    }
    
    if ([[GADRewardBasedVideoAd sharedInstance] isReady]) {
        [[GADRewardBasedVideoAd sharedInstance] presentFromRootViewController:self];
        
    } else if (interstitial.isReady) {
        [interstitial presentFromRootViewController:self];
    }
    
    [self displayContent];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
