//
//  LevelPickerViewController.h
//  LazzyBee
//
//  Created by HuKhong on 10/2/15.
//  Copyright © 2015 Born2go. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    LevelPicker = 0,
    WaitingTimePicker
} PICKER_TYPE;

@interface LevelPickerViewController : UIViewController
{
    IBOutlet UIPickerView *levelPicker;
    
}

@property (nonatomic, assign) PICKER_TYPE pickerType;
@end
