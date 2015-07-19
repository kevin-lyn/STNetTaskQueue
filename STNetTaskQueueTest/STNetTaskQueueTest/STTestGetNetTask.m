//
//  STTestGetNetTask.m
//  STNetTaskQueueTest
//
//  Created by Kevin Lin on 19/7/15.
//
//

#import "STTestGetNetTask.h"

@implementation STTestGetNetTask

- (STHTTPNetTaskMethod)method
{
    return STHTTPNetTaskGet;
}

- (NSString *)uri
{
    return [NSString stringWithFormat:@"posts/%d", self.id];
}

- (void)didResponseJSON:(NSDictionary *)json
{
    _post = json;
}

@end
