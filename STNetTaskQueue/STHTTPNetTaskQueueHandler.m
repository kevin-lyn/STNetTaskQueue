//
//  STHTTPNetTaskQueueHandler.m
//  STNetTaskQueue
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

@class STHTTPNetTaskQueueHandlerOperation;

@interface NSURLSessionTask (STHTTPNetTaskQueueHandlerOperation)

@property (nonatomic, strong) STHTTPNetTaskQueueHandlerOperation *operation;

@end

@implementation NSURLSessionTask (STHTTPNetTaskQueueHandlerOperation)

- (void)setOperation:(STHTTPNetTaskQueueHandlerOperation *)operation
{
    objc_setAssociatedObject(self, @selector(operation), operation, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (STHTTPNetTaskQueueHandlerOperation *)operation
{
    return objc_getAssociatedObject(self, @selector(operation));
}

@end

static NSDictionary *STHTTPNetTaskMethodMap;
static NSDictionary *STHTTPNetTaskContentTypeMap;
static NSString *STHTTPNetTaskFormDataBoundary;
static NSMapTable *STHTTPNetTaskToSessionTask;

@interface STHTTPNetTaskQueueHandlerOperation : NSObject <NSURLSessionDataDelegate>

@property (nonatomic, strong) STNetTaskQueue *queue;
@property (nonatomic, strong) STHTTPNetTask *task;
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSURL *baseURL;

- (void)start;

@end

@implementation STHTTPNetTaskQueueHandlerOperation
{
    NSMutableData *_data;
}

+ (void)load
{
    STHTTPNetTaskMethodMap = @{ @(STHTTPNetTaskGet): @"GET",
                                @(STHTTPNetTaskDelete): @"DELETE",
                                @(STHTTPNetTaskHead): @"HEAD",
                                @(STHTTPNetTaskPatch): @"PATCH",
                                @(STHTTPNetTaskPost): @"POST",
                                @(STHTTPNetTaskPut): @"PUT" };
    STHTTPNetTaskContentTypeMap = @{ @(STHTTPNetTaskRequestJSON): @"application/json; charset=utf-8",
                                     @(STHTTPNetTaskRequestKeyValueString): @"application/x-www-form-urlencoded",
                                     @(STHTTPNetTaskRequestFormData): @"multipart/form-data" };
    STHTTPNetTaskFormDataBoundary = [NSString stringWithFormat:@"ST-Boundary-%@", [[NSUUID UUID] UUIDString]];
    STHTTPNetTaskToSessionTask = [[NSMapTable alloc] initWithKeyOptions:NSPointerFunctionsWeakMemory valueOptions:NSPointerFunctionsWeakMemory capacity:50];
}

- (void)start
{
    _data = [NSMutableData new];
    
    NSDictionary *headers = self.task.headers;
    NSDictionary *parameters = [[[STHTTPNetTaskParametersPacker alloc] initWithNetTask:_task] pack];
    
    NSURLSessionTask *sessionTask = nil;
    NSMutableURLRequest *request = [NSMutableURLRequest new];
    request.HTTPMethod = STHTTPNetTaskMethodMap[@(_task.method)];
    
    if (_baseURL.user.length || _baseURL.password.length) {
        NSString *credentials = [NSString stringWithFormat:@"%@:%@", _baseURL.user, _baseURL.password];
        [request setValue:[NSString stringWithFormat:@"Basic %@", STBase64String(credentials)] forHTTPHeaderField:@"Authorization"];
    }
    
    switch (_task.method) {
        case STHTTPNetTaskGet:
        case STHTTPNetTaskHead:
        case STHTTPNetTaskDelete: {
            NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:[_baseURL URLByAppendingPathComponent:_task.uri]
                                                        resolvingAgainstBaseURL:NO];
            if (parameters.count) {
                urlComponents.query = [self queryStringFromParameters:parameters];
            }
            request.URL = urlComponents.URL;
        }
            break;
        case STHTTPNetTaskPost:
        case STHTTPNetTaskPut:
        case STHTTPNetTaskPatch: {
            request.URL = [_baseURL URLByAppendingPathComponent:_task.uri];
            NSDictionary *datas = _task.datas;
            if (!datas.count) {
                request.HTTPBody = [self bodyDataFromParameters:parameters requestType:_task.requestType];
                [request setValue:STHTTPNetTaskContentTypeMap[@(_task.requestType)] forHTTPHeaderField:@"Content-Type"];
            }
            else {
                request.HTTPBody = [self formDataFromParameters:parameters datas:datas];
                NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", STHTTPNetTaskFormDataBoundary];
                [request setValue:contentType forHTTPHeaderField: @"Content-Type"];
            }
        }
            break;
        default: {
            NSAssert(NO, @"Invalid STHTTPNetTaskMethod");
        }
            break;
    }
    
    for (NSString *headerField in headers) {
        [request setValue:headers[headerField] forHTTPHeaderField:headerField];
    }
    sessionTask = [_session dataTaskWithRequest:request];
    
    [STHTTPNetTaskToSessionTask setObject:sessionTask forKey:_task];
    
    sessionTask.operation = self;
    [sessionTask resume];
}

#pragma mark - NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    [_data appendData:data];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    if (error && error.code == NSURLErrorCancelled) {
        return;
    }
    
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)task.response;
    NSData *data = [NSData dataWithData:_data];
    if (httpResponse.statusCode >= 200 && httpResponse.statusCode < 300) {
        id responseObj = nil;
        NSError *error = nil;
        switch (_task.responseType) {
            case STHTTPNetTaskResponseRawData:
                responseObj = data;
                break;
            case STHTTPNetTaskResponseString:
                responseObj = [self stringFromData:data];
                break;
            case STHTTPNetTaskResponseJSON:
            default:
                responseObj = [self JSONFromData:data];
                break;
        }
        
        if (!responseObj) {
            error = [NSError errorWithDomain:STHTTPNetTaskResponseParsedError
                                        code:0
                                    userInfo:@{ @"url": httpResponse.URL.absoluteString }];
        }
        
        if (error) {
            [_queue task:_task didFailWithError:error];
        }
        else {
            [_queue task:_task didResponse:responseObj];
        }
    }
    else {
        if (!error) { // Response status code is not 20x
            error = [NSError errorWithDomain:STHTTPNetTaskServerError
                                        code:0
                                    userInfo:@{ STHTTPNetTaskErrorStatusCodeUserInfoKey: @(httpResponse.statusCode),
                                                STHTTPNetTaskErrorResponseDataUserInfoKey: data }];
            [STNetTaskQueueLog log:_task.description];
        }
        [_queue task:_task didFailWithError:error];
    }
}

#pragma makr - Response data parsing methods

- (NSString *)stringFromData:(NSData *)data
{
    @try {
        NSString *string = data.length ? [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] : @"";
        return string;
    }
    @catch (NSException *exception) {
        [STNetTaskQueueLog log:@"String parsed error: %@", exception.debugDescription];
        return nil;
    }
}

- (id)JSONFromData:(NSData *)data
{
    NSError *error;
    id JSON = data.length ? [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error] : @{};
    if (error) {
        [STNetTaskQueueLog log:@"JSON parsed error: %@", error.debugDescription];
        return nil;
    }
    return JSON;
}

#pragma mark - Request data constructing methods

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
        [formData appendData:[[NSString stringWithFormat:@"--%@\r\n", STHTTPNetTaskFormDataBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [formData appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", key, key] dataUsingEncoding:NSUTF8StringEncoding]];
        [formData appendData:[[NSString stringWithFormat:@"Content-Type: %@\r\n\r\n", @"*/*"] dataUsingEncoding:NSUTF8StringEncoding]];
        [formData appendData:fileData];
        [formData appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    }];
    
    [formData appendData:[[NSString stringWithFormat:@"--%@--\r\n", STHTTPNetTaskFormDataBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    return formData;
}

- (void)appendKeyValueToString:(NSMutableString *)string withKey:(NSString *)key value:(NSString *)value
{
    [string appendFormat:@"%@=%@&", key, value];
}

- (void)appendToFormData:(NSMutableData *)formData withKey:(NSString *)key value:(NSString *)value
{
    [formData appendData:[[NSString stringWithFormat:@"--%@\r\n", STHTTPNetTaskFormDataBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [formData appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", key] dataUsingEncoding:NSUTF8StringEncoding]];
    [formData appendData:[[NSString stringWithFormat:@"%@\r\n", value] dataUsingEncoding:NSUTF8StringEncoding]];
}

@end

@interface STHTTPNetTaskQueueHandler () <NSURLSessionDataDelegate>

@end

@implementation STHTTPNetTaskQueueHandler
{
    NSURL *_baseURL;
    NSURLSession *_urlSession;
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
    }
    return self;
}

#pragma mark - STNetTaskQueueHandler

- (void)netTaskQueue:(STNetTaskQueue *)netTaskQueue handleTask:(STNetTask *)task
{
    NSAssert([task isKindOfClass:[STHTTPNetTask class]], @"Net task should be subclass of STHTTPNetTask");
    
    STHTTPNetTaskQueueHandlerOperation *operation = [STHTTPNetTaskQueueHandlerOperation new];
    operation.queue = netTaskQueue;
    operation.task = (STHTTPNetTask *)task;
    operation.baseURL = _baseURL;
    operation.session = _urlSession;
    
    [operation start];
}

- (void)netTaskQueue:(STNetTaskQueue *)netTaskQueue didCancelTask:(STNetTask *)task
{
    NSAssert([task isKindOfClass:[STHTTPNetTask class]], @"Net task should be subclass of STHTTPNetTask");
    
    NSURLSessionTask *sessionTask = [STHTTPNetTaskToSessionTask objectForKey:task];
    [sessionTask cancel];
}

- (void)netTaskQueueDidBecomeInactive:(STNetTaskQueue *)netTaskQueue
{
    [_urlSession invalidateAndCancel];
}

#pragma mark - NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    [dataTask.operation URLSession:session dataTask:dataTask didReceiveData:data];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    [task.operation URLSession:session task:task didCompleteWithError:error];
}

@end
