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
                ![propertyValue isKindOfClass:[NSString class]] &&
                ![propertyValue isKindOfClass:[NSArray class]]) {
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
    
    static NSRegularExpression *parameterNameRegex;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        parameterNameRegex = [NSRegularExpression regularExpressionWithPattern:@"([a-z])([A-Z])" options:kNilOptions error:NULL];
    });
    
    NSString *parameterName = [parameterNameRegex stringByReplacingMatchesInString:propertyName options:kNilOptions range:NSMakeRange(0, propertyName.length) withTemplate:[NSString stringWithFormat:@"$1%@$2", separator]];
    parameterName = parameterName.lowercaseString;
    return parameterName;
}

@end
