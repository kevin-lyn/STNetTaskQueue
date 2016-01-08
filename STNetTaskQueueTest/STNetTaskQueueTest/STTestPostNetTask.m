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

// Optional. Retry 3 times after error occurs.
- (NSUInteger)maxRetryCount
{
    return 3;
}

// Optional. Retry for all types of errors
- (BOOL)shouldRetryForError:(NSError *)error
{
    return YES;
}

// Optional. Retry after 5 seconds.
- (NSTimeInterval)retryInterval
{
    return 5;
}

// Optional. Custom headers.
- (NSDictionary *)headers
{
    return @{ @"custom_header": @"value" };
}

// Optional. Add parameters which are not inclued in requestObject and net task properties.
- (NSDictionary *)parameters
{
    return @{ @"other_parameter": @"value" };
}

// Optional. Transform value to a format you want.
- (id)transformValue:(id)value
{
    if ([value isKindOfClass:[NSDate class]]) {
        return @([value timeIntervalSince1970]);
    }
    return value;
}

- (void)didResponseDictionary:(NSDictionary *)dictionary
{
    _post = dictionary;
}

@end
