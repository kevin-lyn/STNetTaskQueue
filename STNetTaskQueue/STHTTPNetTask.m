//
//  STHTTPNetTask.m
//  Sth4Me
//
//  Created by Kevin Lin on 29/11/14.
//  Copyright (c) 2014 Sth4Me. All rights reserved.
//

#import "STHTTPNetTask.h"

NSString *const STHTTPNetTaskServerError = @"STHTTPNetTaskServerError";
NSString *const STHTTPNetTaskResponseParsedError = @"STHTTPNetTaskResponseParsedError";
NSString *const STHTTPNetTaskErrorStatusCodeUserInfoKey = @"statusCode";
NSString *const STHTTPNetTaskErrorResponseDataUserInfoKey = @"responseData";
NSString *STHTTPNetTaskRequestObjectDefaultSeparator = @"_";

@interface STHTTPNetTask ()

@property (nonatomic, strong) NSURLSessionTask *sessionTask;

@end

@implementation STHTTPNetTask

- (STHTTPNetTaskMethod)method
{
    return STHTTPNetTaskGet;
}

- (STHTTPNetTaskRequestType)requestType
{
    return STHTTPNetTaskRequestKeyValueString;
}

- (STHTTPNetTaskResponseType)responseType
{
    return STHTTPNetTaskResponseJSON;
}

- (NSDictionary *)headers
{
    return nil;
}

- (NSDictionary *)parameters
{
    return nil;
}

- (NSDictionary *)datas
{
    return nil;
}

- (void)didResponse:(id)response
{
    if ([response isKindOfClass:[NSDictionary class]]) {
        [self didResponseDictionary:response];
    }
    else if ([response isKindOfClass:[NSArray class]]) {
        [self didResponseArray:response];
    }
    else if ([response isKindOfClass:[NSString class]]) {
        [self didResponseString:response];
    }
    else if ([response isKindOfClass:[NSData class]]) {
        [self didResponseData:response];
    }
    else {
        NSAssert(NO, @"Invalid response");
    }
}

- (void)didResponseDictionary:(NSDictionary *)dictionary
{
    
}

- (void)didResponseArray:(NSArray *)array
{
    
}

- (void)didResponseString:(NSString *)string
{
    
}

- (void)didResponseData:(NSData *)data
{
    
}

- (NSArray *)ignoredProperties
{
    return nil;
}

@end
