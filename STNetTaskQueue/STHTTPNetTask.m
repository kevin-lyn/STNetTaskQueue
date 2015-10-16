//
//  STHTTPNetTask.m
//  Sth4Me
//
//  Created by Kevin Lin on 29/11/14.
//  Copyright (c) 2014 Sth4Me. All rights reserved.
//

#import "STHTTPNetTask.h"
#import "STHTTPNetTaskParametersPacker.h"

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

- (NSString *)description
{
    NSDictionary *methodMap = @{ @(STHTTPNetTaskGet): @"GET",
                                 @(STHTTPNetTaskDelete): @"DELETE",
                                 @(STHTTPNetTaskHead): @"HEAD",
                                 @(STHTTPNetTaskPatch): @"PATCH",
                                 @(STHTTPNetTaskPost): @"POST",
                                 @(STHTTPNetTaskPut): @"PUT" };
    NSDictionary *requestTypeMap = @{ @(STHTTPNetTaskRequestJSON): @"JSON",
                                      @(STHTTPNetTaskRequestKeyValueString): @"Key-Value String",
                                      @(STHTTPNetTaskRequestFormData): @"Form Data" };
    NSDictionary *responseTypeMap = @{ @(STHTTPNetTaskResponseJSON): @"JSON",
                                       @(STHTTPNetTaskResponseString): @"String",
                                       @(STHTTPNetTaskResponseRawData): @"Raw Data" };
    
    NSMutableString *desc = [NSMutableString new];
    [desc appendFormat:@"URI: %@\n", self.uri];
    [desc appendFormat:@"Method: %@\n", methodMap[@(self.method)]];
    [desc appendFormat:@"Request Type: %@\n", requestTypeMap[@(self.requestType)]];
    [desc appendFormat:@"Response Type: %@\n", responseTypeMap[@(self.responseType)]];
    
    NSDictionary *headers = self.headers;
    if (headers.count) {
        [desc appendFormat:@"Custom Headers:\n%@\n", headers];
    }
    NSDictionary *datas = self.datas;
    if (datas.count) {
        [desc appendFormat:@"Form Datas:\n"];
        for (NSString *name in datas) {
            NSData *data = datas[name];
            [desc appendFormat:@"%@: %td bytes\n", name, data.length];
        }
    }
    
    [desc appendFormat:@"Parameters:\n%@\n", [[[STHTTPNetTaskParametersPacker alloc] initWithNetTask:self] pack]];
    return desc;
}

@end
