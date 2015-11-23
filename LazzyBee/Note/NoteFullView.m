//
//  NoteFullView.m
//  LazzyBee
//
//  Created by HuKhong on 10/15/15.
//  Copyright © 2015 Born2go. All rights reserved.
//

#import "NoteFullView.h"

@implementation NoteFullView
{
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [[NSBundle mainBundle] loadNibNamed:@"NoteFullView" owner:self options:nil];
        CGRect rect = self.view.frame;
        rect.size.height = frame.size.height;
        rect.size.width = frame.size.width;
        [self.view setFrame:rect];
        
        [self addSubview:self.view];

    }
    return self;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
//- (void)drawRect:(CGRect)rect {
//    // Drawing code
//}


@end
