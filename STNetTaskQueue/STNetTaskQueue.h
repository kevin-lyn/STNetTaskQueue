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

@protocol STNetTaskDelegate <NSObject>

- (void)netTaskDidEnd:(STNetTask *)task;

@end

@protocol STNetTaskQueueHandler <NSObject>

- (void)netTaskQueue:(STNetTaskQueue *)netTaskQueue task:(STNetTask *)task taskId:(int)taskId;

@end

@interface STNetTaskQueue : NSObject

@property (nonatomic, strong) id<STNetTaskQueueHandler> handler;

+ (instancetype)sharedQueue;
- (void)addTask:(STNetTask *)task;
- (void)cancelTask:(STNetTask *)task;
- (void)didResponse:(id)response taskId:(int)taskId;
- (void)didFailWithError:(NSError *)error taskId:(int)taskId;
- (void)addTaskDelegate:(id<STNetTaskDelegate>)delegate uri:(NSString *)uri;

@end
