# STNetTaskQueue
Queue for managing network request

If you don't want to put all the network reqeust logics in a "Manager" class, **STNetTaskQueue** may be your choice. You can now handle each network reqeust with separated **STNetTask** instead.

**STHTTPNetTaskQueueHandler** is included, which is for HTTP based network reqeust. If you are looking for a socket or other protocol based handler, currently you should write your own net task queue handler and conform to **STNetTaskQueueHandler** protocol. **STHTTPNetTaskQeueuHandler** depends on [AFNetworking](https://github.com/AFNetworking/AFNetworking), which is included in example project.

## Get Started
#### Step 1: Setup STNetTaskQueue after your app launch
```objective-c
NSURL *baseUrl = [NSURL URLWithString:@"http://api.openweathermap.org"];
STHTTPNetTaskQueueHandler *httpHandler = [[STHTTPNetTaskQueueHandler alloc] initWithQueue:[STNetTaskQueue sharedQueue] baseURL:baseUrl];
[STNetTaskQueue sharedQueue].handler = httpHandler;
```

#### Step 2: Write your net task for each reqeust
```objective-c
@interface STOpenWeatherNetTask : STHTTPNetTask

@property (nonatomic, strong) NSString *latitude;
@property (nonatomic, strong) NSString *longitude;
@property (nonatomic, strong, readonly) NSString *place;
@property (nonatomic, assign, readonly) float temperature;

@end
```

```objective-c
@implementation STOpenWeatherNetTask

- (STHTTPNetTaskMethod)method
{
    return STHTTPNetTaskGet;
}

- (NSString *)uri
{
    return @"data/2.5/weather";
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
```objective-c
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

```objective-c
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

