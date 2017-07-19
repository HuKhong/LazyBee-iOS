//
//  UploadToServer.m
//  LazzyBee
//
//  Created by HuKhong on 4/19/15.
//  Copyright (c) 2015 HuKhong. All rights reserved.
//

#import "UploadToServer.h"
#import "UIKit/UIKit.h"
#import "Common.h"
#import "SVProgressHUD.h"
#import "TagManagerHelper.h"
#import "TAGContainer.h"
#import "GTMHTTPFetcher.h"
#import "GTLDataServiceApi.h"
#import "CommonSqlite.h"
#import "CommonDefine.h"
// Singleton
static UploadToServer* sharedUploadToServer = nil;

@implementation UploadToServer


//-------------------------------------------------------------
// allways return the same singleton
//-------------------------------------------------------------
+ (UploadToServer*) sharedUploadToServer {
    // lazy instantiation
    if (sharedUploadToServer == nil) {
        sharedUploadToServer = [[UploadToServer alloc] init];
    }
    return sharedUploadToServer;
}


//-------------------------------------------------------------
// initiating
//-------------------------------------------------------------
- (id) init {
    self = [super init];
    if (self) {
        // use systems main bundle as default bundle
    }
    return self;
}

- (void)uploadDatabaseToServer {
    NSString *pathZip = [[[Common sharedCommon] backupFolder] stringByAppendingPathComponent:[[Common sharedCommon] fileNameToBackup]];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:pathZip]) {
        [self sendRequestToGetPostLink];
    }
    
}

- (void)sendRequestToGetPostLink {
    [SVProgressHUD show];
    
    static GTLServiceDataServiceApi *service = nil;
    if (!service) {
        service = [[GTLServiceDataServiceApi alloc] init];
        service.retryEnabled = YES;
        //[GTMHTTPFetcher setLoggingEnabled:YES];
    }
    
    GTLQueryDataServiceApi *query = [GTLQueryDataServiceApi queryForGetUploadUrl];
    //TODO: Add waiting progress here
    [service executeQuery:query completionHandler:^(GTLServiceTicket *ticket, GTLDataServiceApiUploadTarget *object, NSError *error) {
        if (object && object.url && object.url.length > 0){
            [self didReceivePostLink:object.url];
            
        } else {
            [SVProgressHUD dismiss];
            [self failedToConnectToServerAlert];
        }
    }];
    
}

- (void)didReceivePostLink:(NSString *)postLink {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:postLink]
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                       timeoutInterval:60.0];
    // Specify that it will be a POST request
    [request setHTTPMethod:@"POST"];
    //—————————
    //    NSString *boundary = @"---------------------------14737809831466499882746641449";
    NSString *boundary = @"born2go14737809831466499882746641449";
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary];
    [request addValue:contentType forHTTPHeaderField: @"Content-Type"];
    
    /* adding content as a body to post */
    
    NSMutableData *body = [NSMutableData data];
    
    //data files
    NSString *pathZip = [[[Common sharedCommon] backupFolder] stringByAppendingPathComponent:[[Common sharedCommon] fileNameToBackup]];
    NSData *dataZip = [NSData dataWithContentsOfFile:pathZip];
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [body appendData:[[NSString stringWithString:[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"file\"; filename=\"%@\"\r\n", [[Common sharedCommon] fileNameToBackup]]] dataUsingEncoding:NSUTF8StringEncoding]];
    //[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"file\"; filename=\"%@\"\r\n", view.txtCaption.text]
    
    [body appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[NSData dataWithData:dataZip]];
    
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [body appendData:[@"Content-Type: text/plain\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition:form-data; name=\"device_id\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSString *uniqueIdentifier = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    
    [body appendData:[[NSString stringWithFormat:@"%@", uniqueIdentifier] dataUsingEncoding:NSUTF8StringEncoding]];
    
    //finish
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [request setHTTPBody:body];
    
    //    NSString* test = [[NSString alloc] initWithData:body encoding:NSUTF8StringEncoding];
    //    NSLog(@"test ::: %@", test);
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    
    [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
     {
         dispatch_sync(dispatch_get_main_queue(), ^{
             [SVProgressHUD dismiss];
             if (error == nil && data != nil) {
                 [self didPostingResponse:data];
                 
             } else {
                 [self failedToConnectToServerAlert];
             }
         });
     }];
}

- (void)didPostingResponse:(NSData *)data {
    [self backupSuccessfullyAlert];
}

- (void)failedToConnectToServerAlert {
    [self.delegate failedToConnectToServerAlert];
}

- (void)backupSuccessfullyAlert {
    [self.delegate backupSuccessfullyAlert];
}
@end
