//
//  STTestPutNetTask.m
//  STNetTaskQueueTest
//
//  Created by Kevin Lin on 19/7/15.
//
//

#import "STTestPutNetTask.h"

@implementation STTestPutNetTask

- (STHTTPNetTaskMethod)method
{
    return STHTTPNetTaskPut;
}

- (NSString *)uri
{
    return [NSString stringWithFormat:@"posts/%d", self.id];
}

- (NSDictionary *)parameters
{
    return @{ @"id": @(self.id),
              @"title": self.title,
              @"body": self.body,
              @"userId": @(self.userId) };
}

- (void)didResponseJSON:(NSDictionary *)json
{
    _post = json;
}

@end
