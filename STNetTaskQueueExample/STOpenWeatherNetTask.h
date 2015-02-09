//
//  STOpenWeatherNetTask.h
//  STNetTaskQueueExample
//
//  Created by Kevin Lin on 9/2/15.
//  Copyright (c) 2015 Sth4Me. All rights reserved.
//

#import "STHTTPNetTask.h"

@interface STOpenWeatherNetTask : STHTTPNetTask

@property (nonatomic, strong) NSString *latitude;
@property (nonatomic, strong) NSString *longitude;
@property (nonatomic, strong, readonly) NSString *place;
@property (nonatomic, assign, readonly) float temperature;

@end
