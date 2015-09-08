//
//  WordObject.h
//  LazzyBee
//
//  Created by HuKhong on 3/31/15.
//  Copyright (c) 2015 HuKhong. All rights reserved.
//


#ifndef LazzyBee_WordObject_h
#define LazzyBee_WordObject_h

#import <UIKit/UIKit.h>

#define QUEUE_NEW_WORD 0
#define QUEUE_LEARNED 1
#define QUEUE_REVIEW 2
#define QUEUE_SUSPENDED -1
#define QUEUE_DONE -2

@interface WordObject : NSObject
{
    
}

@property (nonatomic, strong) NSString *wordid;
@property (nonatomic, strong) NSString *question;
@property (nonatomic, strong) NSString *answers;
@property (nonatomic, strong) NSString *subcats;
@property (nonatomic, strong) NSString *status;
@property (nonatomic, strong) NSString *package;
@property (nonatomic, strong) NSString *level;
@property (nonatomic, strong) NSString *queue;
@property (nonatomic, strong) NSString *due;
@property (nonatomic, strong) NSString *revCount;
@property (nonatomic, strong) NSString *lastInterval;
@property (nonatomic, strong) NSString *eFactor;
@end

#endif