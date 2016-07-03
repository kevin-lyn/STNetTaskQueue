//
//  STNetTask+Management.h
//  STNetTaskQueue
//
//  Created by Oleg Sorochich on 7/3/16.
//  Copyright © 2016 Sth4Me. All rights reserved.
//

#import "STNetTask.h"

@interface STNetTask (Management)

/**
 This method is used to start the task
 */
- (void)start;

/**
 This method is used to cancel the task
 */
- (void)cancel;

@end
