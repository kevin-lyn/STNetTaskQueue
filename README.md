# STNetTaskQueue ![CI Status](https://img.shields.io/travis/kevin0571/STNetTaskQueue.svg?style=flat) ![Version](http://img.shields.io/cocoapods/v/STNetTaskQueue.svg?style=flag) ![License](https://img.shields.io/cocoapods/l/STNetTaskQueue.svg?style=flag)
STNetTaskQueue is a networking queue library for iOS and OS X. It's abstract and can be implemented in different protocols.

STNetTaskQueue avoid you from directly dealing with "url", "request packing" and "response parsing". All networking tasks are described and processed by subclassing STNetTask, which provides you a clean code style in UI layer when handling networking.

## Features
- Auto packing parameters for HTTP net task.
- Max concurrent tasks count in each STNetTaskQueue.
- Max retry count for each STNetTask.
- Net task is cancelable after added to STNetTaskQueue.
- Multiple delegates for same net task.
- Works with ReactiveCocoa, subscribeCompleted for net task result.

## STHTTPNetTaskQueueHandler

STHTTPNetTaskQueueHandler is a HTTP based implementation of STNetTaskQueueHandler. It provides different ways to pack request and parse response, e.g. STHTTPNetTaskRequestJSON is for JSON format request body, STHTTPNetTaskResponseJSON is for JSON format response data and STHTTPNetTaskRequestFormData is for form data format request body which is mostly used for uploading file.

## STNetTask

STNetTask is abstract, it provides basic properties and callbacks for subclassing.

## STNetTaskDelegate

STNetTaskDelegate is the delegate protocol for observing result of STNetTask, mostly it is used in view controller. 

## ~~STNetTaskChain~~ (Deprecated. Use STNetTaskGroup instead)

~~STNetTaskChain is a chain which processes an array of STNetTask serially. A net task chain is considered as successful only if all net tasks in the chain are end without error.~~

## STNetTaskGroup

A net task group for executing net tasks serially or concurrently.

## Get Started

### Podfile

```ruby
platform :ios, '7.0'
pod 'STNetTaskQueue'
```

### Carthage
```ruby
github "kevin0571/STNetTaskQueue"
```

### Use STNetTaskQueue in your project
#### Step 1: Setup STNetTaskQueue after your app launch
```objc
NSURL *baseUrl = [NSURL URLWithString:@"http://jsonplaceholder.typicode.com"];
STHTTPNetTaskQueueHandler *httpHandler = [[STHTTPNetTaskQueueHandler alloc] initWithBaseURL:baseUrl];
[STNetTaskQueue sharedQueue].handler = httpHandler;
```

#### Step 2: Create your net task
```objc
@interface STTestPostNetTask : STHTTPNetTask

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *body;
@property (nonatomic, strong) NSDate *date;
@property (nonatomic, assign) int userId;
@property (nonatomic, strong) NSString<STIgnore> *ignored; // This property is ignored when packing the request.
@property (nonatomic, strong, readonly) NSDictionary *post;

@end
```

```objc
@implementation STTestPostNetTask

- (STHTTPNetTaskMethod)method
{
    return STHTTPNetTaskPost;
}

- (NSString *)uri
{
    return @"posts";
}

// Optional. Retry 3 times after error occurs.
- (NSUInteger)maxRetryCount
{
    return 3;
}

// Optional. Retry for all types of errors
- (BOOL)shouldRetryForError:(NSError *)error
{
    return YES;
}

// Optional. Retry after 5 seconds.
- (NSTimeInterval)retryInterval
{
    return 5;
}

// Optional. Custom headers.
- (NSDictionary *)headers
{
    return @{ @"custom_header": @"value" };
}

// Optional. Add parameters which are not inclued in requestObject and net task properties.
- (NSDictionary *)parameters
{
    return @{ @"other_parameter": @"value" };
}

// Optional. Transform value to a format you want.
- (id)transformValue:(id)value
{
    if ([value isKindOfClass:[NSDate class]]) {
        return @([value timeIntervalSince1970]);
    }
    return value;
}

- (void)didResponseDictionary:(NSDictionary *)dictionary
{
    _post = dictionary;
}

@end
```

#### Step 3: Send net task and delegate for the result
```objc
STTestPostNetTask *testPostTask = [STTestPostNetTask new];
testPostTask.title = @"Test Post Net Task Title";
testPostTask.body = @"Test Post Net Task Body";
testPostTask.userId = 1;
testPostTask.date = [NSDate new];
testPostTask.ignored = @"test";
[[STNetTaskQueue sharedQueue] addTaskDelegate:self uri:testPostTask.uri];
[[STNetTaskQueue sharedQueue] addTask:testPostTask];

// The net task will be sent as described below.
/*
    URI: posts
    Method: POST
    Request Type: Key-Value String
    Response Type: JSON
    Custom Headers:
    {
        "custom_header" = value;
    }
    Parameters:
    {
        body = "Test Post Net Task Body";
        date = "1452239110.829915";
        "other_parameter" = value;
        title = "Test Post Net Task Title";
        "user_id" = 1;
    }
 */
```

#### Use subscription block
```objc
[testPostTask subscribeState:STNetTaskStateFinished usingBlock:^{
    if (testPostTask.error) {
        // Handle error cases
        return;
    }
    // Access result from net task
}];
```

#### Use STNetTaskDelegate

```objc
- (void)netTaskDidEnd:(STNetTask *)task
{
    if (task.error) {
        // Handle error cases
        return;
    }
    // Access result from net task
}
```

#### Work with ReactiveCocoa for getting net task result

```objc
[STNetTaskObserve(testPostTask) subscribeCompleted:^(
    if (testPostTask.error) {
        // Handle error cases
        return;
    }
    // Access result from net task
}];
```

For more details, check out unit tests.

### Set max concurrent tasks count of STNetTaskQueue
Sometimes we need to set the concurrent image download tasks to avoid too much data coming at the same time.

```objc
STNetTaskQueue *downloadQueue = [STNetTaskQueue new];
downloadQueue.handler = [[STHTTPNetTaskQueueHandler alloc] initWithBaseURL:[NSURL URLWithString:@"http://example.com"]];
downloadQueue.maxConcurrentTasksCount = 2;
/*
[downloadQueue addTask:task1];
[downloadQueue addTask:task2];
[downloadQueue addTask:task3]; // task3 will be sent after task1 or task2 is finished.
*/
```

### Use STNetTaskGroup to execute multiple net tasks
STNetTaskGroup supports two modes: STNetTaskGroupModeSerial and STNetTaskGroupConcurrent.
STNetTaskGroupModeSerial will execute a net task after the previous net task is finished.
STNetTaskGroupModeConcurrent will execute all net tasks concurrently.
```objc
STTestGetNetTask *task1 = [STTestGetNetTask new];
task1.id = 1;
    
STTestGetNetTask *task2 = [STTestGetNetTask new];
task2.id = 2;
    
STNetTaskGroup *group = [[STNetTaskGroup alloc] initWithTasks:@[ task1, task2 ] mode:STNetTaskGroupModeSerial];
[group subscribeState:STNetTaskGroupStateFinished usingBlock:^(STNetTaskGroup *group, NSError *error) {
    if (error) {
        // One of the net task is failed.
        return;
    }
    // All net tasks are finished without error.
}];
[group start];
```

Or a handy way:
```objc
STTestGetNetTask *task1 = [STTestGetNetTask new];
task1.id = 1;
    
STTestGetNetTask *task2 = [STTestGetNetTask new];
task2.id = 2;

[[@[ task1, task2 ] subscribeState:STNetTaskGroupStateFinished usingBlock:^(STNetTaskGroup *group, NSError *error) {
    if (error) {
        // One of the net task is failed.
        return;
    }
    // All net tasks are finished without error.
}] start];
```