//
//  ImportWordReport.h
//  LazzyBee
//
//  Created by HuKhong on 6/4/15.
//  Copyright (c) 2015 HuKhong. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ImportWordReport : UIViewController
{
    IBOutlet UIView *viewTitle;
    IBOutlet UILabel *lbTitle;
    IBOutlet UILabel *lbNewWord;
    IBOutlet UILabel *lbNewWordCount;
    IBOutlet UILabel *lbNotFound;
    IBOutlet UILabel *lbNotFoundCount;

    IBOutlet UITextView *txtContent;
}

@property (nonatomic, assign) NSInteger newWordCount;
@property (nonatomic, strong) NSArray *notFoundArray;

- (void)loadInformation;
@end
