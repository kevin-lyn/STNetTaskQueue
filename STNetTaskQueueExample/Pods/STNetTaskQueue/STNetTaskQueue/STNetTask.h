//
//  STNetTask.h
//  Sth4Me
//
//  Created by Kevin Lin on 29/11/14.
//  Copyright (c) 2014 Sth4Me. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString *const STNetTaskUnknownError;

#ifdef RACObserve

#define STNetTaskObserve(TASK) [[[RACObserve(TASK, finished) ignore:@NO] deliverOnMainThread] map:^id(id value) { return TASK; }]

#endif

@class STNetTask;

@protocol STNetTaskDelegate <NSObject>

- (void)netTaskDidEnd:(STNetTask *)task;

@end

@interface STNetTask : NSObject

@property (nonatomic, strong) NSError *error;
@property (nonatomic, assign) BOOL pending;
@property (nonatomic, assign) BOOL finished;
@property (nonatomic, assign) NSUInteger retryCount;

- (NSString *)uri;
- (void)didResponse:(id)response;
- (void)didFail;
- (void)didRetry;

- (NSUInteger)maxRetryCount;
- (BOOL)shouldRetryForError:(NSError *)error;
- (NSTimeInterval)retryInterval;

@end
