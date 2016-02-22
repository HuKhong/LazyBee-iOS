//
//  StudiedTableViewCell.h
//  LazzyBee
//
//  Created by HuKhong on 8/21/15.
//  Copyright (c) 2015 Born2go. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MGSwipeTableCell.h"

@interface StudiedTableViewCell : MGSwipeTableCell
{
    
}

@property (strong, nonatomic) IBOutlet UILabel *lbWord;
@property (strong, nonatomic) IBOutlet UILabel *lbPronounce;
@property (strong, nonatomic) IBOutlet UILabel *lbMeaning;
@property (strong, nonatomic) IBOutlet UILabel *lbLevel;

@end
