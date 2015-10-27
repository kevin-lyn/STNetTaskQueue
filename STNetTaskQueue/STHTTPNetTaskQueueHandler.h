//
//  STHTTPNetTaskQueueHandler.h
//  Sth4Me
//
//  Created by Kevin Lin on 29/11/14.
//  Copyright (c) 2014 Sth4Me. All rights reserved.
//

#import "STNetTaskQueue.h"

@interface STHTTPNetTaskQueueHandler : NSObject<STNetTaskQueueHandler>

/*
 Init the handler with base URL, a base URL will be used for constructing the whole url for HTTP net tasks.
 E.g HTTP net task returns uri "user/profile", handled by handler with baseURL "http://example.com", the whole url will be http://example.com/user/profile".
 
 @param baseURL NSURL
 */
- (instancetype)initWithBaseURL:(NSURL *)baseURL;

/*
 Init the handler with baseURL and NSURLSessionConfiguration.
 
 @param baseURL NSURL
 */
- (instancetype)initWithBaseURL:(NSURL *)baseURL configuration:(NSURLSessionConfiguration *)configuration;

@end
