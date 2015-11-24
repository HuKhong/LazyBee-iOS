//
//  NoteThumbnail.m
//  LazzyBee
//
//  Created by HuKhong on 10/15/15.
//  Copyright © 2015 Born2go. All rights reserved.
//

#import "NoteThumbnail.h"

#define OFFSET 5

@implementation NoteThumbnail
{
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [[NSBundle mainBundle] loadNibNamed:@"NoteThumbnail" owner:self options:nil];
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

- (IBAction)panGestureHandle:(id)sender {
    CGPoint translation = [(UIPanGestureRecognizer*)sender translationInView:self.superview];
    [self setCenter:CGPointMake([self center].x + translation.x,
                                         [self center].y + translation.y)];
    [(UIPanGestureRecognizer*)sender setTranslation:CGPointMake(0, 0) inView:self.view];
    
    if ([(UIPanGestureRecognizer*)sender state] == UIGestureRecognizerStateEnded) {
        [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            CGPoint center = [self center];
            
            if (center.x > self.superview.frame.size.width/2) {
                center.x = self.superview.frame.size.width - self.view.frame.size.width/2 - OFFSET; //5 :: offset
                
            } else {
                center.x = self.view.frame.size.width/2 + OFFSET;
            }
            
            if (center.y > self.superview.frame.size.height - self.view.frame.size.height/2 - OFFSET) {
                center.y = self.superview.frame.size.height - self.view.frame.size.height/2 - OFFSET; //5 :: offset
                
            } else if (center.y < self.view.frame.size.height/2 + OFFSET) {
                center.y = self.view.frame.size.height/2 + 5;
            }
            
            [self setCenter:center];
        } completion:nil];
        
    }
}

- (IBAction)tapGestureHandle:(id)sender {
    [self.delegate displayNote:self];
}

@end
