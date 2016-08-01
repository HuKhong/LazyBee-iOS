//
//  NoteFullView.m
//  LazzyBee
//
//  Created by HuKhong on 10/15/15.
//  Copyright © 2015 Born2go. All rights reserved.
//

#import "NoteFullView.h"
#import "CommonSqlite.h"
#import "TagManagerHelper.h"
#import "LocalizeHelper.h"

@import FirebaseAnalytics;

#define TEXT_PLACEHOLDER LocalizedString(@"Note here")

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
        
        self.view.layer.borderColor = [UIColor darkGrayColor].CGColor;
        self.view.layer.borderWidth = 1.0f;
        
        self.view.layer.cornerRadius = 5.0f;
        self.view.clipsToBounds = YES;
        
        self.view.layer.masksToBounds = NO;
        self.view.layer.shadowOffset = CGSizeMake(-5, 10);
        self.view.layer.shadowRadius = 5;
        self.view.layer.shadowOpacity = 0.5;

        btnSave.enabled = NO;
    }
    return self;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
//- (void)drawRect:(CGRect)rect {
//    // Drawing code
//}

- (void)setWord:(WordObject *)word {
    [btnSave setTitle:LocalizedString(@"Save") forState:UIControlStateNormal];
    lbTitle.text = LocalizedString(@"User note");
    
    _word = word;
    
    txtView.text = word.userNote;
    
    if (word.userNote == nil || word.userNote.length == 0) {
        txtView.text = TEXT_PLACEHOLDER;
        
        txtView.textColor = [UIColor lightGrayColor];
    } else {
        txtView.textColor = [UIColor darkGrayColor];
    }
    
    btnSave.enabled = NO;
}

- (IBAction)panGestureHandle:(id)sender {
    CGPoint translation = [(UIPanGestureRecognizer*)sender translationInView:self.superview];
    [self setCenter:CGPointMake([self center].x + translation.x,
                                [self center].y + translation.y)];
    [(UIPanGestureRecognizer*)sender setTranslation:CGPointMake(0, 0) inView:self.view];
}

- (IBAction)btnSaveClick:(id)sender {
    [TagManagerHelper pushOpenScreenEvent:@"iNote"];
    
    [FIRAnalytics logEventWithName:@"Open_iNote" parameters:@{
                                                                          kFIRParameterValue:@(1)
                                                                          }];
    
    if ([txtView.text isEqualToString:TEXT_PLACEHOLDER]) {
        txtView.text = @"";
    }
    
    _word.userNote = txtView.text;
    [[CommonSqlite sharedCommonSqlite] saveNoteForWord:_word withNewNote:txtView.text];
    
    [self.delegate btnSaveClick];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshStudyScreen" object:_word];
}


- (IBAction)btnCloseClick:(id)sender {
    [self.delegate btnCloseClick];
}

#pragma mark text view delegate
- (void)textViewDidBeginEditing:(UITextView *)textView
{
    //set placeholder, because it's not support by default
    if ([txtView.text isEqualToString:TEXT_PLACEHOLDER]) {
        txtView.text = @"";
        txtView.textColor = [UIColor darkGrayColor]; //optional
    }
    
    [txtView becomeFirstResponder];
}

- (void)textViewDidEndEditing:(UITextView *)textView
{

//    if ([txtView.text isEqualToString:@""]) {
//        txtView.text = TEXT_PLACEHOLDER;
//        txtView.textColor = [UIColor lightGrayColor]; //optional
//    }
    if (![txtView.text isEqualToString:_word.userNote]) {
        btnSave.enabled = YES;
    } else {
        btnSave.enabled = NO;
    }
    
    [textView resignFirstResponder];
}

- (void)textViewDidChange:(UITextView *)textView {
    if (![txtView.text isEqualToString:_word.userNote]) {
        btnSave.enabled = YES;
    } else {
        btnSave.enabled = NO;
    }
}

@end
