//
//  RearViewController.h
//  LazzyBee
//
//  Created by HuKhong on 3/4/15.
//  Copyright (c) 2015 HuKhong. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    RearTable_Section_Home = 0,
    RearTable_Section_Support,
    RearTable_Section_Share,
    RearTable_Section_Max
} REAR_TABLEVIEW_SECTION;

typedef enum {
    HomeSection_Home = 0,
    HomeSection_MajorList,
    HomeSection_Dictionary,
    HomeSection_Progress,
    HomeSection_Max
} ABOUT_SECTION_ITEM;

typedef enum {
    SupportSection_Settings = 0,
    SupportSection_Help,
    SupportSection_Max
} SUUPORT_SECTION_ITEM;

typedef enum {
//    About_App = 0,
    ShareSection_ShareFB = 0,
    ShareSection_Max
} SHARE_SECTION_ITEM;


@interface RearViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>
{
    IBOutlet UILabel *lbName;
    IBOutlet UIImageView *imgAvatar;
    IBOutlet UIImageView *imgCover;
    IBOutlet UILabel *lbVersion;
    
}
@property (nonatomic, retain) IBOutlet UITableView *rearTableView;

@end