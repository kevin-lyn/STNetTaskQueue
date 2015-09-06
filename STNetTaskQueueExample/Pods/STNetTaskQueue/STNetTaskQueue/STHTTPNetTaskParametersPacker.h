//
//  STHTTPNetTaskParametersPacker.h
//  Sth4Me
//
//  Created by Kevin Lin on 6/9/15.
//  Copyright (c) 2014 Sth4Me. All rights reserved.
//

#import "STHTTPNetTask.h"

@interface STHTTPNetTaskParametersPacker : NSObject

- (instancetype)initWithNetTask:(STHTTPNetTask *)netTask;
- (NSDictionary *)pack;

@end
