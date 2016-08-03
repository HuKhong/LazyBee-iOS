//
//  CommonAlert.h
//  LazzyBee
//
//  Created by HuKhong on 4/19/15.
//  Copyright (c) 2015 HuKhong. All rights reserved.
//

#ifndef LazzyBee_CommonAlert_h
#define LazzyBee_CommonAlert_h
#import <Foundation/Foundation.h>

@interface CommonAlert : NSObject

// a singleton:
+ (CommonAlert*) sharedCommonAlert;

- (void)showServerCommonErrorAlert;
- (void)noConnectionAlert;
@end

#endif
