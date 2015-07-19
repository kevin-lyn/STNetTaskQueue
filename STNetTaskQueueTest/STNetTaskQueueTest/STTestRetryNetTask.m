//
//  STTestRetryNetTask.m
//  STNetTaskQueueTest
//
//  Created by Kevin Lin on 14/7/15.
//
//

#import "STTestRetryNetTask.h"

@implementation STTestRetryNetTask

- (NSString *)uri
{
    return @"nonexist_uri";
}

- (void)didRetry
{
    NSLog(@"retryCount: %tu", self.retryCount);
}

- (NSUInteger)maxRetryCount
{
    return 3;
}

@end
