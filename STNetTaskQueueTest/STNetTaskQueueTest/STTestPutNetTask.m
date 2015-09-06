//
//  STTestPutNetTask.m
//  STNetTaskQueueTest
//
//  Created by Kevin Lin on 19/7/15.
//
//

#import "STTestPutNetTask.h"

@implementation STTestPutNetTask

- (STHTTPNetTaskMethod)method
{
    return STHTTPNetTaskPut;
}

- (NSString *)uri
{
    return [NSString stringWithFormat:@"posts/%d", self.id];
}

- (void)didResponseDictionary:(NSDictionary *)dictionary
{
    _post = dictionary;
}

@end
