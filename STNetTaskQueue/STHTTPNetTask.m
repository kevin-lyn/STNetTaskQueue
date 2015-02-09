//
//  STHTTPNetTask.m
//  Sth4Me
//
//  Created by Kevin Lin on 29/11/14.
//  Copyright (c) 2014 Sth4Me. All rights reserved.
//

#import "STHTTPNetTask.h"

@implementation STHTTPNetTask

- (STHTTPNetTaskMethod)method
{
    return STHTTPNetTaskGet;
}

- (NSDictionary *)datas
{
    return nil;
}

- (NSDictionary *)parameters
{
    return nil;
}

- (void)didResponse:(NSObject *)response
{
    [self didResponseJSON:(NSDictionary *)response];
}

- (void)didResponseJSON:(NSDictionary *)response
{
    
}

@end
