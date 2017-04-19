//
//  STWebURLResponse.h
//  STNetTaskQueue
//
//  Created by Oleg Sorochich on 7/3/16.
//  Copyright © 2016 Sth4Me. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface STWebURLResponse : NSManagedObject

@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) NSData * data;
@property (nonatomic, retain) NSDate * lastReadDate;

@end
