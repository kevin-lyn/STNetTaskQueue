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

- (NSDictionary *)parameters
{
    NSLog(@"Pack request parameters");
    return @{ @"lat": self.latitude,
              @"lon": self.longitude };
}

- (void)didResponseJSON:(NSDictionary *)response
{
    NSLog(@"Response: %@", response);
    _place = response[@"name"];
    _temperature = [response[@"main"][@"temp"] floatValue] / 10;
}

@end
