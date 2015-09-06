//
//  STOpenWeatherNetTask.m
//  STNetTaskQueueExample
//
//  Created by Kevin Lin on 9/2/15.
//  Copyright (c) 2015 Sth4Me. All rights reserved.
//

#import "STOpenWeatherNetTask.h"

@implementation STOpenWeatherNetTask

- (STHTTPNetTaskMethod)method
{
    return STHTTPNetTaskGet;
}

- (NSString *)uri
{
    return @"data/2.5/weather";
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

- (void)didResponseDictionary:(NSDictionary *)dictionary
{
    _place = dictionary[@"name"];
    _temperature = [dictionary[@"main"][@"temp"] floatValue] / 10;
}

@end
