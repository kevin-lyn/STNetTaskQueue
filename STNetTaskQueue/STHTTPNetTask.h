//
//  STHTTPNetTask.h
//  Sth4Me
//
//  Created by Kevin Lin on 29/11/14.
//  Copyright (c) 2014 Sth4Me. All rights reserved.
//

#import "STNetTask.h"

FOUNDATION_EXPORT NSString *const STHTTPNetTaskServerError;
FOUNDATION_EXPORT NSString *const STHTTPNetTaskResponseParsedError;

typedef NS_ENUM(NSUInteger, STHTTPNetTaskMethod) {
    STHTTPNetTaskGet,
    STHTTPNetTaskPost,
    STHTTPNetTaskPut,
    STHTTPNetTaskDelete,
    STHTTPNetTaskHead,
    STHTTPNetTaskPatch
};

typedef NS_ENUM(NSUInteger, STHTTPNetTaskRequestType) {
    STHTTPNetTaskRequestJSON,
    STHTTPNetTaskRequestKeyValueString,
    STHTTPNetTaskRequestFormData
};

typedef NS_ENUM(NSUInteger, STHTTPNetTaskResponseType) {
    STHTTPNetTaskResponseJSON,
    STHTTPNetTaskResponseString,
    STHTTPNetTaskResponseRawData
};

@interface STHTTPNetTask : STNetTask

- (STHTTPNetTaskMethod)method;
- (STHTTPNetTaskRequestType)requestType;
- (STHTTPNetTaskResponseType)responseType;
- (NSDictionary *)parameters;
- (NSDictionary *)datas;
- (void)didResponseDictionary:(NSDictionary *)dictionary;
- (void)didResponseArray:(NSArray *)array;
- (void)didResponseString:(NSString *)string;
- (void)didResponseData:(NSData *)data;

@end
