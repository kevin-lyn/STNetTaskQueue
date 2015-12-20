//
//  STTestPutNetTask.h
//  STNetTaskQueueTest
//
//  Created by Kevin Lin on 19/7/15.
//
//

#import <STNetTaskQueue/STNetTaskQueue.h>

@interface STTestPutNetTask : STHTTPNetTask

@property (nonatomic, assign) int id;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *body;
@property (nonatomic, assign) int userId;
@property (nonatomic, strong, readonly) NSDictionary *post;

@end
