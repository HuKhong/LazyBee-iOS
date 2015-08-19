//
//  SVProgressHUD.h
//
//  Created by Sam Vermette on 27.03.11.
//  Copyright 2011 Sam Vermette. All rights reserved.
//
//  https://github.com/samvermette/SVProgressHUD
//

#import <UIKit/UIKit.h>
#import <AvailabilityMacros.h>




enum {
    SVProgressHUDMaskTypeNone = 1, // allow user interactions while HUD is displayed
    SVProgressHUDMaskTypeClear, // don't allow
    SVProgressHUDMaskTypeBlack, // don't allow and dim the UI in the back of the HUD
    SVProgressHUDMaskTypeGradient // don't allow and dim the UI with a a-la-alert-view bg gradient
};

typedef NSUInteger SVProgressHUDMaskType;

@interface SVProgressHUD : UIView

@property (strong, nonatomic) void (^dismissCompleteBlock)(void);
- (void)showWithStatus:(NSString*)string maskType:(SVProgressHUDMaskType)hudMaskType networkIndicator:(BOOL)show;

- (void)dismiss;
- (void)dismiss:(void (^)(void))successBlock;

- (void)dismissWithStatus:(NSString*)string error:(BOOL)error;
- (void)dismissWithStatus:(NSString*)string error:(BOOL)error afterDelay:(NSTimeInterval)seconds;

+ (void)showOnTopOfViewController:(UIViewController *)viewController;
+ (void)showOnTopOfViewController:(UIViewController *)viewController withStatus:(NSString*)status;
+ (void)showOnTopOfViewController:(UIViewController *)viewController withStatus:(NSString*)status maskType:(SVProgressHUDMaskType)maskType;
+ (void)showOnTopOfViewController:(UIViewController *)viewController withMaskType:(SVProgressHUDMaskType)maskType;

+ (void)showSuccessWithStatus:(NSString*)string;
+ (void)showSuccessWithStatus:(NSString *)string duration:(NSTimeInterval)duration;
+ (void)showErrorWithStatus:(NSString *)string;
+ (void)showErrorWithStatus:(NSString *)string duration:(NSTimeInterval)duration;

+ (void)setStatus:(NSString*)string; // change the HUD loading status while it's showing

+ (void)dismiss; // simply dismiss the HUD with a fade+scale out animation
+ (void)dismiss:(void (^)(void))successBlock;
+ (void)dismissWithSuccess:(NSString*)successString; // also displays the success icon image
+ (void)dismissWithSuccess:(NSString*)successString afterDelay:(NSTimeInterval)seconds;
+ (void)dismissWithError:(NSString*)errorString; // also displays the error icon image
+ (void)dismissWithError:(NSString*)errorString afterDelay:(NSTimeInterval)seconds;

+ (BOOL)isVisible;

// deprecated methods; it shouldn't be the HUD's responsability to show/hide the network activity indicator
+ (void)showOnTopOfViewController:(UIViewController *)viewController withStatus:(NSString *)status networkIndicator:(BOOL)show;
+ (void)showOnTopOfViewController:(UIViewController *)viewController withMaskType:(SVProgressHUDMaskType)maskType networkIndicator:(BOOL)show;
+ (void)showOnTopOfViewController:(UIViewController *)viewController withStatus:(NSString*)status maskType:(SVProgressHUDMaskType)maskType networkIndicator:(BOOL)show;

+ (SVProgressHUD *) sharedInstance;

@end