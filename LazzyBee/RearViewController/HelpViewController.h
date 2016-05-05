//
//  HelpViewController.h
//  LazzyBee
//
//  Created by HuKhong on 11/9/15.
//  Copyright © 2015 Born2go. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    Help_Screen_Help = 0,
    Help_Screen_VocabTesting,
    Help_Screen_Max
} HELP_SCREEN_TYPE;

@interface HelpViewController : UIViewController
{
    IBOutlet UIWebView *webView;
    
}

@property (nonatomic, assign) HELP_SCREEN_TYPE helpScreenType;
@end
