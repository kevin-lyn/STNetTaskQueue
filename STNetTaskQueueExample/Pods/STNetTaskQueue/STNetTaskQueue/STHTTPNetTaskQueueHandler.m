//
//  STHTTPNetTaskQueueHandler.m
//  Sth4Me
//
//  Created by Kevin Lin on 29/11/14.
//  Copyright (c) 2014 Sth4Me. All rights reserved.
//

#import "STHTTPNetTaskQueueHandler.h"
#import "STHTTPNetTask.h"
#import "STHTTPNetTaskParametersPacker.h"
#import "STNetTaskQueueLog.h"

@implementation STHTTPNetTaskQueueHandler
{
    NSURL *_baseURL;
    NSURLSession *_urlSession;
    NSDictionary *_methodMap;
    NSDictionary *_contentTypeMap;
    NSString *_formDataBoundary;
}

- (instancetype)initWithBaseURL:(NSURL *)baseURL
{
    if (self = [super init]) {
        _baseURL = baseURL;
        _urlSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
        _methodMap = @{ @(STHTTPNetTaskGet): @"GET",
                        @(STHTTPNetTaskDelete): @"DELETE",
                        @(STHTTPNetTaskHead): @"HEAD",
                        @(STHTTPNetTaskPatch): @"PATCH",
                        @(STHTTPNetTaskPost): @"POST",
                        @(STHTTPNetTaskPut): @"PUT" };
        _contentTypeMap = @{ @(STHTTPNetTaskRequestJSON): @"application/json; charset=utf-8",
                             @(STHTTPNetTaskRequestKeyValueString): @"application/x-www-form-urlencoded" };
        _formDataBoundary = [NSString stringWithFormat:@"ST-Boundary-%@", [[NSUUID UUID] UUIDString]];
    }
    return self;
}

- (void)netTaskQueue:(STNetTaskQueue *)netTaskQueue task:(STNetTask *)task taskId:(int)taskId
{
    NSAssert([task isKindOfClass:[STHTTPNetTask class]], @"Net task should be subclass of STHTTPNetTask");
    
    STHTTPNetTask *httpTask = (STHTTPNetTask *)task;
    
    void (^completionHandler)(NSData *, NSURLResponse *, NSError *) = ^(NSData *data, NSURLResponse *response, NSError *error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (httpResponse.statusCode >= 200 && httpResponse.statusCode < 300) {
            id responseObj = nil;
            NSError *error = nil;
            switch (httpTask.responseType) {
                case STHTTPNetTaskResponseRawData: {
                    responseObj = data;
                }
                    break;
                case STHTTPNetTaskResponseString: {
                    @try {
                        if (data.length) {
                            responseObj = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                        }
                        else {
                            responseObj = @"";
                        }
                    }
                    @catch (NSException *exception) {
                        [STNetTaskQueueLog log:@"Response parsed error: %@", exception.debugDescription];
                        error = [NSError errorWithDomain:STHTTPNetTaskResponseParsedError
                                                    code:0
                                                userInfo:@{ @"url": response.URL.absoluteString }];
                    }
                }
                    break;
                case STHTTPNetTaskResponseJSON:
                default: {
                    if (data.length) {
                        responseObj = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
                        if (error) {
                            [STNetTaskQueueLog log:@"Response parsed error: %@", error.debugDescription];
                            error = [NSError errorWithDomain:STHTTPNetTaskResponseParsedError
                                                        code:0
                                                    userInfo:@{ @"url": response.URL.absoluteString }];
                        }
                    }
                    else {
                        responseObj = @{};
                    }
                }
                    break;
            }
            
            if (error) {
                [netTaskQueue didFailWithError:error taskId:taskId];
            }
            else {
                [netTaskQueue didResponse:responseObj taskId:taskId];
            }
        }
        else {
            if (!error) { // Response status code is not 200
                error = [NSError errorWithDomain:STHTTPNetTaskServerError
                                            code:0
                                        userInfo:@{ STHTTPNetTaskErrorStatusCodeUserInfoKey: @(httpResponse.statusCode),
                                                    STHTTPNetTaskErrorResponseDataUserInfoKey: data }];
                [STNetTaskQueueLog log:@"HTTP error with url: %@", httpResponse.URL.absoluteString];
            }
            [netTaskQueue didFailWithError:error taskId:taskId];
        }
    };
    
    NSDictionary *headers = httpTask.headers;
    NSDictionary *parameters = [[[STHTTPNetTaskParametersPacker alloc] initWithNetTask:httpTask] pack];
    
    NSURLSessionTask *sessionTask = nil;
    NSMutableURLRequest *request = [NSMutableURLRequest new];
    request.HTTPMethod = _methodMap[@(httpTask.method)];
    
    for (NSString *headerField in headers) {
        [request setValue:headers[headerField] forHTTPHeaderField:headerField];
    }
    
    switch (httpTask.method) {
        case STHTTPNetTaskGet:
        case STHTTPNetTaskHead:
        case STHTTPNetTaskDelete: {
            NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:[_baseURL URLByAppendingPathComponent:httpTask.uri]
                                                        resolvingAgainstBaseURL:NO];
            if (parameters.count) {
                urlComponents.query = [self queryStringFromParameters:parameters];
            }
            request.URL = urlComponents.URL;
            sessionTask = [_urlSession dataTaskWithRequest:request completionHandler:completionHandler];
        }
            break;
        case STHTTPNetTaskPost:
        case STHTTPNetTaskPut:
        case STHTTPNetTaskPatch: {
            request.URL = [_baseURL URLByAppendingPathComponent:httpTask.uri];
            NSDictionary *datas = httpTask.datas;
            if (!datas.count) {
                request.HTTPBody = [self bodyDataFromParameters:parameters requestType:httpTask.requestType];
                [request setValue:_contentTypeMap[@(httpTask.requestType)] forHTTPHeaderField:@"Content-Type"];
                sessionTask = [_urlSession dataTaskWithRequest:request completionHandler:completionHandler];
            }
            else {
                NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", _formDataBoundary];
                [request setValue:contentType forHTTPHeaderField: @"Content-Type"];
                sessionTask = [_urlSession uploadTaskWithRequest:request
                                                        fromData:[self formDataFromParameters:parameters datas:datas]
                                               completionHandler:completionHandler];
            }
        }
            break;
        default: {
            NSAssert(NO, @"Invalid STHTTPNetTaskMethod");
        }
            break;
    }
    
    [sessionTask resume];
}

- (NSString *)queryStringFromParameters:(NSDictionary *)parameters
{
    if (!parameters.count) {
        return @"";
    }
    
    NSMutableString *queryString = [NSMutableString string];
    [parameters enumerateKeysAndObjectsUsingBlock:^(NSString *key, id value, BOOL *stop) {
        if ([value isKindOfClass:[NSArray class]]) {
            for (id element in value) {
                [self appendToQueryString:queryString withKey:key value:[element description]];
            }
        }
        else {
            [self appendToQueryString:queryString withKey:key value:[value description]];
        }
    }];
    [queryString deleteCharactersInRange:NSMakeRange(queryString.length - 1, 1)];
    return queryString;
}

- (NSData *)bodyDataFromParameters:(NSDictionary *)parameters requestType:(STHTTPNetTaskRequestType)requestType
{
    if (!parameters.count) {
        return nil;
    }
    
    NSData *bodyData = nil;
    
    switch (requestType) {
        case STHTTPNetTaskRequestJSON: {
            NSError *error = nil;
            bodyData = [NSJSONSerialization dataWithJSONObject:parameters options:kNilOptions error:&error];
            NSAssert(!error, @"Request is not in JSON format");
        }
            break;
        case STHTTPNetTaskRequestKeyValueString:
        default: {
            NSMutableString *bodyString = [NSMutableString string];
            [parameters enumerateKeysAndObjectsUsingBlock:^(NSString *key, id value, BOOL *stop) {
                if ([value isKindOfClass:[NSArray class]]) {
                    for (id element in value) {
                        [self appendToBodyString:bodyString withKey:key value:[element description]];
                    }
                }
                else {
                    [self appendToBodyString:bodyString withKey:key value:[value description]];
                }
            }];
            [bodyString deleteCharactersInRange:NSMakeRange(bodyString.length - 1, 1)];
            bodyData = [bodyString dataUsingEncoding:NSUTF8StringEncoding];
        }
            break;
    }
    
    return bodyData;
}

- (NSData *)formDataFromParameters:(NSDictionary *)parameters datas:(NSDictionary *)datas
{
    NSMutableData *formData = [NSMutableData data];
    
    [parameters enumerateKeysAndObjectsUsingBlock:^(NSString *key, id value, BOOL *stop) {
        if ([value isKindOfClass:[NSArray class]]) {
            for (id element in value) {
                [self appendToFormData:formData withKey:key value:[element description]];
            }
        }
        else {
            [self appendToFormData:formData withKey:key value:[value description]];
        }
    }];
    
    [datas enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSData *fileData, BOOL *stop) {
        [formData appendData:[[NSString stringWithFormat:@"--%@\r\n", _formDataBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [formData appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", key, key] dataUsingEncoding:NSUTF8StringEncoding]];
        [formData appendData:[[NSString stringWithFormat:@"Content-Type: %@\r\n\r\n", @"*/*"] dataUsingEncoding:NSUTF8StringEncoding]];
        [formData appendData:fileData];
        [formData appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    }];
    
    [formData appendData:[[NSString stringWithFormat:@"--%@--\r\n", _formDataBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    return formData;
}

- (void)appendToQueryString:(NSMutableString *)queryString withKey:(NSString *)key value:(NSString *)value
{
    value = [value stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    [queryString appendFormat:@"%@=%@&", key, value];
}

- (void)appendToBodyString:(NSMutableString *)bodyString withKey:(NSString *)key value:(NSString *)value
{
    [bodyString appendFormat:@"%@=%@&", key, value];
}

- (void)appendToFormData:(NSMutableData *)formData withKey:(NSString *)key value:(NSString *)value
{
    [formData appendData:[[NSString stringWithFormat:@"--%@\r\n", _formDataBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [formData appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", key] dataUsingEncoding:NSUTF8StringEncoding]];
    [formData appendData:[[NSString stringWithFormat:@"%@\r\n", value] dataUsingEncoding:NSUTF8StringEncoding]];
}

@end
