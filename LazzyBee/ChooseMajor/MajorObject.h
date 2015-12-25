//
//  MajorObject.h
//  LazzyBee
//
//  Created by HuKhong on 3/31/15.
//  Copyright (c) 2015 HuKhong. All rights reserved.
//


#ifndef LazzyBee_MajorObject_h
#define LazzyBee_MajorObject_h

#import <UIKit/UIKit.h>


@interface MajorObject : NSObject
{
    
}

@property (nonatomic, strong) NSString *majorName;
@property (nonatomic, strong) NSString *majorThumbnail;
@property (nonatomic, assign) BOOL checkFlag;
@property (nonatomic, assign) BOOL enabled;

- (id)initWithName:(NSString *)majorName thumbnail:(NSString *)thumbnail andCheckFlag:(BOOL)flag;

- (NSString *)displayName;
@end

#endif
