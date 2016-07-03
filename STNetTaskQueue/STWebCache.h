//
//  STWebCache.h
//  STNetTaskQueue
//
//  Created by Oleg Sorochich on 7/3/16.
//  Copyright © 2016 Sth4Me. All rights reserved.
//

#import "STBaseCoreDataStorage.h"

@interface STWebCache : STBaseCoreDataStorage

/**
 Indicates duration for cached responses. All responses older than duration time will be cleaned.
*/
@property (nonatomic, assign) NSUInteger cacheDaysDuration;

+ (STWebCache *)sharedInstance;

- (void)saveResponseWithData:(NSData *)data forURL:(NSString*)url;
- (NSData *)responseDataForUrl:(NSString *)url;

- (void)clean;

@end
