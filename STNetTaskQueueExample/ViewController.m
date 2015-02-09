//
//  ViewController.m
//  STNetTaskQueueExample
//
//  Created by Kevin Lin on 9/2/15.
//  Copyright (c) 2015 Sth4Me. All rights reserved.
//

#import "ViewController.h"
#import "STNetTaskQueue.h"
#import "STOpenWeatherNetTask.h"

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
}

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

@end
