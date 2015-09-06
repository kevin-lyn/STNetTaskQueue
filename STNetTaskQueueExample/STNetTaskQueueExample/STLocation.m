//
//  STLocation.m
//  STNetTaskQueueExample
//
//  Created by Kevin Lin on 6/9/15.
//  Copyright (c) 2015 Sth4Me. All rights reserved.
//

#import "STLocation.h"

@implementation STLocation

// If you want to ignore some properties when packing the request object, return an array with property names.
- (NSArray *)ignoredProperties
{
    return @[ @"ignoredValue" ];
}

// This is optional, if this is not implemented, underscore "_" will be used as separator when packing parameters. Which means if you use CamelCase naming for your property, it will be converted to lower cases string separated by "_", e.g. "userInfo" will be packed as "user_info" in parameters.
- (NSString *)parameterNameSeparator
{
    return @"_";
}

@end