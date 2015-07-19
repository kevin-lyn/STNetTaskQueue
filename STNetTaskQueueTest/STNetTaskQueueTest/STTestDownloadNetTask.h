//
//  STTestDownloadNetTask.h
//  STNetTaskQueueTest
//
//  Created by Kevin Lin on 19/7/15.
//
//

#import "STHTTPNetTask.h"
#import <UIKit/UIKit.h>

@interface STTestDownloadNetTask : STHTTPNetTask

@property (nonatomic, strong, readonly) UIImage *image;

@end
