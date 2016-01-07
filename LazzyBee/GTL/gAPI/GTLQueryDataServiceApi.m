/* This file was generated by the ServiceGenerator.
 * The ServiceGenerator is Copyright (c) 2016 Google Inc.
 */

//
//  GTLQueryDataServiceApi.m
//

// ----------------------------------------------------------------------------
// NOTE: This file is generated from Google APIs Discovery Service.
// Service:
//   LazzyBee Backend Api (dataServiceApi/v1.1)
// Description:
//   This is an API
// Classes:
//   GTLQueryDataServiceApi (10 custom class methods, 5 custom properties)

#import "GTLQueryDataServiceApi.h"

#import "GTLDataServiceApiDownloadTarget.h"
#import "GTLDataServiceApiUploadTarget.h"
#import "GTLDataServiceApiVoca.h"
#import "GTLDataServiceApiVocaCollection.h"

@implementation GTLQueryDataServiceApi

@dynamic code, fields, identifier, orderSearch, q;

+ (NSDictionary *)parameterNameMap {
  NSDictionary *map = @{
    @"identifier" : @"id"
  };
  return map;
}

#pragma mark - Service level methods
// These create a GTLQueryDataServiceApi object.

+ (instancetype)queryForFindVocaByIdWithIdentifier:(long long)identifier
                                       orderSearch:(BOOL)orderSearch {
  NSString *methodName = @"dataServiceApi.findVocaById";
  GTLQueryDataServiceApi *query = [self queryWithMethodName:methodName];
  query.identifier = identifier;
  query.orderSearch = orderSearch;
  query.expectedObjectClass = [GTLDataServiceApiVoca class];
  return query;
}

+ (instancetype)queryForFindVocaByQWithOrderSearch:(BOOL)orderSearch
                                                 q:(NSString *)q {
  NSString *methodName = @"dataServiceApi.findVocaByQ";
  GTLQueryDataServiceApi *query = [self queryWithMethodName:methodName];
  query.orderSearch = orderSearch;
  query.q = q;
  query.expectedObjectClass = [GTLDataServiceApiVoca class];
  return query;
}

+ (instancetype)queryForGetDownloadUrlWithCode:(NSString *)code {
  NSString *methodName = @"dataServiceApi.getDownloadUrl";
  GTLQueryDataServiceApi *query = [self queryWithMethodName:methodName];
  query.code = code;
  query.expectedObjectClass = [GTLDataServiceApiDownloadTarget class];
  return query;
}

+ (instancetype)queryForGetUploadUrl {
  NSString *methodName = @"dataServiceApi.getUploadUrl";
  GTLQueryDataServiceApi *query = [self queryWithMethodName:methodName];
  query.expectedObjectClass = [GTLDataServiceApiUploadTarget class];
  return query;
}

+ (instancetype)queryForGetVocaByIdWithIdentifier:(long long)identifier {
  NSString *methodName = @"dataServiceApi.getVocaById";
  GTLQueryDataServiceApi *query = [self queryWithMethodName:methodName];
  query.identifier = identifier;
  query.expectedObjectClass = [GTLDataServiceApiVoca class];
  return query;
}

+ (instancetype)queryForGetVocaByQWithQ:(NSString *)q {
  NSString *methodName = @"dataServiceApi.getVocaByQ";
  GTLQueryDataServiceApi *query = [self queryWithMethodName:methodName];
  query.q = q;
  query.expectedObjectClass = [GTLDataServiceApiVoca class];
  return query;
}

+ (instancetype)queryForListVoca {
  NSString *methodName = @"dataServiceApi.listVoca";
  GTLQueryDataServiceApi *query = [self queryWithMethodName:methodName];
  query.expectedObjectClass = [GTLDataServiceApiVocaCollection class];
  return query;
}

+ (instancetype)queryForSaveVocaWithObject:(GTLDataServiceApiVoca *)object {
  if (object == nil) {
    GTL_DEBUG_ASSERT(object != nil, @"%@ got a nil object", NSStringFromSelector(_cmd));
    return nil;
  }
  NSString *methodName = @"dataServiceApi.saveVoca";
  GTLQueryDataServiceApi *query = [self queryWithMethodName:methodName];
  query.bodyObject = object;
  return query;
}

+ (instancetype)queryForUpdateAWithObject:(GTLDataServiceApiVoca *)object {
  if (object == nil) {
    GTL_DEBUG_ASSERT(object != nil, @"%@ got a nil object", NSStringFromSelector(_cmd));
    return nil;
  }
  NSString *methodName = @"dataServiceApi.updateA";
  GTLQueryDataServiceApi *query = [self queryWithMethodName:methodName];
  query.bodyObject = object;
  return query;
}

+ (instancetype)queryForUpdateDWithObject:(GTLDataServiceApiVoca *)object {
  if (object == nil) {
    GTL_DEBUG_ASSERT(object != nil, @"%@ got a nil object", NSStringFromSelector(_cmd));
    return nil;
  }
  NSString *methodName = @"dataServiceApi.updateD";
  GTLQueryDataServiceApi *query = [self queryWithMethodName:methodName];
  query.bodyObject = object;
  return query;
}

@end
