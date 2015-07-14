//
//  STNetTaskQueueTest.m
//  STNetTaskQueueTest
//
//  Created by Kevin Lin on 14/7/15.
//
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "STHTTPNetTaskQueueHandler.h"
#import "STTestRetryNetTask.h"

@interface STNetTaskQueueTest : XCTestCase <STNetTaskDelegate>

@end

@implementation STNetTaskQueueTest
{
    XCTestExpectation *_expectation;
}

- (void)setUp
{
    [super setUp];
    
    STHTTPNetTaskQueueHandler *httpHandler = [[STHTTPNetTaskQueueHandler alloc] initWithBaseURL:[NSURL URLWithString:@"https://www.google.com"]];
    [STNetTaskQueue sharedQueue].handler = httpHandler;
}

- (void)tearDown
{
    [super tearDown];
}

- (void)testRetryNetTask
{
    _expectation = [self expectationWithDescription:@"testRetryNetTask"];
    
    STTestRetryNetTask *testRetryTask = [STTestRetryNetTask new];
    [[STNetTaskQueue sharedQueue] addTaskDelegate:self uri:testRetryTask.uri];
    [[STNetTaskQueue sharedQueue] addTask:testRetryTask];
    
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)netTaskDidEnd:(STNetTask *)task
{
    if ([task isKindOfClass:[STTestRetryNetTask class]]) {
        [_expectation fulfill];
        if (task.retryCount != task.maxRetryCount) {
            XCTFail(@"testRetryNetTask failed");
        }
    }
}

@end
