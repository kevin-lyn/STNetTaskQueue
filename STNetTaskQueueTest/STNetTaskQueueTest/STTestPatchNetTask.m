//
//  STTestPatchNetTask.m
//  STNetTaskQueueTest
//
//  Created by Kevin Lin on 19/7/15.
//
//

#import "STTestPatchNetTask.h"

@implementation STTestPatchNetTask

- (STHTTPNetTaskMethod)method
{
    return STHTTPNetTaskPatch;
}

- (NSString *)uri
{
    return [NSString stringWithFormat:@"posts/%d", self.id];
}

- (NSDictionary *)parameters
{
    return @{ @"title": self.title };
}

- (void)didResponseDictionary:(NSDictionary *)dictionary
{
    _post = dictionary;
}

- (NSArray *)ignoredProperties
{
    return @[ @"id" ];
}

@end
