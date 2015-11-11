//
//  STNetTaskQueue.m
//  Sth4Me
//
//  Created by Kevin Lin on 29/11/14.
//  Copyright (c) 2014 Sth4Me. All rights reserved.
//

#import "STNetTaskQueue.h"
#import "STNetTaskQueueLog.h"

@interface STNetTaskQueue()

@property (nonatomic, strong) NSThread *thred;
@property (nonatomic, strong) NSRecursiveLock *lock;
@property (nonatomic, strong) NSMutableDictionary *taskDelegates; // <NSString, NSHashTable<STNetTaskDelegate>>
@property (nonatomic, strong) NSMutableArray *tasks; // <STNetTask>
@property (nonatomic, strong) NSMutableArray *watingTasks; // <STNetTask>

@end

@implementation STNetTaskQueue

+ (instancetype)sharedQueue
{
    static STNetTaskQueue *sharedQueue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedQueue = [self new];
    });
    return sharedQueue;
}

- (id)init
{    
    if (self = [super init]) {
        self.thred = [[NSThread alloc] initWithTarget:self selector:@selector(threadEntryPoint) object:nil];
        self.thred.name = NSStringFromClass(self.class);
        [self.thred start];
        self.lock = [NSRecursiveLock new];
        self.lock.name = [NSString stringWithFormat:@"%@Lock", NSStringFromClass(self.class)];
        self.taskDelegates = [NSMutableDictionary new];
        self.tasks = [NSMutableArray new];
        self.watingTasks = [NSMutableArray new];
    }
    return self;
}

- (void)dealloc
{
    [self.handler netTaskQueueDidBecomeInactive:self];
}

- (void)threadEntryPoint
{
    @autoreleasepool {
        NSRunLoop *runloop = [NSRunLoop currentRunLoop];
        [runloop addPort:[NSPort port] forMode:NSDefaultRunLoopMode]; // Just for keeping the runloop
        [runloop run];
    }
}

- (void)performInThread:(NSThread *)thread usingBlock:(void(^)())block
{
    [self performSelector:@selector(performUsingBlock:) onThread:thread withObject:block waitUntilDone:NO];
}

- (void)performUsingBlock:(void(^)())block
{
    block();
}

- (void)addTask:(STNetTask *)task
{
    NSAssert(self.handler, @"STNetTaskQueueHandler is not set.");
    NSAssert(!task.finished, @"STNetTask is finished, please recreate a net task.");
    
    task.pending = YES;
    [self performInThread:self.thred usingBlock:^{
        [self _addTask:task];
    }];
}

- (void)_addTask:(STNetTask *)task
{
    if (self.maxConcurrentTasksCount > 0 && self.tasks.count >= self.maxConcurrentTasksCount) {
        [self.watingTasks addObject:task];
        return;
    }

    [self.tasks addObject:task];
    [self.handler netTaskQueue:self handleTask:task];
}

- (void)cancelTask:(STNetTask *)task
{
    if (!task) {
        return;
    }
    
    [self performInThread:self.thred usingBlock:^{
        [self _cancelTask:task];
    }];
}

- (void)_cancelTask:(STNetTask *)task
{
    [self.tasks removeObject:task];
    [self.watingTasks removeObject:task];
    task.pending = NO;
    
    [self.handler netTaskQueue:self didCancelTask:task];
}

- (BOOL)_retryTask:(STNetTask *)task withError:(NSError *)error
{
    if ([task shouldRetryForError:error] && task.retryCount < task.maxRetryCount) {
        task.retryCount++;
        [self performSelector:@selector(_retryTask:) withObject:task afterDelay:task.retryInterval];
        return YES;
    }
    return NO;
}

- (void)_retryTask:(STNetTask *)task
{
    [task didRetry];
    [self addTask:task];
}

- (void)_sendWatingTasks
{
    if (!self.watingTasks.count) {
        return;
    }
    STNetTask *task = self.watingTasks.firstObject;
    [self.watingTasks removeObjectAtIndex:0];
    [self addTask:task];
}

- (void)task:(STNetTask *)task didResponse:(id)response
{
    [self performInThread:self.thred usingBlock:^{
        [self _task:task didResponse:response];
    }];
}

- (void)_task:(STNetTask *)task didResponse:(id)response
{
    if (![self.tasks containsObject:task]) {
        return;
    }
    [self.tasks removeObject:task];
    
    @try {
        [task didResponse:response];
    }
    @catch (NSException *exception) {
        [STNetTaskQueueLog log:@"Exception in 'didResponse' - %@", exception.debugDescription];
        NSError *error = [NSError errorWithDomain:STNetTaskUnknownError
                                             code:-1
                                         userInfo:@{ @"msg": exception.description ? : @"nil" }];
        
        if ([self _retryTask:task withError:error]) {
            return;
        }
        
        task.error = error;
        [task didFail];
    }
    
    task.pending = NO;
    task.finished = YES;
    
    [self _netTaskDidEnd:task];
    
    [self _sendWatingTasks];
}

- (void)task:(STNetTask *)task didFailWithError:(NSError *)error
{
    [self performInThread:self.thred usingBlock:^{
        [self _task:task didFailWithError:error];
    }];
}

- (void)_task:(STNetTask *)task didFailWithError:(NSError *)error
{
    if (![self.tasks containsObject:task]) {
        return;
    }
    [self.tasks removeObject:task];
    
    [STNetTaskQueueLog log:error.debugDescription];
    
    if ([self _retryTask:task withError:error]) {
        return;
    }
    
    task.error = error;
    [task didFail];
    task.pending = NO;
    task.finished = YES;
    
    [self _netTaskDidEnd:task];
    
    [self _sendWatingTasks];
}

- (void)_netTaskDidEnd:(STNetTask *)task
{
    [self.lock lock];
    
    NSHashTable *delegates = self.taskDelegates[task.uri];
    NSArray *allDelegates = [NSArray arrayWithArray:delegates.allObjects];
    
    [self.lock unlock];
    
    if (allDelegates.count) {
        dispatch_async(dispatch_get_main_queue(), ^ {
            for (id<STNetTaskDelegate> delegate in allDelegates) {
                [delegate netTaskDidEnd:task];
            }
        });
    }
}

- (void)addTaskDelegate:(id<STNetTaskDelegate>)delegate uri:(NSString *)uri
{
    [self.lock lock];
    
    NSHashTable *delegates = self.taskDelegates[uri];
    if (!delegates) {
        delegates = [NSHashTable weakObjectsHashTable];
        self.taskDelegates[uri] = delegates;
    }
    [delegates addObject:delegate];
    
    [self.lock unlock];
}

- (void)removeTaskDelegate:(id<STNetTaskDelegate>)delegate
{
    [self.lock lock];
    
    for (NSString *uri in self.taskDelegates) {
        [self removeTaskDelegate:delegate uri:uri];
    }
    
    [self.lock unlock];
}

- (void)removeTaskDelegate:(id<STNetTaskDelegate>)delegate uri:(NSString *)uri
{
    [self.lock lock];
    
    NSHashTable *delegates = self.taskDelegates[uri];
    [delegates removeObject:delegate];
    
    [self.lock unlock];
}

@end