//
//  HTMLHelper.h
//  LazzyBee
//
//  Created by HuKhong on 4/19/15.
//  Copyright (c) 2015 HuKhong. All rights reserved.
//

#ifndef LazzyBee_HTMLHelper_h
#define LazzyBee_HTMLHelper_h
#import <Foundation/Foundation.h>
#import "WordObject.h"
#import "MajorObject.h"

@interface HTMLHelper : NSObject

// a singleton:
+ (HTMLHelper*) sharedHTMLHelper;

- (NSString *)createHTMLForReverse:(WordObject *)word withPackage:(MajorObject *)majorObj;
- (NSString *)createHTMLForQuestion:(WordObject *)word withPackage:(MajorObject *)majorObj;
- (NSString *)createHTMLForAnswer:(WordObject *)word withPackage:(MajorObject *)majorObj;
- (NSString *)createHTMLDict:(WordObject *)wordObj dictType:(NSString *)dictType;
@end

#endif
