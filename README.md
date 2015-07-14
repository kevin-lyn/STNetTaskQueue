# STNetTaskQueue
Queue for managing network requests

STNetTaskQueue may be your choice if you want to handle each network request stuff in separated STNetTask instead of having all the network requests logics in a "Manager" class.

**STHTTPNetTaskQueueHandler** is included, which is for HTTP based network reqeust. If you are looking for a socket or other protocol based handler, currently you should write your own net task queue handler and conform to **STNetTaskQueueHandler** protocol. **STHTTPNetTaskQeueuHandler** depends on [AFNetworking](https://github.com/AFNetworking/AFNetworking), which is included in example project.

## Features
- Retry net task with specified max retry count.
- Delegate for net task result according to "uri" of net task.

## Sequence Chart
![STNetTaskQueue Sequence Chart](https://cloud.githubusercontent.com/assets/1491282/7292210/6d761f6a-e9cc-11e4-9620-0075082dcc8e.png)

### Installation with CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Objective-C, which automates and simplifies the process of using 3rd-party libraries like AFNetworking in your projects. See the ["Getting Started" guide for more information](https://github.com/AFNetworking/AFNetworking/wiki/Getting-Started-with-AFNetworking).

#### Podfile

```ruby
platform :ios, '7.0'
pod 'STNetTaskQueue', '~> 0.0.1'
```

## Get Started
#### Step 1: Setup STNetTaskQueue after your app launch
```objc
NSURL *baseUrl = [NSURL URLWithString:@"http://api.openweathermap.org"];
STHTTPNetTaskQueueHandler *httpHandler = [[STHTTPNetTaskQueueHandler alloc] initWithBaseURL:baseUrl];
[STNetTaskQueue sharedQueue].handler = httpHandler;
```

#### Step 2: Write your net task for each reqeust
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
    return 3;
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

#### Step 3: Go and get your response
```objc
if (_openWeatherTask.pending) {
    return;
}
_openWeatherTask = [STOpenWeatherNetTask new];
_openWeatherTask.latitude = @"1.306038";
_openWeatherTask.longitude = @"103.772962";
// Task delegate will be a weak reference, so no need to remove it manually.
// Duplicated task delegates will be ignored by STNetTaskQueue, so it's fine to invoke addTaskDelegate here.
[[STNetTaskQueue sharedQueue] addTaskDelegate:self uri:_openWeatherTask.uri];
[[STNetTaskQueue sharedQueue] addTask:_openWeatherTask];
```

```objc
- (void)netTaskDidEnd:(STNetTask *)task
{
    // It's necessary to detect if _openWeatherTask != task and return,
    // if you have mutiple instance/viewController deleagating the same uri.
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

You can see more details in example project. The example is tested with iOS SDK 8.1, XCode 6.1.1 and iPhone 6 simulator.