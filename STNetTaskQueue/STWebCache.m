//
//  STWebCache.m
//  STNetTaskQueue
//
//  Created by Oleg Sorochich on 7/3/16.
//  Copyright © 2016 Sth4Me. All rights reserved.
//

#import "STWebCache.h"
#import "STWebURLResponse.h"

static NSString *const kStorageName = @"WebCache";
static NSString *const kCacheDaysDurationKey = @"kDurationKey";

@implementation STWebCache

@dynamic cacheDaysDuration;

+ (STWebCache *)sharedInstance {
    
    static STWebCache *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[STWebCache alloc] initWithStoreName:kStorageName];
        [sharedInstance clean];
    });
    return sharedInstance;
}

- (void)setCacheDaysDuration:(NSUInteger)cacheDaysDuration {
    [[NSUserDefaults standardUserDefaults] setInteger:cacheDaysDuration
                                               forKey:kCacheDaysDurationKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSUInteger)cacheDaysDuration {
    NSUInteger duration = [[NSUserDefaults standardUserDefaults] integerForKey:kCacheDaysDurationKey];
    if (duration < 1) {
        // A duration for the cached responsed is equal to 3 by default
        self.cacheDaysDuration = 3;
        duration = 3;
    }
    
    return duration;
}

- (void)saveResponseWithData:(NSData *)data forURL:(NSString *)url {
    [self executeBlockInPrivate:^() {
        STWebURLResponse *item = [self recordsWithName:NSStringFromClass([STWebURLResponse class])
                                             predicate:[NSPredicate predicateWithFormat:@"url == [c]%@", url]].lastObject;
        if(item == nil) {
            item = [self insertObjectWithClass:[STWebURLResponse class]];
            item.url = url;
        }
        
        item.data = data;
        item.lastReadDate = [NSDate date];
       
        [self save];
        
        return (id)nil;
    }];
}

- (NSData *)responseDataForUrl:(NSString *)url {
    return [self executeBlockInPrivate:^() {
        STWebURLResponse *response = [self recordsWithName:NSStringFromClass([STWebURLResponse class])
                                                predicate:[NSPredicate predicateWithFormat:@"url == [c]%@", url]].lastObject;
        NSData *data = response.data;
        return data;
    }];
}

#pragma mark - Private interface

- (void)clean {
    NSTimeInterval const kCleanInterval = 60 * 60 * 24 * self.cacheDaysDuration;
  
    [self executeBlockInPrivate:^() {
        NSDate *oldDate = [NSDate dateWithTimeIntervalSinceNow:-kCleanInterval];
        NSArray *records = [self recordsWithName:NSStringFromClass([STWebURLResponse class])
                                       predicate:[NSPredicate predicateWithFormat:@"lastReadDate < %@", oldDate]];
        NSNumber *count = @(records.count);
        
        [self deleteRecords:records];
        [self save];
        return (id)count;
    }];
}

@end
