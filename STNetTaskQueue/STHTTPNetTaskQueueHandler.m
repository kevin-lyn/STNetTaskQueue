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
#import <objc/runtime.h>

static uint8_t const STBase64EncodingTable[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
static NSString * STBase64String(NSString *string)
{
    NSMutableString *encodedString = [NSMutableString new];
    
    NSData *data = [NSData dataWithBytes:string.UTF8String length:[string lengthOfBytesUsingEncoding:NSUTF8StringEncoding]];
    NSUInteger length = data.length;
    uint8_t *bytes = (uint8_t *)data.bytes;
    
    for (NSUInteger i = 0; i < length; i += 3) {
        uint8_t byte = bytes[i];
        int tableIndex = (byte & 0xFC) >> 2;
        [encodedString appendFormat:@"%c", STBase64EncodingTable[tableIndex]];
        tableIndex = (byte & 0x03) << 4;
        
        if (i + 1 < length) {
            byte = bytes[i + 1];
            tableIndex |= (byte & 0xF0) >> 4;
            [encodedString appendFormat:@"%c", STBase64EncodingTable[tableIndex]];
            tableIndex = (byte & 0x0F) << 2;
            
            if (i + 2 < length) {
                byte = bytes[i + 2];
                tableIndex |= (byte & 0xC0) >> 6;
                [encodedString appendFormat:@"%c", STBase64EncodingTable[tableIndex]];
                
                tableIndex = (byte & 0x3F);
                [encodedString appendFormat:@"%c", STBase64EncodingTable[tableIndex]];
            }
            else {
                [encodedString appendFormat:@"%c=", STBase64EncodingTable[tableIndex]];
            }
        }
        else {
            [encodedString appendFormat:@"%c=", STBase64EncodingTable[tableIndex]];
        }
    }
    
    return [NSString stringWithString:encodedString];
}

@interface NSURLSessionTask (STHTTPNetTaskQueueHandler)

@property (nonatomic, strong, readonly) NSData *data;
@property (nonatomic, copy) void(^completionBlock)(NSURLSessionTask *, NSError *);

- (void)appendData:(NSData *)data;

@end

@implementation NSURLSessionTask (STHTTPNetTaskQueueHandler)

- (void)appendData:(NSData *)data
{
    NSMutableData *mutableData = objc_getAssociatedObject(self, @selector(data));
    if (!mutableData) {
        mutableData = [NSMutableData new];
        objc_setAssociatedObject(self, @selector(data), mutableData, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    [mutableData appendData:data];
}

- (NSData *)data
{
    NSMutableData *data = objc_getAssociatedObject(self, @selector(data));
    return [NSData dataWithData:data];
}

- (void)setCompletionBlock:(void (^)(NSURLSessionTask *, NSError *))completionBlock
{
    objc_setAssociatedObject(self, @selector(completionBlock), completionBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void (^)(NSURLSessionTask *, NSError *))completionBlock
{
    return objc_getAssociatedObject(self, @selector(completionBlock));
}

@end

@interface STHTTPNetTaskQueueHandler () <NSURLSessionDataDelegate>

@end

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
    return [self initWithBaseURL:baseURL configuration:[NSURLSessionConfiguration defaultSessionConfiguration]];
}

- (instancetype)initWithBaseURL:(NSURL *)baseURL configuration:(NSURLSessionConfiguration *)configuration
{
    if (self = [super init]) {
        _baseURL = baseURL;
        _urlSession = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
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

- (void)netTaskQueue:(STNetTaskQueue *)netTaskQueue handleTask:(STNetTask *)task
{
    NSAssert([task isKindOfClass:[STHTTPNetTask class]], @"Net task should be subclass of STHTTPNetTask");
    
    STHTTPNetTask *httpTask = (STHTTPNetTask *)task;
    NSDictionary *headers = httpTask.headers;
    NSDictionary *parameters = [[[STHTTPNetTaskParametersPacker alloc] initWithNetTask:httpTask] pack];
    
    NSURLSessionTask *sessionTask = nil;
    NSMutableURLRequest *request = [NSMutableURLRequest new];
    request.HTTPMethod = _methodMap[@(httpTask.method)];
    
    for (NSString *headerField in headers) {
        [request setValue:headers[headerField] forHTTPHeaderField:headerField];
    }
    
    if (_baseURL.user.length || _baseURL.password.length) {
        NSString *credentials = [NSString stringWithFormat:@"%@:%@", _baseURL.user, _baseURL.password];
        [request setValue:[NSString stringWithFormat:@"Basic %@", STBase64String(credentials)] forHTTPHeaderField:@"Authorization"];
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
            sessionTask = [_urlSession dataTaskWithRequest:request];
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
            }
            else {
                request.HTTPBody = [self formDataFromParameters:parameters datas:datas];
                NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", _formDataBoundary];
                [request setValue:contentType forHTTPHeaderField: @"Content-Type"];
            }
            sessionTask = [_urlSession dataTaskWithRequest:request];
        }
            break;
        default: {
            NSAssert(NO, @"Invalid STHTTPNetTaskMethod");
        }
            break;
    }
    
    [httpTask setValue:sessionTask forKey:@"sessionTask"];
    
    sessionTask.completionBlock = ^(NSURLSessionTask *sessionTask, NSError *error) {
        NSData *data = sessionTask.data;
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)sessionTask.response;
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
                                                userInfo:@{ @"url": httpResponse.URL.absoluteString }];
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
                                                    userInfo:@{ @"url": httpResponse.URL.absoluteString }];
                        }
                    }
                    else {
                        responseObj = @{};
                    }
                }
                    break;
            }
            
            if (error) {
                [netTaskQueue task:task didFailWithError:error];
            }
            else {
                [netTaskQueue task:task didResponse:responseObj];
            }
        }
        else {
            if (!error) { // Response status code is not 200
                error = [NSError errorWithDomain:STHTTPNetTaskServerError
                                            code:0
                                        userInfo:@{ STHTTPNetTaskErrorStatusCodeUserInfoKey: @(httpResponse.statusCode),
                                                    STHTTPNetTaskErrorResponseDataUserInfoKey: data }];
                [STNetTaskQueueLog log:httpTask.description];
            }
            [netTaskQueue task:task didFailWithError:error];
        }
    };
    [sessionTask resume];
}

- (void)netTaskQueue:(STNetTaskQueue *)netTaskQueue didCancelTask:(STNetTask *)task
{
    NSAssert([task isKindOfClass:[STHTTPNetTask class]], @"Net task should be subclass of STHTTPNetTask");
    
    STHTTPNetTask *httpTask = (STHTTPNetTask *)task;
    
    NSURLSessionTask *sessionTask = [httpTask valueForKey:@"sessionTask"];
    [sessionTask cancel];
    
    [httpTask setValue:nil forKey:@"sessionTask"];
}

- (void)netTaskQueueDidBecomeInactive:(STNetTaskQueue *)netTaskQueue
{
    [_urlSession invalidateAndCancel];
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    [dataTask appendData:data];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    task.completionBlock(task, error);
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
                [self appendKeyValueToString:queryString withKey:key value:[element description]];
            }
        }
        else {
            [self appendKeyValueToString:queryString withKey:key value:[value description]];
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
                        [self appendKeyValueToString:bodyString withKey:key value:[element description]];
                    }
                }
                else {
                    [self appendKeyValueToString:bodyString withKey:key value:[value description]];
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

- (void)appendKeyValueToString:(NSMutableString *)string withKey:(NSString *)key value:(NSString *)value
{
    [string appendFormat:@"%@=%@&", key, value];
}

- (void)appendToFormData:(NSMutableData *)formData withKey:(NSString *)key value:(NSString *)value
{
    [formData appendData:[[NSString stringWithFormat:@"--%@\r\n", _formDataBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [formData appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", key] dataUsingEncoding:NSUTF8StringEncoding]];
    [formData appendData:[[NSString stringWithFormat:@"%@\r\n", value] dataUsingEncoding:NSUTF8StringEncoding]];
}

@end
