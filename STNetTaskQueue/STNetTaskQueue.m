//
//  STNetTaskQueue.m
//  Sth4Me
//
//  Created by Kevin Lin on 29/11/14.
//  Copyright (c) 2014 Sth4Me. All rights reserved.
//

#import "STNetTaskQueue.h"
#import "STNetTaskQueueLog.h"

@interface STNetTaskDelegateWeakWrapper : NSObject

@property (nonatomic, weak) id<STNetTaskDelegate> delegate;

@end

@implementation STNetTaskDelegateWeakWrapper

@end

static STNetTaskQueue *sharedInstance;

@interface STNetTaskQueue()

@property (atomic, strong) NSMutableDictionary *tasks; // <NSNumber, STNetTask>
@property (atomic, strong) NSMutableDictionary *taskDelegates; // <NSString, NSArray<STNetTaskDelegate>>
@property (atomic, strong) NSOperationQueue *queue;
@property (atomic, strong) NSMutableArray *watingTasks; // <STNetTask>
@property (atomic, assign) int currentTaskId;

@end

@implementation STNetTaskQueue

+ (instancetype)sharedQueue
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [self new];
    });
    return sharedInstance;
}

- (id)init
{    
    if (self = [super init]) {
        self.tasks = [NSMutableDictionary new];
        self.taskDelegates = [NSMutableDictionary new];
        self.queue = [NSOperationQueue new];
        self.queue.name = @"STNetTaskQueue";
        self.queue.maxConcurrentOperationCount = 1;
        self.watingTasks = [NSMutableArray new];
    }
    return self;
}

- (void)addTask:(STNetTask *)task
{
    NSAssert(self.handler, @"STNetTaskQueueHandler is not set.");
    NSAssert(!task.finished, @"STNetTask is finished, please recreate a new net task.");
    
    task.pending = YES;
    __weak STNetTaskQueue *weakSelf = self;
    [self.queue addOperationWithBlock:^ {
        @synchronized(weakSelf.tasks) {
            if (weakSelf.maxConcurrentTasksCount > 0 && weakSelf.tasks.count >= weakSelf.maxConcurrentTasksCount) {
                [weakSelf.watingTasks addObject:task];
                return;
            }
        }
        
        int taskId;
        @synchronized(weakSelf) {
            weakSelf.currentTaskId++;
            taskId = weakSelf.currentTaskId;
        }
        
        [weakSelf.handler netTaskQueue:weakSelf task:task taskId:taskId];
        @synchronized(weakSelf.tasks) {
            [weakSelf.tasks setObject:task forKey:@(taskId)];
        }
    }];
}

- (void)cancelTask:(STNetTask *)task
{
    if (!task) {
        return;
    }
    
    __weak STNetTaskQueue *weakSelf = self;
    [self.queue addOperationWithBlock:^ {
        
        NSNumber *taskIdToBeRemoved = nil;
        @synchronized(weakSelf.tasks) {
            for (NSNumber *taskId in weakSelf.tasks.allKeys) {
                if ([weakSelf.tasks objectForKey:taskId] == task) {
                    taskIdToBeRemoved = taskId;
                    break;
                }
            }
            if (taskIdToBeRemoved) {
                [weakSelf.tasks removeObjectForKey:taskIdToBeRemoved];
            }
        }
        
        if (taskIdToBeRemoved) {
            [weakSelf sendWatingTask];
        }
        else {
            @synchronized(weakSelf.watingTasks) {
                [weakSelf.watingTasks removeObject:task];
            }
        }
        
        task.pending = NO;
    }];
}

- (BOOL)retryTask:(STNetTask *)task withError:(NSError *)error
{
    if ([task shouldRetryForError:error] && task.retryCount < task.maxRetryCount) {
        task.retryCount++;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(task.retryInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [task didRetry];
            [self addTask:task];
        });
        return YES;
    }
    return NO;
}

- (void)sendWatingTask
{
    STNetTask *task;
    @synchronized(self.watingTasks) {
        if (!self.watingTasks.count) {
            return;
        }
        task = self.watingTasks[0];
        [self.watingTasks removeObjectAtIndex:0];
    }
    [self addTask:task];
}

- (void)didResponse:(id)response taskId:(int)taskId
{
    __weak STNetTaskQueue *weakSelf = self;
    [self.queue addOperationWithBlock:^ {
        
        STNetTask *task = nil;
        @synchronized(weakSelf.tasks) {
            task = [weakSelf.tasks objectForKey:@(taskId)];
            if (!task) {
                return;
            }
            [weakSelf.tasks removeObjectForKey:@(taskId)];
        }
        
        @try {
            [task didResponse:response];
        }
        @catch (NSException *exception) {
            [STNetTaskQueueLog log:@"Exception in 'didResponse' - %@", exception.debugDescription];
            NSError *error = [NSError errorWithDomain:STNetTaskUnknownError
                                                 code:-1
                                             userInfo:@{ @"msg": exception.description }];
            
            if ([weakSelf retryTask:task withError:error]) {
                return;
            }
            
            task.error = error;
            [task didFail];
        }
        
        [weakSelf netTaskDidEnd:task];
        task.pending = NO;
        task.finished = YES;
        
        [weakSelf sendWatingTask];
    }];
}

- (void)didFailWithError:(NSError *)error taskId:(int)taskId
{
    __weak STNetTaskQueue *weakSelf = self;
    [self.queue addOperationWithBlock:^ {
        
        [STNetTaskQueueLog log:error.debugDescription];
        
        STNetTask *task = nil;
        @synchronized(weakSelf.tasks) {
            task = [weakSelf.tasks objectForKey:@(taskId)];
            if (!task) {
                return;
            }
            [weakSelf.tasks removeObjectForKey:@(taskId)];
        }
        
        if ([weakSelf retryTask:task withError:error]) {
            return;
        }
        
        task.error = error;
        [task didFail];
        [weakSelf netTaskDidEnd:task];
        task.pending = NO;
        task.finished = YES;
        
        [weakSelf sendWatingTask];
    }];
}

- (void)netTaskDidEnd:(STNetTask *)task
{
    NSArray *delegates = [self.taskDelegates objectForKey:task.uri];
    for (STNetTaskDelegateWeakWrapper *weakWrapper in delegates) {
        dispatch_async(dispatch_get_main_queue(), ^ {
            [weakWrapper.delegate netTaskDidEnd:task];
        });
    }
}

- (void)addTaskDelegate:(id<STNetTaskDelegate>)delegate uri:(NSString *)uri
{
    NSAssert([NSThread isMainThread], @"addTaskDelegate: must be involked in main thread.");
    NSAssert(delegate && uri, @"addTaskDelegate: trying to addTaskDelegate with nil delegate or uri.");
    
    NSMutableArray *delegates = [self.taskDelegates objectForKey:uri];
    if (!delegates) {
        delegates = [NSMutableArray new];
        [self.taskDelegates setObject:delegates forKey:uri];
    }
    
    BOOL delegateExisted = NO;
    NSMutableArray *toBeDeleted = [NSMutableArray new];
    for (STNetTaskDelegateWeakWrapper *weakWrapper in delegates) {
        if (weakWrapper.delegate == delegate) {
            delegateExisted = YES;
        }
        if (!weakWrapper.delegate) {
            [toBeDeleted addObject:weakWrapper];
        }
    }
    
    [delegates removeObjectsInArray:toBeDeleted];
    
    if (!delegateExisted) {
        STNetTaskDelegateWeakWrapper *weakWrapper = [STNetTaskDelegateWeakWrapper new];
        weakWrapper.delegate = delegate;
        
        [delegates addObject:weakWrapper];
    }
}

@end