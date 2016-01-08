//
//  STTestPackerNetTask.m
//  STNetTaskQueueTest
//
//  Created by Kevin Lin on 8/1/16.
//
//

#import "STTestPackerNetTask.h"

@implementation STTestPackerNetTask

- (STHTTPNetTaskMethod)method
{
    return STHTTPNetTaskPost;
}

- (STHTTPNetTaskRequestType)requestType
{
    return STHTTPNetTaskRequestJSON;
}

- (NSString *)uri
{
    return @"posts";
}

- (id)transformValue:(id)value
{
    if ([value isKindOfClass:[NSArray class]]) {
        return [value componentsJoinedByString:@","];
    }
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
