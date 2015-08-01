//
//  STTestMaxConcurrentTasksCountNetTask.m
//  STNetTaskQueueTest
//
//  Created by Kevin Lin on 1/8/15.
//
//

#import "STTestMaxConcurrentTasksCountNetTask.h"

@implementation STTestMaxConcurrentTasksCountNetTask

- (NSString *)uri
{
    return @"nonexist_uri";
}

- (void)didRetry
{
    NSLog(@"id: %d, retryCount: %tu", self.id, self.retryCount);
}

- (NSUInteger)maxRetryCount
{
    return 3;
}

@end
