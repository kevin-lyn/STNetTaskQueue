//
//  STLocation.h
//  STNetTaskQueueExample
//
//  Created by Kevin Lin on 6/9/15.
//  Copyright (c) 2015 Sth4Me. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <STNetTaskQueue/STNetTaskQueue.h>

@interface STLocation : NSObject<STHTTPNetTaskRequestObject>

@property (nonatomic, strong) NSString *lat;
@property (nonatomic, strong) NSString *lon;
@property (nonatomic, assign) int ignoredValue;
@property (nonatomic, assign, readonly) BOOL readOnlyProperty; // Read only property will not be packed into parameters

@end