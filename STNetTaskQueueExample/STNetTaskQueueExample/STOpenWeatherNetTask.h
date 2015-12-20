//
//  STOpenWeatherNetTask.h
//  STNetTaskQueueExample
//
//  Created by Kevin Lin on 9/2/15.
//  Copyright (c) 2015 Sth4Me. All rights reserved.
//

#import <STNetTaskQueue/STNetTaskQueue.h>
#import "STLocation.h"

@interface STOpenWeatherNetTask : STHTTPNetTask

@property (nonatomic, strong) STLocation *location;
@property (nonatomic, strong) NSString *userInfo;
@property (nonatomic, strong, readonly) NSString *place;
@property (nonatomic, assign, readonly) float temperature;

@end
