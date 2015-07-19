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

- (void)didResponseJSON:(NSDictionary *)json
{
    _post = json;
}

@end
