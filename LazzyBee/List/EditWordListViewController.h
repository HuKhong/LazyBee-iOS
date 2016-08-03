//
//  EditWordListViewController.h
//  LazzyBee
//
//  Created by HuKhong on 8/3/16.
//  Copyright © 2016 Born2go. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EditWordListViewController : UIViewController
{
    IBOutlet UILabel *lbGuide1;
    IBOutlet UILabel *lbGuide2;
    IBOutlet UITextView *textView;
    
}

@property (nonatomic, strong) NSArray *wordsArray;
@end
