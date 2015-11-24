//
//  NoteThumbnail.h
//  LazzyBee
//
//  Created by HuKhong on 10/15/15.
//  Copyright © 2015 Born2go. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol NoteThumbnailDelegate <NSObject>

@optional // Delegate protocols

- (void)displayNote:(id)sender;

@end

@interface NoteThumbnail : UIView
{

    
}
@property (strong, nonatomic) IBOutlet UIView *view;

@property(nonatomic, readwrite) id <NoteThumbnailDelegate> delegate;

@end
