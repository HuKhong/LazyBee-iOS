//
//  MajorObject.m
//  LazzyBee
//
//  Created by HuKhong on 3/31/15.
//  Copyright (c) 2015 HuKhong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MajorObject.h"
#import "LocalizeHelper.h"

@implementation MajorObject

- (id)init {
    self = [super init];
    if (self) {

    }
    return self;
}

- (id)initWithName:(NSString *)majorName thumbnail:(NSString *)thumbnail andCheckFlag:(BOOL)flag {
    self = [super init];
    if (self) {
        self.majorName = majorName;
        self.majorThumbnail = thumbnail;
        self.checkFlag = flag;
        self.enabled = YES;
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    
    [encoder encodeObject:self.majorName forKey:@"majorName"];
    [encoder encodeObject:self.majorThumbnail forKey:@"majorThumbnail"];
    [encoder encodeBool:self.checkFlag forKey:@"checkFlag"];
    [encoder encodeBool:self.enabled forKey:@"enabled"];
}

- (id)initWithCoder:(NSCoder *)decoder {
    if ((self = [super init])) // Superclass init
    {
        self.majorName = [decoder decodeObjectForKey:@"majorName"];
        self.majorThumbnail = [decoder decodeObjectForKey:@"majorThumbnail"];
        self.checkFlag = [decoder decodeBoolForKey:@"checkFlag"];
        self.enabled = [decoder decodeBoolForKey:@"enabled"];
    }
    
    return self;
}

- (NSString *)displayName {
    NSString *res = @"";
    
    if ([[self.majorName lowercaseString] isEqualToString:@"economic"]) {
        
        res = LocalizedString(@"Economy");
        
    } else if ([[self.majorName lowercaseString] isEqualToString:@"ielts"]) {
        
        res = LocalizedString(@"IELTS");
        
    } else if ([[self.majorName lowercaseString] isEqualToString:@"it"]) {
        
        res = LocalizedString(@"IT");
        
    } else if ([[self.majorName lowercaseString] isEqualToString:@"science"]) {
        
        res = LocalizedString(@"Science");
        
    } else if ([[self.majorName lowercaseString] isEqualToString:@"medicine"]) {
        
        res = LocalizedString(@"Medicine");
        
    }  else if ([[self.majorName lowercaseString] isEqualToString:@"toeic"]) {
        
        res = LocalizedString(@"Toeic");
        
    } else if ([[self.majorName lowercaseString] isEqualToString:@"coming soon"]) {
        
        res = LocalizedString(@"Coming soon");
        
    }
    
    return res;
}
@end