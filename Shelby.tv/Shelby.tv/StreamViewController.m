//
//  FirstViewController.m
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 10/17/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

#import "StreamViewController.h"

@interface StreamViewController ()



@end

@implementation StreamViewController
@synthesize button = _button;


#pragma mark - Memory Management Methods
- (void)dealloc
{
    self.button = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - View Lifecycle Methods
- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

#pragma mark - Private Methods


@end