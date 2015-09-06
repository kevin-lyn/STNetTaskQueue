# STNetTaskQueue
STNetTaskQueue is a networking queue library for iOS and OS X. It's abstract and can be implemented in different protocols.

STNetTaskQueue avoid you from directly dealing with "url", "request packing" and "response parsing". All networking tasks are described and processed by subclassing STNetTask, which provides you a clean code style in UI layer when handling networking.

## Glance
### Tired of this?
```objc
[network GET:@"data/2.5/weather" parameters:@{ @"lat": location.lat,
                                               @"lon": location.lon,
                                               @"user_info": location.userInfo,
                                               @"other_parameter": @"value" }];
```
### What about this?
```objc
STOpenWeatherNetTask *openWeatherTask = [STOpenWeatherNetTask new];
openWeatherTask.requestObject = location;
[[STNetTaskQueue sharedQueue] addTask:openWeatherTask];
```
STNetTaskQueue will get all non-readonly properties from "location" and pack them as parameters for you. See [Get Started](https://github.com/kevin0571/STNetTaskQueue#get-started) for more details.

## Features
- Auto packing parameters for HTTP net task.
- Max concurrent tasks count in each STNetTaskQueue.
- Max retry count for each STNetTask.
- Net task is cancelable after added to STNetTaskQueue.
- Multiple delegates for same net task.
- Works with ReactiveCocoa, subscribeNext for net task result.

## STHTTPNetTaskQueueHandler

STHTTPNetTaskQueueHandler is a HTTP based implementation of STNetTaskQueueHandler. It provides different ways to pack request and parse response, e.g. STHTTPNetTaskRequestJSON is for JSON format request body, STHTTPNetTaskResponseJSON is for JSON format response data and STHTTPNetTaskRequestFormData is for form data format request body which is mostly used for uploading file.

## STNetTask

STNetTask is abstract, it provides basic properties and callbacks for subclassing.

## STNetTaskDelegate

STNetTaskDelegate is the delegate protocol for observing result of STNetTask, mostly it is used in view controller. 

## STNetTaskChain

STNetTaskChain is a chain which processes an array of STNetTask serially. A net task chain is considered as successful only if all net tasks in the chain are end without error.

## Get Started

### Podfile

```ruby
platform :ios, '7.0'
pod 'STNetTaskQueue'
```

### Use STNetTaskQueue in your project
#### Step 1: Setup STNetTaskQueue after your app launch
```objc
NSURL *baseUrl = [NSURL URLWithString:@"http://api.openweathermap.org"];
STHTTPNetTaskQueueHandler *httpHandler = [[STHTTPNetTaskQueueHandler alloc] initWithBaseURL:baseUrl];
[STNetTaskQueue sharedQueue].handler = httpHandler;
```

#### Step 2: Create your net task
```objc
@interface STOpenWeatherNetTask : STHTTPNetTask

@property (nonatomic, strong) NSString *lat;
@property (nonatomic, strong) NSString *lon;
@property (nonatomic, strong, readonly) NSString *place;
@property (nonatomic, assign, readonly) float temperature;

@end
```

```objc
@implementation STOpenWeatherNetTask

- (STHTTPNetTaskMethod)method
{
    return STHTTPNetTaskGet;
}

- (NSString *)uri
{
    return @"data/2.5/weather";
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

- (void)didResponseDictionary:(NSDictionary *)dictionary
{
    _place = dictionary[@"name"];
    _temperature = [dictionary[@"main"][@"temp"] floatValue] / 10;
}

@end
```

#### Step 3: Send net task and delegate for the result
```objc
- (void)sendOpenWeatherTask
{
    if (_openWeatherTask.pending) {
        return;
    }
    
    STLocation *location = [STLocation new];
    location.lat = @"this value is going to be overwritten";
    location.lon = @"this value is going to be overwritten";
    location.userInfo = @"user info";
    location.ignoredValue = 1;
    
    _openWeatherTask = [STOpenWeatherNetTask new];
    _openWeatherTask.requestObject = location;
    _openWeatherTask.lat = @"1.306038";
    _openWeatherTask.lon = @"103.772962";
    // STHTTPNetTask will pack all non-readonly properties from "requestObject", and then all non-readonly properties from net task, finally parameters returned by net task. Previous parameters might be overwritten if there are duplicated parameter names. Which means the final packed parameters would be: 
    // @{ @"lat": @"1.306038", 
    //    @"lon": @"103.772962",
    //    @"user_info": @"user info",
    //    @"other_parameter": @"value" }
    
    // Task delegate will be a weak reference, so there is no need to remove it manually.
    // It's appropriate to add task delegate here because duplicated task delegates will be ignored by STNetTaskQueue.
    [[STNetTaskQueue sharedQueue] addTaskDelegate:self uri:_openWeatherTask.uri];
    [[STNetTaskQueue sharedQueue] addTask:_openWeatherTask];
}
```

#### Create a request object
Conform STHTTPNetTaskRequestObject protocol
```objc
@interface STLocation : NSObject<STHTTPNetTaskRequestObject>

@property (nonatomic, strong) NSString *lat;
@property (nonatomic, strong) NSString *lon;
@property (nonatomic, strong) NSString *userInfo;
@property (nonatomic, assign) int ignoredValue;
@property (nonatomic, assign, readonly) BOOL readOnlyProperty; // Read only property will not be packed into parameters

@end
```

```objc
@implementation STLocation

// If you want to ignore some properties when packing the request object, return an array with property names.
- (NSArray *)ignoredProperties
{
    return @[ @"ignoredValue" ];
}

// This is optional, if this is not implemented, underscore "_" will be used as separator when packing parameters. Which means if you use CamelCase naming for your property, it will be converted to lower cases string separated by "_", e.g. "userInfo" will be packed as "user_info" in parameters.
- (NSString *)parameterNameSeparator
{
    return @"_"
}

@end
```

#### Work with ReactiveCocoa for getting net task result

```objc
[STNetTaskObserve(_openWeatherTask) subscribeNext:^(STOpenWeatherNetTask *task) {
    if (task.error) { // Would be network issue
        _resultLabel.text = @"Network Unavailable";
        _goBtn.hidden = YES;
        return;
    }
    _resultLabel.text = [NSString stringWithFormat:@"%@\n%.1f°C", task.place, task.temperature];
    _goBtn.hidden = YES;
}];
```

#### Or use STNetTaskDelegate

```objc
- (void)netTaskDidEnd:(STNetTask *)task
{
    // It's necessary to detect if _openWeatherTask != task,
    // if you have mutiple viewControllers deleagating the same uri.
    if (_openWeatherTask != task) {
        return;
    }

    if (task.error) { // Would be network issue
        _resultLabel.text = @"Network Unavailable";
        _goBtn.hidden = YES;
        return;
    }

    _resultLabel.text = [NSString stringWithFormat:@"%@\n%.1f°C", _openWeatherTask.place, _openWeatherTask.temperature];
    _goBtn.hidden = YES;
}
```
For more details, download the example project or check out unit tests for usage references.

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

## What's Next

- More unit tests for STHTTPNetTaskQueueHandler.
- Detailed documentation for STNetTaskQueue, STNetTask, STNetTaskChain.