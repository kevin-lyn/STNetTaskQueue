//
//  STNetTaskQueue.m
//  STNetTaskQueue
//
//  Created by Kevin Lin on 29/11/14.
//  Copyright (c) 2014 Sth4Me. All rights reserved.
//

#import "STNetTaskQueue.h"
#import "STNetTaskQueueLog.h"
#import "STWebCache.h"

@interface STNetTask (STInternal)

@property (atomic, assign) BOOL pending;
@property (atomic, assign) BOOL cancelled;
@property (atomic, assign) BOOL finished;
@property (atomic, assign) NSUInteger retryCount;

- (void)notifyState:(STNetTaskState)state;

@end

@interface STNetTaskQueue()

@property (nonatomic, strong) NSThread *thread;
@property (nonatomic, strong) NSRecursiveLock *lock;
@property (nonatomic, strong) NSMutableDictionary *taskDelegates; // <NSString, NSHashTable<STNetTaskDelegate>>
@property (nonatomic, strong) NSMutableArray *tasks; // <STNetTask>
@property (nonatomic, strong) NSMutableArray *waitingTasks; // <STNetTask>

@property (nonatomic, strong) STWebCache *cache;

@end

@implementation STNetTaskQueue

@dynamic cachedResponsesDuration;

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
        self.thread = [[NSThread alloc] initWithTarget:self selector:@selector(threadEntryPoint) object:nil];
        self.thread.name = NSStringFromClass(self.class);
        [self.thread start];
        self.lock = [NSRecursiveLock new];
        self.lock.name = [NSString stringWithFormat:@"%@Lock", NSStringFromClass(self.class)];
        self.taskDelegates = [NSMutableDictionary new];
        self.tasks = [NSMutableArray new];
        self.waitingTasks = [NSMutableArray new];
        
        self.cache = [STWebCache sharedInstance];
    }
    return self;
}

- (void)dealloc
{
    [self.handler netTaskQueueDidBecomeInactive:self];
}

- (void)setCachedResponsesDuration:(NSUInteger)cachedResponsesDuration {
    self.cache.cacheDaysDuration = cachedResponsesDuration;
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
    NSAssert(!task.finished && !task.cancelled, @"STNetTask is finished/cancelled, please recreate a net task.");
    
    task.pending = YES;
    [self performInThread:self.thread usingBlock:^{
        [self _addTask:task];
    }];
}

- (void)_addTask:(STNetTask *)task
{
    if (self.maxConcurrentTasksCount > 0 && self.tasks.count >= self.maxConcurrentTasksCount) {
        [self.waitingTasks addObject:task];
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
    
    [self performInThread:self.thread usingBlock:^{
        [self _cancelTask:task];
    }];
}

- (void)_cancelTask:(STNetTask *)task
{
    [self.tasks removeObject:task];
    [self.waitingTasks removeObject:task];
    task.pending = NO;
    
    [self.handler netTaskQueue:self didCancelTask:task];
    task.cancelled = YES;
    [task notifyState:STNetTaskStateCancalled];
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
    if (!task.cancelled) {
        [task didRetry];
        [task notifyState:STNetTaskStateRetrying];
        [self addTask:task];
    }
}

- (void)_sendwaitingTasks
{
    if (!self.waitingTasks.count) {
        return;
    }
    STNetTask *task = self.waitingTasks.firstObject;
    [self.waitingTasks removeObjectAtIndex:0];
    [self addTask:task];
}

- (void)task:(STNetTask *)task didResponse:(id)response
{
    [self performInThread:self.thread usingBlock:^{
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
    [task notifyState:STNetTaskStateFinished];
    
    [self _netTaskDidEnd:task];
    
    [self _sendwaitingTasks];
}

- (void)task:(STNetTask *)task didFailWithError:(NSError *)error
{
    [self performInThread:self.thread usingBlock:^{
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
    [task notifyState:STNetTaskStateFinished];
    
    [self _netTaskDidEnd:task];
    
    [self _sendwaitingTasks];
}

- (void)_netTaskDidEnd:(STNetTask *)task
{
    if ([task conformsToProtocol:@protocol(STNetTaskBlockBasedContract)]) {
        id<STNetTaskBlockBasedContract> blockTask = (STNetTask<STNetTaskBlockBasedContract> *)task;
        if (blockTask.completionHandler != nil) {
            
            dispatch_async(dispatch_get_main_queue(), ^ {
                blockTask.completionHandler(task);
            });
            
            return;
        }
        
    }
    
    [self.lock lock];
    
    NSHashTable *delegatesForURI = self.taskDelegates[task.uri];
    NSHashTable *delegatesForClass = self.taskDelegates[NSStringFromClass(task.class)];
    NSMutableSet *set = [NSMutableSet new];
    [set addObjectsFromArray:delegatesForURI.allObjects];
    [set addObjectsFromArray:delegatesForClass.allObjects];
    NSArray *delegates = set.allObjects;
    
    [self.lock unlock];
    
    if (delegates.count) {
        dispatch_async(dispatch_get_main_queue(), ^ {
            for (id<STNetTaskDelegate> delegate in delegates) {
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

- (void)addTaskDelegate:(id<STNetTaskDelegate>)delegate class:(Class)clazz
{
    NSString *className = NSStringFromClass(clazz);
    NSAssert([clazz isSubclassOfClass:[STNetTask class]], @"%@ should be a subclass of STNetTask", className);
    
    [self.lock lock];
    
    NSHashTable *delegates = self.taskDelegates[className];
    if (!delegates) {
        delegates = [NSHashTable weakObjectsHashTable];
        self.taskDelegates[className] = delegates;
    }
    [delegates addObject:delegate];
    
    [self.lock unlock];
}

- (void)removeTaskDelegate:(id<STNetTaskDelegate>)delegate
{
    [self.lock lock];
    
    for (NSString *key in self.taskDelegates) {
        [self removeTaskDelegate:delegate key:key];
    }
    
    [self.lock unlock];
}

- (void)removeTaskDelegate:(id<STNetTaskDelegate>)delegate uri:(NSString *)uri
{
    [self removeTaskDelegate:delegate key:uri];
}

- (void)removeTaskDelegate:(id<STNetTaskDelegate>)delegate class:(Class)clazz
{
    [self removeTaskDelegate:delegate key:NSStringFromClass(clazz)];
}

- (void)removeTaskDelegate:(id<STNetTaskDelegate>)delegate key:(NSString *)key
{
    [self.lock lock];
    
    NSHashTable *delegates = self.taskDelegates[key];
    [delegates removeObject:delegate];
    
    [self.lock unlock];
}

@end
