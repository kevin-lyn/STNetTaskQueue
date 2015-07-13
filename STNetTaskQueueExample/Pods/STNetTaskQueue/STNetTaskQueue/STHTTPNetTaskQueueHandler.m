//
//  STHTTPNetTaskQueueHandler.m
//  Sth4Me
//
//  Created by Kevin Lin on 29/11/14.
//  Copyright (c) 2014 Sth4Me. All rights reserved.
//

#import "STHTTPNetTaskQueueHandler.h"
#import "STHTTPNetTask.h"
#import "AFNetworking.h"

@implementation STHTTPNetTaskQueueHandler
{
    AFHTTPSessionManager *_httpManager;
}

- (instancetype)initWithBaseURL:(NSURL *)baseURL
{
    if (self = [super init]) {
        _httpManager = [[AFHTTPSessionManager alloc] initWithBaseURL:baseURL];
    }
    return self;
}

- (void)netTaskQueue:(STNetTaskQueue *)netTaskQueue task:(STNetTask *)task taskId:(int)taskId
{
    NSAssert([task isKindOfClass:[STHTTPNetTask class]], @"Should be subclass of STHTTPNetTask");
    
    void (^success)(NSURLSessionDataTask *, id) = ^(NSURLSessionDataTask *task, id responseObject) {
        [netTaskQueue didResponse:responseObject taskId:taskId];
    };
    
    void (^failure)(NSURLSessionDataTask *, NSError *) = ^(NSURLSessionDataTask *task, NSError *error) {
        [netTaskQueue didFailWithError:error taskId:taskId];
    };
    
    STHTTPNetTask *httpTask = (STHTTPNetTask *)task;
    NSDictionary *parameters = [httpTask parameters];
    
    switch ([httpTask method]) {
        case STHTTPNetTaskGet: {
            [_httpManager GET:[httpTask uri] parameters:parameters success:success failure:failure];
        }
            break;
        case STHTTPNetTaskPost: {
            NSDictionary *datas = [httpTask datas];
            if (!datas.count) {
                [_httpManager POST:[httpTask uri] parameters:parameters success:success failure:failure];
            }
            else {
                [_httpManager POST:[httpTask uri] parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
                    for (NSString *name in datas) {
                        [formData appendPartWithFileData:datas[name] name:name fileName:@"st_file" mimeType:@"*/*"];
                    }
                } success:success failure:failure];
            }
        }
            break;
        case STHTTPNetTaskPut: {
            [_httpManager PUT:[httpTask uri] parameters:parameters success:success failure:failure];
        }
            break;
        case STHTTPNetTaskDelete: {
            [_httpManager DELETE:[httpTask uri] parameters:parameters success:success failure:failure];
        }
            break;
        case STHTTPNetTaskPatch: {
            [_httpManager PATCH:[httpTask uri] parameters:parameters success:success failure:failure];
        }
            break;
        case STHTTPNetTaskHead: {
            [_httpManager HEAD:[httpTask uri] parameters:parameters success:^(NSURLSessionDataTask *task) {
                [netTaskQueue didResponse:@{} taskId:taskId];
            } failure:failure];
        }
            break;
        default: {
            NSAssert(NO, @"Invalid STHTTPNetTaskMethod");
        }
            break;
    }
}

@end
