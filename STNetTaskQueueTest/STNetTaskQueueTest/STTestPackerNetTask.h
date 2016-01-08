//
//  STTestPackerNetTask.h
//  STNetTaskQueueTest
//
//  Created by Kevin Lin on 8/1/16.
//
//

#import <STNetTaskQueue/STNetTaskQueue.h>

@interface STTestPackerNetTask : STHTTPNetTask

@property (nonatomic, strong) NSString *string;
@property (nonatomic, strong) NSDate *date;
@property (nonatomic, strong) NSDictionary *dictionary;
@property (nonatomic, strong) NSArray *array;
@property (nonatomic, strong, readonly) NSDictionary *post;

@end
