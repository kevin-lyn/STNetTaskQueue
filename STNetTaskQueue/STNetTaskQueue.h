//
//  STNetTaskQueue.h
//  Sth4Me
//
//  Created by Kevin Lin on 29/11/14.
//  Copyright (c) 2014 Sth4Me. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STNetTask.h"

@class STNetTaskQueue;

@protocol STNetTaskQueueHandler <NSObject>

- (void)netTaskQueue:(STNetTaskQueue *)netTaskQueue task:(STNetTask *)task taskId:(int)taskId;

@end

@interface STNetTaskQueue : NSObject

@property (nonatomic, strong) id<STNetTaskQueueHandler> handler;

// Count of Max concurrent task in a queue.
// If number of unfinished tasks in queue hits the max count, upcoming task will be processed till one the unfinished task is done.
@property (nonatomic, assign) NSUInteger maxConcurrentTasksCount;

+ (instancetype)sharedQueue;

// Add/Cancel a "STNetTask" into queue.
- (void)addTask:(STNetTask *)task;
- (void)cancelTask:(STNetTask *)task;

// Only used in "STNetTaskQueueHandler".
- (void)didResponse:(id)response taskId:(int)taskId;
- (void)didFailWithError:(NSError *)error taskId:(int)taskId;

// Add a task delegate to "STNetTaskQueue",
// it's a weak reference and adding duplicated delegate with same uri will be ignored.
- (void)addTaskDelegate:(id<STNetTaskDelegate>)delegate uri:(NSString *)uri;

// Most of the times you don't need to remove task delegate explicitly,
// because "STNetTaskQueue" holds weak reference of each delegate;
- (void)removeTaskDelegate:(id<STNetTaskDelegate>)delegate uri:(NSString *)uri;
- (void)removeTaskDelegate:(id<STNetTaskDelegate>)delegate;

@end
