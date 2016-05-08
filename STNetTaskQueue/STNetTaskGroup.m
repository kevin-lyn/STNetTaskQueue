//
//  STNetTaskGroup.m
//  STNetTaskQueue
//
//  Created by Kevin Lin on 8/5/16.
//  Copyright © 2016 Sth4Me. All rights reserved.
//

#import "STNetTaskGroup.h"
#import "STNetTaskQueue.h"

@interface STNetTaskGroup ()

@property (nonatomic, strong) STNetTask *executingTask;
@property (nonatomic, strong) NSArray<STNetTask *> *tasks;
@property (nonatomic, assign) BOOL pending;
@property (nonatomic, assign) BOOL started;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSMutableArray<STNetTaskGroupSubscriptionBlock> *> *stateToBlock;
@property (nonatomic, strong) STNetTaskSubscriptionBlock taskSubscriptionBlock; // For serial mode
@property (nonatomic, strong, readonly) STNetTaskQueue *queue;

@end

@implementation STNetTaskGroup

- (instancetype)initWithTasks:(NSArray<STNetTask *> *)tasks mode:(STNetTaskGroupMode)mode
{
    return [self initWithTasks:tasks mode:mode queue:[STNetTaskQueue sharedQueue]];
}

- (instancetype)initWithTasks:(NSArray<STNetTask *> *)tasks mode:(STNetTaskGroupMode)mode queue:(STNetTaskQueue *)queue
{
    if (self = [super init]) {
        self.tasks = [NSArray arrayWithArray:tasks];
        _mode = mode;
        _queue = queue;
    }
    return self;
}

- (void)addTask:(STNetTask *)task
{
    NSMutableArray *tasks = [_tasks mutableCopy];
    [tasks addObject:task];
    self.tasks = [NSArray arrayWithArray:tasks];
}

- (STNetTaskGroup *)subscribeState:(STNetTaskGroupState)state usingBlock:(STNetTaskGroupSubscriptionBlock)block
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
    return self;
}

- (void)notifyState:(STNetTaskGroupState)state withError:(NSError *)error
{
    NSMutableArray<STNetTaskGroupSubscriptionBlock> *blocks = self.stateToBlock[@(state)];
    for (STNetTaskSubscriptionBlock block in blocks) {
        block(self, error);
    }
    self.stateToBlock = nil;
    self.taskSubscriptionBlock = nil;
}

- (void)start
{
    NSAssert(!self.started, @"STNetTaskQueue can not be reused, please create a new instance.");
    if (self.pending) {
        return;
    }
    self.pending = YES;
    self.started = YES;
 
    switch (self.mode) {
        case STNetTaskGroupModeSerial: {
            __block NSUInteger executingTaskIndex = 0;
            __weak STNetTaskGroup *weakSelf = self;
            self.taskSubscriptionBlock = ^{
                if (weakSelf.executingTask.error) {
                    [weakSelf notifyState:STNetTaskGroupStateFinished withError:weakSelf.executingTask.error];
                    return;
                }
                executingTaskIndex++;
                if (executingTaskIndex == weakSelf.tasks.count) {
                    [weakSelf notifyState:STNetTaskGroupStateFinished withError:nil];
                }
                else {
                    weakSelf.executingTask = weakSelf.tasks[executingTaskIndex];
                    [weakSelf.queue addTask:weakSelf.executingTask];
                    [weakSelf.executingTask subscribeState:STNetTaskStateFinished usingBlock:weakSelf.taskSubscriptionBlock];
                }
            };
            self.executingTask = self.tasks[executingTaskIndex];
            [self.queue addTask:self.executingTask];
            [self.executingTask subscribeState:STNetTaskStateFinished usingBlock:self.taskSubscriptionBlock];
        }
            break;
        case STNetTaskGroupModeConcurrent: {
            __block NSUInteger finishedTasksCount = 0;
            for (STNetTask *task in self.tasks) {
                [self.queue addTask:task];
                [task subscribeState:STNetTaskStateFinished usingBlock:^{
                    if (task.error) {
                        [self cancelTasks];
                        [self notifyState:STNetTaskGroupStateFinished withError:task.error];
                        return;
                    }
                    finishedTasksCount++;
                    if (finishedTasksCount == self.tasks.count) {
                        [self notifyState:STNetTaskGroupStateFinished withError:nil];
                    }
                }];
            }
        }
            break;
        default:
            break;
    }
}

- (void)cancel
{
    if (!self.pending) {
        return;
    }
    
    switch (self.mode) {
        case STNetTaskGroupModeSerial: {
            [self.queue cancelTask:self.executingTask];
            self.executingTask = nil;
        }
            break;
        case STNetTaskGroupModeConcurrent: {
            [self cancelTasks];
        }
            break;
        default:
            break;
    }
    [self notifyState:STNetTaskGroupStateCancelled withError:nil];
}

- (void)cancelTasks
{
    for (STNetTask *task in self.tasks) {
        if (task.pending) {
            [self.queue cancelTask:task];
        }
    }
}

@end

@implementation NSArray (STNetTaskGroup)

- (STNetTaskGroup *)serialNetTaskGroup
{
    return [[STNetTaskGroup alloc] initWithTasks:self mode:STNetTaskGroupModeSerial];
}

- (STNetTaskGroup *)serialNetTaskGroupInQueue:(STNetTaskQueue *)queue
{
    return [[STNetTaskGroup alloc] initWithTasks:self mode:STNetTaskGroupModeSerial queue:queue];
}

- (STNetTaskGroup *)concurrentNetTaskGroup
{
    return [[STNetTaskGroup alloc] initWithTasks:self mode:STNetTaskGroupModeConcurrent];
}

- (STNetTaskGroup *)concurrentNetTaskGroupInQueue:(STNetTaskQueue *)queue
{
    return [[STNetTaskGroup alloc] initWithTasks:self mode:STNetTaskGroupModeConcurrent queue:queue];
}

@end
