//
//  STNetTaskQueueLog.m
//  STNetTaskQueue
//
//  Created by Kevin Lin on 6/9/15.
//  Copyright (c) 2014 Sth4Me. All rights reserved.
//

#import "STNetTaskQueueLog.h"

@implementation STNetTaskQueueLog

+ (void)log:(NSString *)content, ...
{
    if (!content) {
        return;
    }
    va_list args;
    va_start(args, content);
    NSLogv([NSString stringWithFormat:@"[STNetTaskQueue] %@", content], args);
    va_end(args);
}

@end
