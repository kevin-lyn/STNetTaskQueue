//
//  STNetTask+Management.m
//  STNetTaskQueue
//
//  Created by Oleg Sorochich on 7/3/16.
//  Copyright © 2016 Sth4Me. All rights reserved.
//

#import "STNetTask+Management.h"
#import "STNetTaskQueue.h"


@implementation STNetTask (Management)

- (void)start {
    [[STNetTaskQueue sharedQueue] addTask:self];
}


- (void)cancel {
    [[STNetTaskQueue sharedQueue] cancelTask:self];
}

@end
