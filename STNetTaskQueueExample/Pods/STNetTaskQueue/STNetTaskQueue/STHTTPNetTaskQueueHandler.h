//
//  STHTTPNetTaskQueueHandler.h
//  Sth4Me
//
//  Created by Kevin Lin on 29/11/14.
//  Copyright (c) 2014 Sth4Me. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STNetTaskQueue.h"

@interface STHTTPNetTaskQueueHandler : NSObject<STNetTaskQueueHandler>

- (instancetype)initWithBaseURL:(NSURL *)baseURL;

@end
