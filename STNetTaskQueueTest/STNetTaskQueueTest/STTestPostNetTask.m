//
//  STTestPostNetTask.m
//  STNetTaskQueueTest
//
//  Created by Kevin Lin on 19/7/15.
//
//

#import "STTestPostNetTask.h"

@implementation STTestPostNetTask

- (STHTTPNetTaskMethod)method
{
    return STHTTPNetTaskPost;
}

- (NSString *)uri
{
    return @"posts";
}

- (NSDictionary *)parameters
{
    return @{ @"title": self.title,
              @"body": self.body,
              @"userId": @(self.userId) };
}

- (void)didResponseDictionary:(NSDictionary *)dictionary
{
    _post = dictionary;
}

@end
