//
//  STNetTaskQueue.h
//  STNetTaskQueue
//
//  Created by Kevin Lin on 29/11/14.
//  Copyright (c) 2014 Sth4Me. All rights reserved.
//

#import <Foundation/Foundation.h>

@class STNetTask;
@class STWebCache;
@protocol STNetTaskDelegate;

//! Project version number for STNetTaskQueue.
FOUNDATION_EXPORT double STNetTaskQueueVersionNumber;

//! Project version string for STNetTaskQueue.
FOUNDATION_EXPORT const unsigned char STNetTaskQueueVersionString[];

@class STNetTaskQueue;

@protocol STNetTaskQueueHandler <NSObject>

/**
 STNetTaskQueue will call this method when a net task is added to queue and become ready to be excecuted.
 
 @param netTaskQueue STNetTaskQueue The net task queue which is holding the net task.
 @param task STNetTask The net task which is ready to be executed.
 */
- (void)netTaskQueue:(STNetTaskQueue *)netTaskQueue handleTask:(STNetTask *)task;

/**
 STNetTaskQueue will call this method when a net task is cancelled and removed from net task queue.
 Giving a chance to the handler to do a clean up for the cancelled net task.
 
 @param netTaskQueue STNetTaskQueue The net task queue which is holding the cancelled net task.
 @param task STNetTask The net task which is cancelled and removed from net task queue.
 */
- (void)netTaskQueue:(STNetTaskQueue *)netTaskQueue didCancelTask:(STNetTask *)task;

/**
 STNetTaskQueue will call this method when the net task queue is deallocated.
 
 @param netTaskQueue STNetTaskQueue The net task queue which is deallocated.
 */
- (void)netTaskQueueDidBecomeInactive:(STNetTaskQueue *)netTaskQueue;

@end

@interface STNetTaskQueue : NSObject

/**
  Indicates count of days for cached responses. By default it is equal to 3 days.
*/
@property (nonatomic, assign) NSUInteger cachedResponsesDuration;

/**
 A cache for responses. Set task.useOfflineCache to enabling response caching.
 User cache.clean() to manually clean the cache.
*/
@property (nonatomic, readonly, strong) STWebCache *cache;

/**
 The STNetTaskQueueHandler which is used for handling the net tasks in queue.
 */
@property (nonatomic, strong) id<STNetTaskQueueHandler> handler;

/**
 Count of Max concurrent task in a queue.
 If the number of unfinished tasks in queue hits the max count, upcoming task will be processed till one of the unfinished task is done.
 */
@property (nonatomic, assign) NSUInteger maxConcurrentTasksCount;

/**
 A shared STNetTaskQueue instance.
 */
+ (instancetype)sharedQueue;

/**
 Add a net task into the net task queue.
 The net task may not be executed immediately depends on the "maxConcurrentTasksCount",
 but the net task will be marked as "pending" anyway.
 
 @param task STNetTask The net task to be added into the queue.
 */
- (void)addTask:(STNetTask *)task;

/**
 Cancel and remove the net task from queue.
 If the net task is executing, it will be cancelled and remove from the queue without calling the "netTaskDidEnd" delegate method.
 
 @param task STNetTask The net task to be cancelled and removed from the queue.
 */
- (void)cancelTask:(STNetTask *)task;

/**
 This method should be called when the "handler" finish handling the net task successfully.
 After "handler" called this method, the net task will be marked as "finished", set "pending" as "NO", and removed from the queue.
 
 @param task STNetTask The net task which is handled by "handler".
 @param response id The response object.
 */
- (void)task:(STNetTask *)task didResponse:(id)response;

/**
 This method should be caled when the "handler" finish handling the net task with error.
 After "hadnler" called this method, the net task will be marked as "finished", set "pending" as "NO", and removed from the queue.
 
 @param task STNetTask The net task which is handled by "handler".
 @param error NSError Error object.
 */
- (void)task:(STNetTask *)task didFailWithError:(NSError *)error;

/**
 Add a net task delegate to "STNetTaskQueue" with uri of the net task,
 it's a weak reference and duplicated delegate with same uri will be ignored.
 
 @param delegate id<STNetTaskDelegate>
 @param uri NSString A unique string returned by STNetTask.
 */
- (void)addTaskDelegate:(id<STNetTaskDelegate>)delegate uri:(NSString *)uri;

/**
 Add a net task delegate to "STNetTaskQueue" with class of net task,
 it's a weak reference and duplicated delegate with same class will be ignored.
 
 @param delegate id<STNetTaskDelegate>
 @param class Class Class which extends STNetTask.
 */
- (void)addTaskDelegate:(id<STNetTaskDelegate>)delegate class:(Class)clazz;

/**
 Most of the times you don't need to remove net task delegate explicitly,
 because "STNetTaskQueue" holds weak reference of each delegate.
 
 @param delegate id<STNetTaskDelegate>
 @param uri NSString
 */
- (void)removeTaskDelegate:(id<STNetTaskDelegate>)delegate uri:(NSString *)uri;
- (void)removeTaskDelegate:(id<STNetTaskDelegate>)delegate class:(Class)clazz;
- (void)removeTaskDelegate:(id<STNetTaskDelegate>)delegate;

@end

#import <STNetTaskQueue/STNetTaskChain.h>
#import <STNetTaskQueue/STNetTaskGroup.h>
#import <STNetTaskQueue/STHTTPNetTask.h>
#import <STNetTaskQueue/STHTTPNetTaskQueueHandler.h>