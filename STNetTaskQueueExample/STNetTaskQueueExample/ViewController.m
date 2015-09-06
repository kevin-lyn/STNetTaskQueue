//
//  ViewController.m
//  STNetTaskQueueExample
//
//  Created by Kevin Lin on 9/2/15.
//  Copyright (c) 2015 Sth4Me. All rights reserved.
//

#import "ViewController.h"
#import <ReactiveCocoa/ReactiveCocoa.h>
#import "STNetTaskQueue.h"
#import "STOpenWeatherNetTask.h"
#import "STLocation.h"

@interface ViewController ()<STNetTaskDelegate>

@end

@implementation ViewController
{
    STOpenWeatherNetTask *_openWeatherTask;
    UILabel *_resultLabel;
    UIButton *_goBtn;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _resultLabel = [[UILabel alloc] initWithFrame:self.view.bounds];
    _resultLabel.textColor = [UIColor whiteColor];
    _resultLabel.textAlignment = NSTextAlignmentCenter;
    _resultLabel.numberOfLines = 0;
    [self.view addSubview:_resultLabel];
    
    _goBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 100, 40)];
    _goBtn.backgroundColor = [UIColor whiteColor];
    _goBtn.layer.cornerRadius = 10;
    [_goBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [_goBtn setTitle:@"Go" forState:UIControlStateNormal];
    [_goBtn addTarget:self action:@selector(goBtnDidTap) forControlEvents:UIControlEventTouchUpInside];
    _goBtn.center = self.view.center;
    [self.view addSubview:_goBtn];
}

- (void)goBtnDidTap
{
    [self sendOpenWeatherTask];
    
    /*
     Work with ReactiveCocoa, get net task result with 'subscribeNext'.
     Note that ReactiveCocoa.h should be imported before STNetTaskQueue.
    
    [STNetTaskObserve(_openWeatherTask) subscribeNext:^(STOpenWeatherNetTask *task) {
        if (task.error) { // Would be network issue
            _resultLabel.text = @"Network Unavailable";
            _goBtn.hidden = YES;
            return;
        }
        _resultLabel.text = [NSString stringWithFormat:@"%@\n%.1f°C", task.place, task.temperature];
        _goBtn.hidden = YES;
    }];
     
     */
}

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

@end
