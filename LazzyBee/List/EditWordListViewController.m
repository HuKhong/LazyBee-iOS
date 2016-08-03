//
//  EditWordListViewController.m
//  LazzyBee
//
//  Created by HuKhong on 8/3/16.
//  Copyright © 2016 Born2go. All rights reserved.
//

#import "EditWordListViewController.h"
#import "CommonDefine.h"
#import "LocalizeHelper.h"
#import "ImportWordReport.h"
#import "GTMHTTPFetcher.h"
#import "GTLDataServiceApi.h"
#import "WordObject.h"
#import "CommonSqlite.h"
#import "AppDelegate.h"
#import "Common.h"
#import "SVProgressHUD.h"
#import "CommonAlert.h"

@interface EditWordListViewController ()
{
    ImportWordReport *reportView;
    
    NSMutableArray *missingWords;
    NSMutableArray *customList;
    NSInteger countNew;
}
@end

@implementation EditWordListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self.navigationController.navigationBar setTranslucent:NO];

    [self.navigationController.navigationBar setBarTintColor:COMMON_COLOR];
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor whiteColor]};
    [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
    
    [self setTitle:LocalizedString(@"Edit")];
    
    UIBarButtonItem *btnCancel = [[UIBarButtonItem alloc] initWithTitle:LocalizedString(@"Close") style:UIBarButtonItemStyleDone target:(id)self  action:@selector(cancelButtonClick)];
    self.navigationItem.leftBarButtonItem = btnCancel;
    
    UIBarButtonItem *btnImport = [[UIBarButtonItem alloc] initWithTitle:LocalizedString(@"Import") style:UIBarButtonItemStyleDone target:(id)self  action:@selector(importButtonClick)];
    self.navigationItem.rightBarButtonItem = btnImport;
    
    lbGuide1.text = LocalizedString(@"Please add words that you want to learn. These words will be added to learn first.");
    lbGuide2.text = LocalizedString(@"(Separate words by comma, break line)");
    textView.text = @"";
    
    textView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    textView.layer.borderWidth = 0.5f;
    textView.layer.cornerRadius = 5.0f;
    textView.clipsToBounds = YES;
    
    missingWords = [[NSMutableArray alloc] init];
    customList = [[NSMutableArray alloc] init];
    
    if (_wordsArray != nil) {
        NSString *content = @"";
        NSString *w = @"";
        for (int i = 0; i < [_wordsArray count]; i++) {
            w = [_wordsArray objectAtIndex:i];
            
            if (i == 0) {
                content = w;
                
            } else {
                content = [content stringByAppendingFormat:@"\n%@", w];
            }
        }
        
        textView.text = content;
    }
    
    [textView becomeFirstResponder];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(dismissImportReport)
                                                 name:@"DismissImportReport"
                                               object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)cancelButtonClick {
    if (textView.text.length == 0) {
        [self dismissViewControllerAnimated:YES completion:nil];
        
    } else {
        [self confirmCancelEditList];
    }
}


- (void)confirmCancelEditList {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:LocalizedString(@"Are you sure you want to cancel?") delegate:(id)self cancelButtonTitle:LocalizedString(@"No") otherButtonTitles:LocalizedString(@"Yes"), nil];
    alert.tag = 2;
    
    [alert show];
}

- (void)importButtonClick {
    if ([[Common sharedCommon] networkIsActive]) {
        [customList removeAllObjects];
        [missingWords removeAllObjects];
        countNew = 0;
        
        [textView resignFirstResponder];
        
        [SVProgressHUD showWithStatus:LocalizedString(@"Downloading data from server")];
        
        NSCharacterSet *charSet = [NSCharacterSet characterSetWithCharactersInString:@"\n,;"];
        NSArray *wordsArr = [textView.text componentsSeparatedByCharactersInSet:charSet];
        
        if ([wordsArr count] > 0) {
            [customList addObjectsFromArray:wordsArr];
            
            //remove invalid element
            NSMutableArray *tmpArr = [[NSMutableArray alloc] init];
            for (NSString *w in customList) {
                if (w.length == 0) {
                    [tmpArr addObject:w];
                }
            }
            
            [customList removeObjectsInArray:tmpArr];
            
            if ([customList count] > 0) {
                countNew = [customList count];
                [self downloadWordFromServer:[customList objectAtIndex:0]];
                
            }
            
        }
        
        if ([customList count] == 0) {
            [SVProgressHUD dismiss];
            [self noWordFoundAlert];
        }
        
    } else {
        [self noConnectionAlert];
    }
    
}


- (void)downloadWordFromServer:(NSString *)wd {
    NSCharacterSet *charSet = [NSCharacterSet whitespaceCharacterSet];
    NSString *word = [[wd stringByTrimmingCharactersInSet:charSet] lowercaseString];
    
    static GTLServiceDataServiceApi *service = nil;
    if (!service) {
        service = [[GTLServiceDataServiceApi alloc] init];
        service.retryEnabled = YES;
        //[GTMHTTPFetcher setLoggingEnabled:YES];
    }
    
    GTLQueryDataServiceApi *query = [GTLQueryDataServiceApi queryForGetVocaByQWithQ:word];
    //TODO: Add waiting progress here
    [service executeQuery:query completionHandler:^(GTLServiceTicket *ticket, GTLDataServiceApiVoca *object, NSError *error) {
        if (object != nil) {
            //TODO: Update word: q, a, level, package, (and ee, ev)
            WordObject *wordObj = [[WordObject alloc] init];
            wordObj.question   = object.q;
            wordObj.answers    = object.a;
            wordObj.level      = [NSString stringWithFormat:@"%ld", (long)[object.level integerValue]];
            wordObj.package    = object.packages;
            wordObj.gid        = [NSString stringWithFormat:@"%@", object.gid];
            
            if (object.lEn && object.lEn.length > 0) {
                wordObj.langEN     = object.lEn;
            }
            
            if (object.lVn && object.lVn.length > 0) {
                wordObj.langVN     = object.lVn;
            }
            
            wordObj.package    = object.packages;
            wordObj.eFactor    = @"2500";
            wordObj.queue = [NSString stringWithFormat:@"%d", QUEUE_UNKNOWN];
            wordObj.priority = 1;
            
            //insert to db, no need to get from server next time
            [[CommonSqlite sharedCommonSqlite] insertWordToDatabase:wordObj];
            
            //next word
            [customList removeObject:wd];
            
            if ([customList count] > 0) {
                [self downloadWordFromServer:[customList objectAtIndex:0]];
                
            } else {
                [SVProgressHUD dismiss];
                
                [self showReport];
            }
            
        } else {
            [customList removeObject:wd];
            [missingWords addObject:wd];
            
            if ([customList count] > 0) {
                [self downloadWordFromServer:[customList objectAtIndex:0]];
                
            } else {
                [SVProgressHUD dismiss];
                
                [self showReport];
            }
        }
    }];
}

- (void)showReport {    
    reportView = [[ImportWordReport alloc] initWithNibName:@"ImportWordReport" bundle:nil];
    reportView.newWordCount = countNew - [missingWords count];
    reportView.notFoundArray = missingWords;
    
    reportView.view.alpha = 0;
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    CGRect rect = appDelegate.window.frame;
    [reportView.view setFrame:rect];
    
    [appDelegate.window addSubview:reportView.view];
    
    [UIView animateWithDuration:0.3 animations:^(void) {
        reportView.view.alpha = 1;
    }];
}

- (void)noWordFoundAlert {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:LocalizedString(@"Attention") message:LocalizedString(@"There is no word in the custom list.") delegate:(id)self cancelButtonTitle:LocalizedString(@"OK") otherButtonTitles:nil];
    alert.tag = 1;
    
    [alert show];
}

- (void)noConnectionAlert {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:LocalizedString(@"No connection") message:LocalizedString(@"Please double check wifi/3G connection") delegate:(id)self cancelButtonTitle:LocalizedString(@"OK") otherButtonTitles:nil];
    alert.tag = 3;
    
    [alert show];
}

- (void)dismissImportReport {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (alertView.tag == 2) {   //cancel
        if (buttonIndex != 0) {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }
    
    return;
}

@end
