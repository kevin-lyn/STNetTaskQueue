//
//  STNetTask.h
//  STNetTaskQueue
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
    [[[[RACObserve(TASK, cancelled) skip:1] ignore:@NO] deliverOnMainThread] subscribeNext:^(id x) { \
        [subscriber sendError:nil];\
    }]; \
    return nil; \
}]

#endif

@class STNetTask;

typedef void (^STNetTaskCompletionBlock)(STNetTask *task);

@protocol STNetTaskBlockBasedContract <NSObject>

/**
 This handler will be called if STNetTask subclass implements STNetTaskBlockBasedContract.
 If the next task is failed, task.error will be non-nil.
 
 In case if class implements STNetTaskBlockBasedContract, but completion handler is nil, 'netTaskDidEnd:' method will be triggered.
 */
@property (nonatomic, copy) STNetTaskCompletionBlock completionHandler;

@end

@protocol STNetTaskDelegate <NSObject>

/**
 This delegate method will be called when the net task is finished(no matter it's successful or failed).
 If the net task is failed, task.error will be non-nil.
 
 @param task STNetTask The finished net task.
 */
- (void)netTaskDidEnd:(__kindof STNetTask *)task;

@end

typedef NS_ENUM(NSUInteger, STNetTaskState) {
    STNetTaskStateCancalled,
    STNetTaskStateFinished,
    STNetTaskStateRetrying
};

typedef void (^STNetTaskSubscriptionBlock)();

@interface STNetTask : NSObject

/**
 Error object which contains error message when net task is failed.
 */
@property (atomic, strong) NSError *error;

/**
 Indicates if the net task is waiting for executing or executing.
 This value will be set to "YES" immediately after the net task is added to net task queue.
 */
@property (atomic, assign, readonly) BOOL pending;

/**
 Indicates if the net task is cancelled.
 This value would be "NO" by default after net task is created, even the net task is not added to queue.
 */
@property (atomic, assign, readonly) BOOL cancelled;

/**
 Indicates if the net task is finished(no matter it's successful or failed).
 */
@property (atomic, assign, readonly) BOOL finished;

/**
 The current retry time @see maxRetryCount
 */
@property (atomic, assign, readonly) NSUInteger retryCount;


/**
 Indicates if the net task should cache a request. 
 In case if request is failed by internet connection error and cache exists, the task should be finished with the last cached data which is specified for the task.uri.
 */
@property (atomic, assign, readwrite) BOOL useOfflineCache;

/**
 A unique string represents the net task.
 
 @return NSString The uri string.
 */
- (NSString *)uri;

/**
 A callback method which is called when the net task is finished successfully.
 Note: this method will be called in thread of STNetTaskQueue.
 
 @param response id The response object.
 */
- (void)didResponse:(id)response;

/**
 A callback method which is called when the net task is failed.
 Note: this method will be called in thread of STNetTaskQueue.
 */
- (void)didFail;

/**
 A callback method which is called when the net task is retried.
 Note: this method will be called in thread of STNetTaskQueue.
 */
- (void)didRetry;

/**
 Indicates how many times the net task should be retried after failed.
 Default 0.
 
 @return NSUInteger
 */
- (NSUInteger)maxRetryCount;

/**
 If you are going to retry the net task only when specific error is returned, return NO in this method.
 Default YES.
 
 @param error NSError Error object.
 @return BOOL Should the net task be retried according to the error object.
 */
- (BOOL)shouldRetryForError:(NSError *)error;

/**
 Indicates how many seconds should be delayed before retrying the net task.
 
 @return NSTimeInterval
 */
- (NSTimeInterval)retryInterval;

/**
 Subscribe state of net task by using block
 
 @param state STNetTaskState state of net task
 @param block STNetTaskSubscriptionBlock block is called when net task is in subscribed state.
        NOTE: this block will be called in main thread.
 */
- (void)subscribeState:(STNetTaskState)state usingBlock:(STNetTaskSubscriptionBlock)block;

@end
