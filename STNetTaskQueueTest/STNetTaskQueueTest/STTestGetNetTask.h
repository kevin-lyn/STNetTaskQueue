//
//  STTestGetNetTask.h
//  STNetTaskQueueTest
//
//  Created by Kevin Lin on 19/7/15.
//
//

#import <STNetTaskQueue/STNetTaskQueue.h>

@interface STTestGetNetTask : STHTTPNetTask

@property (nonatomic, assign) int id;
@property (nonatomic, strong, readonly) NSDictionary *post;

@end
