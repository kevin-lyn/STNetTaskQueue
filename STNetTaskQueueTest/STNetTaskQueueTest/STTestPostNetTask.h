//
//  STTestPostNetTask.h
//  STNetTaskQueueTest
//
//  Created by Kevin Lin on 19/7/15.
//
//

#import <STNetTaskQueue/STHTTPNetTask.h>

@interface STTestPostNetTask : STHTTPNetTask

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *body;
@property (nonatomic, strong) NSDate *date;
@property (nonatomic, assign) int userId;
@property (nonatomic, strong) NSString<STIgnore> *ignored; // This property is ignored when packing the request.
@property (nonatomic, strong, readonly) NSDictionary *post;

@end
