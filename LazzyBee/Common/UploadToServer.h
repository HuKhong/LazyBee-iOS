//
//  UploadToServer.h
//  LazzyBee
//
//  Created by HuKhong on 4/19/15.
//  Copyright (c) 2015 HuKhong. All rights reserved.
//

#ifndef LazzyBee_UploadToServer_h
#define LazzyBee_UploadToServer_h
#import <Foundation/Foundation.h>

@protocol UploadToServerDelegate <NSObject>
- (void)failedToConnectToServerAlert;
- (void)backupSuccessfullyAlert;

@optional // Delegate protocols

@end
@interface UploadToServer : NSObject

// a singleton:
+ (UploadToServer*) sharedUploadToServer;

- (void)uploadDatabaseToServer;

@property(nonatomic, readwrite) id <UploadToServerDelegate> delegate;
@end

#endif
