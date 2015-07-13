//
//  STHTTPNetTask.h
//  Sth4Me
//
//  Created by Kevin Lin on 29/11/14.
//  Copyright (c) 2014 Sth4Me. All rights reserved.
//

#import "STNetTask.h"

typedef enum {
    STHTTPNetTaskGet,
    STHTTPNetTaskPost,
    STHTTPNetTaskPut,
    STHTTPNetTaskDelete,
    STHTTPNetTaskHead,
    STHTTPNetTaskPatch
} STHTTPNetTaskMethod;

@interface STHTTPNetTask : STNetTask

- (STHTTPNetTaskMethod)method;
- (NSDictionary *)parameters;
- (NSDictionary *)datas;
- (void)didResponseJSON:(NSDictionary *)response;

@end
