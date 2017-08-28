//
//  OpenEarObject.h
//  LazzyBee
//
//  Created by HuKhong on 10/15/15.
//  Copyright © 2015 Born2go. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OpenEars/OEEventsObserver.h>

@protocol OpenEarObjectDelegate <NSObject>

@optional // Delegate protocols


@end

#define COMMAND_SHOW_ANSWER @"Show answer"
#define COMMAND_LEARN_AGAIN @"Learn again"
#define COMMAND_EASY @"Easy"
#define COMMAND_NORMAL @"Normal"
#define COMMAND_HARD @"Hard"
#define COMMAND_PRONOUNCE @"Pronounce"
#define COMMAND_MEANING @"Meaning"
#define COMMAND_EXAMPLE @"Example"

@interface OpenEarObject : UIView <OEEventsObserverDelegate>
{

    IBOutlet UIImageView *imgEar;
    
}
@property (strong, nonatomic) IBOutlet UIView *view;

@property(nonatomic, readwrite) id <OpenEarObjectDelegate> delegate;

- (void)stopListening;
- (void)startListening;
@end
