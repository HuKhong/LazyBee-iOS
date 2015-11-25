//
//  NoteFullView.h
//  LazzyBee
//
//  Created by HuKhong on 10/15/15.
//  Copyright © 2015 Born2go. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WordObject.h"

@protocol NoteFullViewDelegate <NSObject>

@optional // Delegate protocols

- (void)btnCloseClick;
- (void)btnSaveClick;

@end

@interface NoteFullView : UIView
{

    IBOutlet UITextView *txtView;
    IBOutlet UIButton *btnSave;
    
    
}
@property (strong, nonatomic) IBOutlet UIView *view;
@property (strong, nonatomic) WordObject *word;

@property(nonatomic, readwrite) id <NoteFullViewDelegate> delegate;

@end
