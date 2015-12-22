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
@property (nonatomic, strong) NSMutableDictionary *stateToBlock;

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
    if (!self.stateToBlock) {
        self.stateToBlock = [NSMutableDictionary new];
    }
    NSAssert(self.stateToBlock[@(state)] == nil, @"State is subscribed already");
    self.stateToBlock[@(state)] = [block copy];
}

- (void)notifyState:(STNetTaskState)state
{
    dispatch_async(dispatch_get_main_queue(), ^{
        STNetTaskSubscriptionBlock block = self.stateToBlock[@(state)];
        if (block) {
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
