//
//  ChangeLanguageViewController.h
//  LazzyBee
//
//  Created by HuKhong on 3/3/15.
//  Copyright (c) 2015 HuKhong. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    LanguageViet = 0,
    LanguageEnglish,
    LanguageMax
} SUPPORTED_LANG;

@interface ChangeLanguageViewController : UIViewController
{
    
    IBOutlet UILabel *lbChangeLangGuide;
    IBOutlet UITableView *languageTableView;
}
@end
