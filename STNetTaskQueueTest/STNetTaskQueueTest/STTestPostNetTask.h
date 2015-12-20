//
//  STTestPostNetTask.h
//  STNetTaskQueueTest
//
//  Created by Kevin Lin on 19/7/15.
//
//

#import <STNetTaskQueue/STHTTPNetTask.h>

@interface STTestPostNetTask : STHTTPNetTask

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *body;
@property (nonatomic, assign) int userId;
@property (nonatomic, strong, readonly) NSDictionary *post;

@end
