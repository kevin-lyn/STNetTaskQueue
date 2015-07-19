//
//  STTestDownloadNetTask.m
//  STNetTaskQueueTest
//
//  Created by Kevin Lin on 19/7/15.
//
//

#import "STTestDownloadNetTask.h"

@implementation STTestDownloadNetTask

- (STHTTPNetTaskMethod)method
{
    return STHTTPNetTaskGet;
}

- (STHTTPNetTaskResponseType)responseType
{
    return STHTTPNetTaskResponseRawData;
}

- (NSString *)uri
{
    return @"images/modules/logos_page/Octocat.png";
}

- (void)didResponseData:(NSData *)data
{
    _image = [UIImage imageWithData:data];
}

@end
