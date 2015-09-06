//
//  STHTTPNetTaskParametersPacker.m
//  Sth4Me
//
//  Created by Kevin Lin on 6/9/15.
//  Copyright (c) 2014 Sth4Me. All rights reserved.
//

#import "STHTTPNetTaskParametersPacker.h"
#import <objc/runtime.h>

@implementation STHTTPNetTaskParametersPacker
{
    STHTTPNetTask *_netTask;
}

- (instancetype)initWithNetTask:(STHTTPNetTask *)netTask
{
    if (self = [super init]) {
        _netTask = netTask;
    }
    return self;
}

- (NSDictionary *)pack
{
    NSMutableDictionary *parameters = [NSMutableDictionary new];
    
    // Pack parameters from request object of net task
    [parameters addEntriesFromDictionary:[self parametersFromRequestObject:_netTask.requestObject]];
    // Pack parameters from net task
    [parameters addEntriesFromDictionary:[self parametersFromRequestObject:_netTask]];
    // Pack additional parameters
    [parameters addEntriesFromDictionary:_netTask.parameters];
    
    return [NSDictionary dictionaryWithDictionary:parameters];
}

- (NSDictionary *)parametersFromRequestObject:(id<STHTTPNetTaskRequestObject>)requestObject
{
    if (!requestObject || ![requestObject isKindOfClass:[NSObject class]]) {
        return nil;
    }
    
    NSSet *ignoredProperties = [NSSet setWithArray:[requestObject ignoredProperties]];
    NSMutableDictionary *parameters = [NSMutableDictionary new];
    
    unsigned int numberOfProperties;
    objc_property_t *properties = class_copyPropertyList([requestObject class], &numberOfProperties);
    for (unsigned int i = 0; i < numberOfProperties; i++) {
        objc_property_t property = properties[i];
        NSString *propertyName = [NSString stringWithUTF8String:property_getName(property)];
        NSArray *propertyAttributes = [[NSString stringWithUTF8String:property_getAttributes(property)] componentsSeparatedByString:@","];
        
        if ([ignoredProperties containsObject:propertyName]) {
            continue;
        }
        
        if (![self shouldPackPropertyWithAttributes:propertyAttributes]) {
            continue;
        }
        
        id propertyValue = [(NSObject *)requestObject valueForKey:propertyName];
        if ([propertyValue conformsToProtocol:@protocol(STHTTPNetTaskRequestObject)]) {
            [parameters addEntriesFromDictionary:[self parametersFromRequestObject:propertyValue]];
        }
        else if ([propertyValue isKindOfClass:[NSDictionary class]]) {
            [parameters addEntriesFromDictionary:propertyValue];
        }
        else {
            if (![propertyValue isKindOfClass:[NSNumber class]] &&
                ![propertyValue isKindOfClass:[NSString class]]) {
                continue;
            }
            
            NSString *separator = STHTTPNetTaskRequestObjectDefaultSeparator;
            if ([requestObject respondsToSelector:@selector(parameterNameSeparator)]) {
                separator = [requestObject parameterNameSeparator];
            }
            NSString *parameterName = [self parameterNameOfProperty:propertyName withSeparator:separator];
            parameters[parameterName] = propertyValue;
        }
    }
    
    free(properties);
    
    return parameters;
}

- (BOOL)shouldPackPropertyWithAttributes:(NSArray *)attributes
{
    // Only pack non-readonly property
    return ![attributes containsObject:@"R"];
}

- (NSString *)parameterNameOfProperty:(NSString *)propertyName withSeparator:(NSString *)separator
{
    if (!separator) {
        return propertyName;
    }
    
    NSMutableString *parameterName = [NSMutableString new];
    NSCharacterSet *uppercase = [NSCharacterSet uppercaseLetterCharacterSet];
    for (NSUInteger i = 0; i < propertyName.length; i++) {
        unichar ch = [propertyName characterAtIndex:i];
        if ([uppercase characterIsMember:ch]) {
            [parameterName appendFormat:@"%@%C", (i == 0 ? @"" : separator), (unichar)tolower((int)ch)];
        }
        else {
            [parameterName appendFormat:@"%C", ch];
        }
    }
    return parameterName;
}

@end
