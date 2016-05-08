//
//  STHTTPNetTaskParametersPacker.h
//  STNetTaskQueue
//
//  Created by Kevin Lin on 6/9/15.
//  Copyright (c) 2014 Sth4Me. All rights reserved.
//

#import <Foundation/Foundation.h>

@class STHTTPNetTask;

@interface STHTTPNetTaskParametersPacker : NSObject

- (instancetype)initWithNetTask:(STHTTPNetTask *)netTask;
- (NSDictionary<NSString *, id> *)pack;

@end
