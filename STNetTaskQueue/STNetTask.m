//
//  STNetTask.m
//  STNetTaskQueue
//
//  Created by Kevin Lin on 29/11/14.
//  Copyright (c) 2014 Sth4Me. All rights reserved.
//

#import "STNetTask.h"

NSString *const STNetTaskUnknownError = @"STNetTaskUnknownError";

@interface STNetTask ()

@property (atomic, assign) BOOL pending;
@property (atomic, assign) BOOL cancelled;
@property (atomic, assign) BOOL finished;

@property (atomic, assign) NSUInteger retryCount;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSMutableArray<STNetTaskSubscriptionBlock> *> *stateToBlock;

@end

@implementation STNetTask

- (NSString *)uri
{
    return @"";
}

- (void)didResponse:(id)response
{
    
}

- (void)didFail
{
    
}

- (void)didRetry
{
    
}

- (NSUInteger)maxRetryCount
{
    return 0;
}

- (BOOL)shouldRetryForError:(NSError *)error
{
    return YES;
}

- (NSTimeInterval)retryInterval
{
    return 0;
}

- (void)subscribeState:(STNetTaskState)state usingBlock:(STNetTaskSubscriptionBlock)block
{
    if ([NSThread isMainThread]) {
        [self _subscribeState:state usingBlock:block];
    }
    else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self _subscribeState:state usingBlock:block];
        });
    }
}

- (void)_subscribeState:(STNetTaskState)state usingBlock:(STNetTaskSubscriptionBlock)block
{
    if (!self.stateToBlock) {
        self.stateToBlock = [NSMutableDictionary new];
    }
    NSMutableArray *blocks = self.stateToBlock[@(state)];
    if (!blocks) {
        blocks = [NSMutableArray new];
        self.stateToBlock[@(state)] = blocks;
    }
    [blocks addObject:[block copy]];
}

- (void)notifyState:(STNetTaskState)state
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSArray *blocks = self.stateToBlock[@(state)];
        for (STNetTaskSubscriptionBlock block in blocks) {
            block();
        }
        switch (state) {
            case STNetTaskStateFinished:
            case STNetTaskStateCancalled: {
                self.stateToBlock = nil;
            }
                break;
            default:
                break;
        }
    });
}

@end
