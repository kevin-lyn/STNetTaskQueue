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

#define STNetTaskObserve(TASK) \
[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) { \
    [[[[RACObserve(TASK, finished) skip:1] ignore:@NO] deliverOnMainThread] subscribeNext:^(id x) { \
        [subscriber sendNext:TASK];\
        [subscriber sendCompleted]; \
    }]; \
    return nil; \
}]
#endif

@class STNetTask;

@protocol STNetTaskDelegate <NSObject>

/*
 This delegate method will be called when the net task is finished(no matter it's successful or failed).
 If the net task is failed, task.error will be non-nil.
 
 @param task STNetTask The finished net task.
 */
- (void)netTaskDidEnd:(STNetTask *)task;

@end

@interface STNetTask : NSObject

/* Error object which contains error message when net task is failed. */
@property (atomic, strong) NSError *error;

/*
 Indicates if the net task is waiting for executing or executing.
 This value will be set to "YES" immediately after the net task is added to net task queue.
 */
@property (atomic, assign) BOOL pending;

/* Indicates if the net task is finished(no matter it's successful or failed). */
@property (atomic, assign) BOOL finished;

/* The current retry time @see maxRetryCount */
@property (atomic, assign) NSUInteger retryCount;

/*
 A unique string represents the net task.
 
 @return NSString The uri string.
 */
- (NSString *)uri;

/*
 A callback method which is called when the net task is finished successfully.
 
 @param response id The response object.
 */
- (void)didResponse:(id)response;

/*
 A callback method which is called when the net task is failed.
 */
- (void)didFail;

/*
 A callback method which is called when the net task is retried.
 */
- (void)didRetry;

/*
 Indicates how many times the net task should be retried after failed.
 Default 0.
 
 @return NSUInteger
 */
- (NSUInteger)maxRetryCount;

/*
 If you are going to retry the net task only when specific error is returned, return NO in this method.
 Default YES.
 
 @param error NSError Error object.
 @return BOOL Should the net task be retried according to the error object.
 */
- (BOOL)shouldRetryForError:(NSError *)error;

/*
 Indicates how many seconds should be delayed before retrying the net task.
 
 @return NSTimeInterval
 */
- (NSTimeInterval)retryInterval;

@end
