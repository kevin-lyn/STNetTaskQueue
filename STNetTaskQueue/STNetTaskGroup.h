//
//  STNetTaskGroup.h
//  STNetTaskQueue
//
//  Created by Kevin Lin on 8/5/16.
//  Copyright © 2016 Sth4Me. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class STNetTask;
@class STNetTaskQueue;
@class STNetTaskGroup;

typedef NS_ENUM(NSUInteger, STNetTaskGroupMode) {
    STNetTaskGroupModeSerial,
    STNetTaskGroupModeConcurrent
};

typedef NS_ENUM(NSUInteger, STNetTaskGroupState) {
    STNetTaskGroupStateCancelled,
    STNetTaskGroupStateFinished
};

/**
 @param group STNetTaskGroup
 @param error NSError the first error was encountered in the group.
 */
typedef void (^STNetTaskGroupSubscriptionBlock)(STNetTaskGroup *group, NSError  * _Nullable error);

/**
 STNetTaskGroup is a group to execute STNetTasks in serial or concurrent mode.
 NOTE: STNetTaskGroup is currently not thread safe.
 */
@interface STNetTaskGroup : NSObject

/**
 The executing task in the group when it is in STNetTaskGroupModeSerial.
 It will be always 'nil' when the group is in STNetTaskGroupModeConcurrent.
 */
@property (nullable, nonatomic, strong, readonly) STNetTask *executingTask;

/**
 All tasks in this group.
 */
@property (nonatomic, strong, readonly) NSArray<STNetTask *> *tasks;

/**
 The STNetTaskGroupMode is being used.
 */
@property (nonatomic, assign, readonly) STNetTaskGroupMode mode;

/**
 Indicates if the group is executing tasks.
 */
@property (nonatomic, assign, readonly) BOOL pending;

/**
 Init with an array of net tasks and mode.
 [STNetTaskQueue sharedQueue] will be used for executing tasks in the group.
 
 @param tasks NSArray
 @param mode STNetTaskGroupMode indicates the tasks in this group should be sent serially or concurrently.
 */
- (instancetype)initWithTasks:(NSArray<STNetTask *> *)tasks mode:(STNetTaskGroupMode)mode;

/**
 Init with an array of net tasks, mode and the queue which will be used for executing tasks.
 
 @param tasks NSArray
 @param mode STNetTaskGroupMode indicates the tasks in this group should be sent serially or concurrently.
 @param queue STNetTaskQueue the queue which is used for executing tasks in the group.
 */
- (instancetype)initWithTasks:(NSArray<STNetTask *> *)tasks mode:(STNetTaskGroupMode)mode queue:(STNetTaskQueue *)queue NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

/**
 Add a new task to this group.
 
 @param task STNetTask
 */
- (void)addTask:(STNetTask *)task;

/**
 Subscribe state with STNetTaskGroupSubscriptionBlock.
 
 @param state STNetTaskGroupState
 @param block STNetTaskGroupSubscriptionBlock
 */
- (STNetTaskGroup *)subscribeState:(STNetTaskGroupState)state usingBlock:(STNetTaskGroupSubscriptionBlock)block;

/**
 Start executing tasks in this group.
 */
- (void)start;

/**
 Cancel all tasks in this group.
 */
- (void)cancel;

@end

/**
 Handy category for executing tasks in an array.
 */
@interface NSArray (STNetTaskGroup)

- (STNetTaskGroup *)serialNetTaskGroup;
- (STNetTaskGroup *)serialNetTaskGroupInQueue:(STNetTaskQueue *)queue;
- (STNetTaskGroup *)concurrentNetTaskGroup;
- (STNetTaskGroup *)concurrentNetTaskGroupInQueue:(STNetTaskQueue *)queue;

@end

NS_ASSUME_NONNULL_END
