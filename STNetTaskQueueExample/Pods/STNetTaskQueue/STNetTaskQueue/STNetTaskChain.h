//
//  STNetTaskChain.h
//  Sth4Me
//
//  Created by Kevin Lin on 29/11/14.
//  Copyright (c) 2014 Sth4Me. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STNetTaskQueue.h"

@class STNetTaskChain;

@protocol STNetTaskChainDelegate <NSObject>

- (void)netTaskChainDidEnd:(STNetTaskChain *)netTaskChain;

@end

@interface STNetTaskChain : NSObject

@property (nonatomic, weak) id<STNetTaskChainDelegate> delegate;
@property (nonatomic, strong) STNetTaskQueue *queue;
@property (nonatomic, strong, readonly) NSError *error;
@property (nonatomic, assign, readonly) BOOL started;

- (void)setTasks:(STNetTask *)task, ...;
// Return NO indicates this task should not be sent.
- (BOOL)onNextRequest:(STNetTask *)task;
- (void)onNextResponse:(STNetTask *)task;
- (void)start;
- (void)cancel;

@end
