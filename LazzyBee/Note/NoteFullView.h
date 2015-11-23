//
//  NoteFullView.h
//  LazzyBee
//
//  Created by HuKhong on 10/15/15.
//  Copyright © 2015 Born2go. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol NoteFullViewDelegate <NSObject>

@optional // Delegate protocols



@end

@interface NoteFullView : UIView
{

    
}
@property (strong, nonatomic) IBOutlet UIView *view;

@property(nonatomic, readwrite) id <NoteFullViewDelegate> delegate;

@end
