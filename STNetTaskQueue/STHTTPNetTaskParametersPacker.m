//
//  STHTTPNetTaskParametersPacker.m
//  STNetTaskQueue
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
    if (ignoredProperties.count == 1 && [ignoredProperties.anyObject isEqualToString:@"*"]) {
        return nil;
    }
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
        
        NSString *separator = [self separatorFromRequestObject:requestObject];
        NSString *parameterName = [self parameterNameFromName:propertyName withSeparator:separator];
        id parameterValue = [self parameterValueFromValue:[(NSObject *)requestObject valueForKey:propertyName] inRequestObject:requestObject];
        if (parameterName && parameterValue) {
            parameters[parameterName] = parameterValue;
        }
    }
    
    free(properties);
    
    return parameters;
}

- (NSDictionary *)parametersFromDictionary:(NSDictionary *)dictionary inRequestObject:(id<STHTTPNetTaskRequestObject>)requestObject
{
    NSString *separator = [self separatorFromRequestObject:requestObject];
    NSMutableDictionary *parameters = [NSMutableDictionary new];
    for (NSString *key in dictionary) {
        NSString *parameterName = [self parameterNameFromName:key withSeparator:separator];
        id parameterValue = [self parameterValueFromValue:dictionary[key] inRequestObject:requestObject];
        if (parameterName && parameterValue) {
            parameters[parameterName] = parameterValue;
        }
    }
    return parameters;
}

- (id)parameterValueFromValue:(id)value inRequestObject:(id<STHTTPNetTaskRequestObject>)requestObject
{
    if ([requestObject respondsToSelector:@selector(transformValue:)]) {
        id transformedValue = [requestObject transformValue:value];
        if (transformedValue != value) {
            return transformedValue;
        }
    }
    if ([value conformsToProtocol:@protocol(STHTTPNetTaskRequestObject)]) {
        return [self parametersFromRequestObject:value];
    }
    else if ([value isKindOfClass:[NSDictionary class]]) {
        return [self parametersFromDictionary:value inRequestObject:requestObject];
    }
    else if ([value isKindOfClass:[NSNumber class]] ||
             [value isKindOfClass:[NSString class]] ||
             [value isKindOfClass:[NSArray class]]) {
        return value;
    }
    return nil;
}

- (NSString *)parameterNameFromName:(NSString *)name withSeparator:(NSString *)separator
{
    if (!separator) {
        return name;
    }
    
    NSMutableString *parameterName = [NSMutableString new];
    const char *chars = name.UTF8String;
    for (NSUInteger i = 0; i < name.length; i++) {
        BOOL hasPrevious = i != 0;
        BOOL hasNext = i + 1 < name.length;
        BOOL prependUnderscore = NO;
        char ch = chars[i];
        if (isupper(ch)) {
            if (hasPrevious) {
                if (!isupper(chars[i - 1])) {
                    prependUnderscore = YES;
                }
            }
            if(hasNext && !prependUnderscore) {
                if (!isupper(chars[i + 1])) {
                    prependUnderscore = YES;
                }
            }
            ch = tolower(ch);
        }
        if (prependUnderscore) {
            [parameterName appendFormat:@"_%c", ch];
        }
        else {
            [parameterName appendFormat:@"%c", ch];
        }
    }
    
    return [NSString stringWithString:parameterName];
}

- (NSString *)separatorFromRequestObject:(id<STHTTPNetTaskRequestObject>)requestObject
{
    NSString *separator = STHTTPNetTaskRequestObjectDefaultSeparator;
    if ([requestObject respondsToSelector:@selector(parameterNameSeparator)]) {
        separator = [requestObject parameterNameSeparator];
    }
    return separator;
}

- (BOOL)shouldPackPropertyWithAttributes:(NSArray *)attributes
{
    // Only pack non-readonly property and property which is not ignored.
    return ![attributes containsObject:@"R"] && [attributes[0] rangeOfString:NSStringFromProtocol(@protocol(STIgnore))].location == NSNotFound;
}

@end
