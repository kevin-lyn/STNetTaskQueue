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

- (NSUInteger)maxRetryCount
{
    return 3; // Retry after error occurs
}

- (BOOL)shouldRetryForError:(NSError *)error
{
    return YES; // Retry for all kinds of errors
}

- (NSTimeInterval)retryInterval
{
    return 5; // Retry after 5 seconds
}

- (NSDictionary *)headers
{
    return @{ @"custom_header": @"value" };
}

- (NSDictionary *)parameters
{
    NSLog(@"Pack request parameters");
    return @{ @"lat": self.latitude,
              @"lon": self.longitude };
}

- (void)didResponseDictionary:(NSDictionary *)dictionary
{
    NSLog(@"Response: %@", dictionary);
    _place = dictionary[@"name"];
    _temperature = [dictionary[@"main"][@"temp"] floatValue] / 10;
}

@end
