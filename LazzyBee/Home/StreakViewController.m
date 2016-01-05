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

#define NUMBER_OF_DAYS 7
// This is defined in Math.h
#define M_PI   3.14159265358979323846264338327950288   /* pi */

// Our conversion definition
#define DEGREES_TO_RADIANS(angle) (angle / 180.0 * M_PI)

@interface StreakViewController ()

@end

@implementation StreakViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [TagManagerHelper pushOpenScreenEvent:@"iStreakCongratulation"];
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
    
    NSInteger streakCount = [[Common sharedCommon] getCountOfStreak];
    
    lbStreakCount.text = [NSString stringWithFormat:@"%ld %@", (long)streakCount, LocalizedString(@"day")];
    
    lbCongratulation.text = [NSString stringWithFormat:LocalizedString(@"Streack congratulation"), (long)streakCount];
    
    [self displayDaysWithStreakStatus];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)viewDidAppear:(BOOL)animated {
    
    CGRect rect = scrollViewContainer.frame;
    
    rect.size.height = btnContinue.frame.origin.y + btnContinue.frame.size.height + 10;
    [scrollViewContainer setContentSize:rect.size];
    
    [self rotateImage:imgRingStreak duration:2.0
                curve:UIViewAnimationCurveLinear degrees:0];
    
    [[PlaySoundLib sharedPlaySoundLib] playFileInResource:@"magic.mp3"];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

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
        
        for (int j = 0; j < NUMBER_OF_DAYS; j++) {
            if ([streakArr count] > j) {
                streakNumber = [streakArr objectAtIndex:[streakArr count] - 1 - j];
                
                if ([streakNumber doubleValue] == dayInInterval) {
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
        
        [dayStatusViewArray addObject:statusView];
        
        dayInInterval = dayInInterval - 24*3600;
    }
}

- (IBAction)btnContinueClick:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"NeedToCheckReviewList" object:nil];
}
@end
