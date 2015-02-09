//
//  STNetTaskChain.m
//  Sth4Me
//
//  Created by Kevin Lin on 29/11/14.
//  Copyright (c) 2014 Sth4Me. All rights reserved.
//

#import "STNetTaskChain.h"

@interface STNetTaskChain()<STNetTaskDelegate>

@property (nonatomic, strong) NSArray *allTasks;
@property (nonatomic, assign) int taskIndex;

@end

@implementation STNetTaskChain

- (void)setTasks:(STNetTask *)task, ...
{
    NSMutableArray *tasks = [NSMutableArray array];
    va_list args;
    va_start(args, task);
    STNetTask *nextTask = nil;
    for (nextTask = task; nextTask != nil; nextTask = va_arg(args, STNetTask *)) {
        [tasks addObject:nextTask];
        [self.queue addTaskDelegate:self uri:nextTask.uri];
    }
    va_end(args);
    self.allTasks = tasks;
}

- (BOOL)onNextRequest:(STNetTask *)task
{
    return YES;
}

- (void)onNextResponse:(STNetTask *)task
{
    
}

- (void)start
{
    if (_started) {
        return;
    }
    _started = YES;
    _error = nil;
    self.taskIndex = 0;
    [self nextRequest];
}

- (void)cancel
{
    if (!_started) {
        return;
    }
    _started = NO;
    for (STNetTask *task in self.allTasks) {
        [self.queue cancelTask:task];
    }
}

- (void)nextRequest
{
    while (_started) {
        if (self.taskIndex >= self.allTasks.count) {
            _started = NO;
            [self.delegate netTaskChainDidEnd:self];
            return;
        }
        STNetTask *task = [self.allTasks objectAtIndex:self.taskIndex];
        self.taskIndex++;
        if ([self onNextRequest:task]) {
            [self.queue addTask:task];
            return;
        }
    }
}

- (void)netTaskDidEnd:(STNetTask *)task
{
    if (![self.allTasks containsObject:task]) {
        return;
    }
    
    if (task.error) {
        _error = task.error;
        [self.delegate netTaskChainDidEnd:self];
    }
    else {
        [self onNextResponse:task];
        [self nextRequest];
    }
}

@end

