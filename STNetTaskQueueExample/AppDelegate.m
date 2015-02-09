//
//  AppDelegate.m
//  STNetTaskQueueExample
//
//  Created by Kevin Lin on 9/2/15.
//  Copyright (c) 2015 Sth4Me. All rights reserved.
//

#import "AppDelegate.h"
#import "STNetTaskQueue.h"
#import "STHTTPNetTaskQueueHandler.h"
#import "ViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Setup up shared STNetTaskQUeue
    NSURL *baseUrl = [NSURL URLWithString:@"http://api.openweathermap.org"];
    STHTTPNetTaskQueueHandler *httpHandler = [[STHTTPNetTaskQueueHandler alloc] initWithQueue:[STNetTaskQueue sharedQueue]
                                                                                      baseURL:baseUrl];
    [STNetTaskQueue sharedQueue].handler = httpHandler;
    
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.rootViewController = [ViewController new];
    [self.window makeKeyAndVisible];
    
    return YES;
}

@end
