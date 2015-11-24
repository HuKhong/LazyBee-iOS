//
//  WordObject.m
//  LazzyBee
//
//  Created by HuKhong on 3/31/15.
//  Copyright (c) 2015 HuKhong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WordObject.h"

/*
 @property (nonatomic, strong) NSString *wordid;
 @property (nonatomic, strong) NSString *question;
 @property (nonatomic, strong) NSString *answers;
 @property (nonatomic, strong) NSString *subcats;
 @property (nonatomic, strong) NSString *status;
 @property (nonatomic, strong) NSString *package;
 @property (nonatomic, strong) NSString *level;
 @property (nonatomic, strong) NSString *queue;
 @property (nonatomic, strong) NSString *due;
 @property (nonatomic, strong) NSString *revCount;
 @property (nonatomic, strong) NSString *lastInterval;
 @property (nonatomic, strong) NSString *eFactor;
 */
@implementation WordObject

- (id)init {
    self = [super init];
    if (self) {
        self.wordid = @"";
        self.gid = @"";
        self.question = @"";
        self.answers = @"";
        self.subcats = @"";
        self.status = @"";
        self.package = @"";
        self.level = @"";
        self.queue = @"";
        self.due = @"";
        self.revCount = @"";
        self.lastInterval = @"";
        self.eFactor = @"";
        self.langEN = @"";
        self.langVN = @"";
        self.userNote = @"";
        self.isFromServer = NO;
    }
    return self;
}


- (void)encodeWithCoder:(NSCoder *)encoder {
    
    [encoder encodeObject:self.wordid forKey:@"wordid"];
    [encoder encodeObject:self.gid forKey:@"gid"];
    [encoder encodeObject:self.question forKey:@"question"];
    [encoder encodeObject:self.answers forKey:@"answers"];
    [encoder encodeObject:self.subcats forKey:@"subcats"];
    [encoder encodeObject:self.status forKey:@"status"];
    [encoder encodeObject:self.package forKey:@"package"];
    [encoder encodeObject:self.level forKey:@"level"];
    [encoder encodeObject:self.queue forKey:@"queue"];
    [encoder encodeObject:self.due forKey:@"due"];
    [encoder encodeObject:self.revCount forKey:@"revCount"];
    [encoder encodeObject:self.lastInterval forKey:@"lastInterval"];
    [encoder encodeObject:self.eFactor forKey:@"eFactor"];
    [encoder encodeObject:self.langVN forKey:@"langVN"];
    [encoder encodeObject:self.langEN forKey:@"langEN"];
    [encoder encodeObject:self.userNote forKey:@"userNote"];
}

- (id)initWithCoder:(NSCoder *)decoder {
    if ((self = [super init])) // Superclass init
    {
        self.wordid = [decoder decodeObjectForKey:@"wordid"];
        self.gid = [decoder decodeObjectForKey:@"gid"];
        self.question = [decoder decodeObjectForKey:@"question"];
        self.answers = [decoder decodeObjectForKey:@"answers"];
        self.subcats = [decoder decodeObjectForKey:@"subcats"];
        self.status = [decoder decodeObjectForKey:@"status"];
        self.package = [decoder decodeObjectForKey:@"package"];
        self.level = [decoder decodeObjectForKey:@"level"];
        self.queue = [decoder decodeObjectForKey:@"queue"];
        self.due = [decoder decodeObjectForKey:@"due"];
        self.revCount = [decoder decodeObjectForKey:@"revCount"];
        self.lastInterval = [decoder decodeObjectForKey:@"lastInterval"];
        self.eFactor = [decoder decodeObjectForKey:@"eFactor"];
        self.langVN = [decoder decodeObjectForKey:@"langVN"];
        self.langEN = [decoder decodeObjectForKey:@"langEN"];
        self.userNote = [decoder decodeObjectForKey:@"userNote"];
    }
    
    return self;
}
@end