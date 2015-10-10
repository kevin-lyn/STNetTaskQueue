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
    [[[[RACObserve(TASK, pending) skip:1] ignore:@YES] deliverOnMainThread] subscribeNext:^(id x) { \
        [subscriber sendCompleted]; \
    }]; \
    return nil; \
}]
#endif

@class STNetTask;

@protocol STNetTaskDelegate <NSObject>

- (void)netTaskDidEnd:(STNetTask *)task;

@end

@interface STNetTask : NSObject

@property (atomic, strong) NSError *error;
@property (atomic, assign) BOOL pending;
@property (atomic, assign) BOOL finished;
@property (atomic, assign) NSUInteger retryCount;

- (NSString *)uri;
- (void)didResponse:(id)response;
- (void)didFail;
- (void)didRetry;

- (NSUInteger)maxRetryCount;
- (BOOL)shouldRetryForError:(NSError *)error;
- (NSTimeInterval)retryInterval;

@end
