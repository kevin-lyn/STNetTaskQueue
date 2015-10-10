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

@interface STNetTaskQueue()

@property (nonatomic, strong) NSThread *thred;
@property (nonatomic, strong) NSRecursiveLock *lock;
@property (nonatomic, strong) NSMutableDictionary *taskDelegates; // <NSString, NSArray<STNetTaskDelegateWeakWrapper>>
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

- (void)threadEntryPoint
{
    @autoreleasepool {
        NSRunLoop *runloop = [NSRunLoop currentRunLoop];
        [runloop addPort:[NSPort port] forMode:NSDefaultRunLoopMode]; // Just for keeping the runloop
        [runloop run];
    }
}

- (void)addTask:(STNetTask *)task
{
    NSAssert(self.handler, @"STNetTaskQueueHandler is not set.");
    NSAssert(!task.finished, @"STNetTask is finished, please recreate a net task.");
    if (task.pending) {
        return;
    }
    task.pending = YES;
    [self performSelector:@selector(_addTask:) onThread:self.thred withObject:task waitUntilDone:NO modes:@[ NSRunLoopCommonModes ]];
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
    [self performSelector:@selector(_cancelTask:) onThread:self.thred withObject:task waitUntilDone:NO];
}

- (void)_cancelTask:(STNetTask *)task
{
    [self.tasks removeObject:task];
    [self.watingTasks removeObject:task];
    task.pending = NO;
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
    [self performSelector:@selector(_taskDidResponse:) onThread:self.thred withObject:@{ @"task": task, @"response": response } waitUntilDone:NO];
}

- (void)_taskDidResponse:(NSDictionary *)params
{
    STNetTask *task = params[@"task"];
    id response = params[@"response"];
    
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
                                         userInfo:@{ @"msg": exception.description }];
        
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
    [self performSelector:@selector(_taskDidFailWithError:) onThread:self.thred withObject:@{ @"task": task, @"error": error } waitUntilDone:NO];
}

- (void)_taskDidFailWithError:(NSDictionary *)params
{
    STNetTask *task = params[@"task"];
    NSError *error = params[@"error"];
    
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
    
    NSArray *delegates = self.taskDelegates[task.uri];
    for (STNetTaskDelegateWeakWrapper *weakWrapper in delegates) {
        dispatch_async(dispatch_get_main_queue(), ^ {
            [weakWrapper.delegate netTaskDidEnd:task];
        });
    }
    
    [self.lock unlock];
}

- (void)addTaskDelegate:(id<STNetTaskDelegate>)delegate uri:(NSString *)uri
{
    [self.lock lock];
    
    NSMutableArray *delegates = self.taskDelegates[uri];
    if (!delegates) {
        delegates = [NSMutableArray new];
        self.taskDelegates[uri] = delegates;
    }
    
    NSInteger indexOfDelegate = [self indexOfTaskDelegate:delegate inDelegates:delegates];
    if (indexOfDelegate == NSNotFound) {
        STNetTaskDelegateWeakWrapper *weakWrapper = [STNetTaskDelegateWeakWrapper new];
        weakWrapper.delegate = delegate;
        [delegates addObject:weakWrapper];
    }
    
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
    
    NSMutableArray *delegates = self.taskDelegates[uri];
    NSInteger indexOfDelegate = [self indexOfTaskDelegate:delegate inDelegates:delegates];
    if (indexOfDelegate != NSNotFound) {
        [delegates removeObjectAtIndex:indexOfDelegate];
    }
    
    [self.lock unlock];
}

- (NSInteger)indexOfTaskDelegate:(id<STNetTaskDelegate>)delegate inDelegates:(NSMutableArray *)delegates
{
    NSInteger index = NSNotFound;
    NSMutableArray *toBeDeleted = [NSMutableArray new];
    NSInteger i = 0;
    for (STNetTaskDelegateWeakWrapper *weakWrapper in delegates) {
        if (weakWrapper.delegate == delegate) {
            index = i;
        }
        if (!weakWrapper.delegate) {
            [toBeDeleted addObject:weakWrapper];
        }
        i++;
    }
    
    [delegates removeObjectsInArray:toBeDeleted];
    return index;
}

@end