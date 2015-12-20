//
//  STTestPatchNetTask.h
//  STNetTaskQueueTest
//
//  Created by Kevin Lin on 19/7/15.
//
//

#import <STNetTaskQueue/STHTTPNetTask.h>

@interface STTestPatchNetTask : STHTTPNetTask

@property (nonatomic, assign) int id;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong, readonly) NSDictionary *post;

@end
