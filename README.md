# STNetTaskQueue
STNetTaskQueue is a networking queue library for iOS and OS X. It's abstract and can be implemented in different protocols.

STNetTaskQueue avoid you from directly dealing with "url", "request packing" and "response parsing". All networking tasks are described and processed by subclassing STNetTask, which provides you a clean code style in UI layer when handling networking.

## Features
- Max concurrent tasks count in each STNetTaskQueue.
- Max retry count for each STNetTask.
- Net task is cancelable after added to STNetTaskQueue.
- Multiple delegates for same net task.

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

@property (nonatomic, strong) NSString *latitude;
@property (nonatomic, strong) NSString *longitude;
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

- (NSUInteger)maxRetryCount
{
    return 3; // Retry after error occurs
}

- (NSDictionary *)parameters
{
    return @{ @"lat": self.latitude,
              @"lon": self.longitude };
}

- (void)didResponseJSON:(NSDictionary *)response
{
    _place = response[@"name"];
    _temperature = [response[@"main"][@"temp"] floatValue] / 10;
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
    _openWeatherTask = [STOpenWeatherNetTask new];
    _openWeatherTask.latitude = @"1.306038";
    _openWeatherTask.longitude = @"103.772962";
    // Task delegate will be a weak reference, so there is no need to remove it manually.
    // It's appropriate to add task delegate here because duplicated task delegates will be ignored by STNetTaskQueue.
    [[STNetTaskQueue sharedQueue] addTaskDelegate:self uri:_openWeatherTask.uri];
    [[STNetTaskQueue sharedQueue] addTask:_openWeatherTask];
}
```

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

## What's Next

- More unit tests for STHTTPNetTaskQueueHandler.
- Detailed documentation for STNetTaskQueue, STNetTask, STNetTaskChain.
- Support other protocol based STNetTaskQueueHandler, e.g. STNetTaskQueueHandler for ProtocolBuffers.