//
//  STTestDeleteNetTask.m
//  STNetTaskQueueTest
//
//  Created by Kevin Lin on 19/7/15.
//
//

#import "STTestDeleteNetTask.h"

@implementation STTestDeleteNetTask

- (STHTTPNetTaskMethod)method
{
    return STHTTPNetTaskDelete;
}

- (NSString *)uri
{
    return [NSString stringWithFormat:@"posts/%d", self.id];
}

- (NSArray *)ignoredProperties
{
    return STHTTPNetTaskIgnoreAllProperties;
}

@end
