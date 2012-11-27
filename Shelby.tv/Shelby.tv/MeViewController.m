//
//  MeViewController.m
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 10/17/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

#import "MeViewController.h"

@interface MeViewController ()

- (void)launchPlayerWithStreamEntires;
- (void)launchPlayerWithQueueRollEntries;
- (void)launchPlayerWithPersonalRollEntries;

@end

@implementation MeViewController
@synthesize streamButton = _streamButton;
@synthesize queueRollButton = _queueRollButton;
@synthesize personalRollButton = _personalRollButton;

#pragma mark - Memory Management Methods
- (void)dealloc
{
    self.streamButton = nil;
    self.queueRollButton = nil;
    self.personalRollButton = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - View Lifecycle Methods
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.streamButton addTarget:self action:@selector(launchPlayerWithStreamEntries) forControlEvents:UIControlEventTouchUpInside];
    [self.queueRollButton addTarget:self action:@selector(launchPlayerWithQueueRollEntries) forControlEvents:UIControlEventTouchUpInside];
    [self.personalRollButton addTarget:self action:@selector(launchPlayerWithPersonalRollEntries) forControlEvents:UIControlEventTouchUpInside];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

#pragma mark - Private Methods
- (void)launchPlayerWithStreamEntires
{
    CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Stream];
    NSMutableArray *videoFrames = [[NSMutableArray alloc] initWithArray:[dataUtility fetchStreamEntries] copyItems:YES];
}

- (void)launchPlayerWithQueueRollEntries
{
    CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_QueueRoll];
    NSMutableArray *videoFrames = [[NSMutableArray alloc] initWithArray:[dataUtility fetchQueueRollEntries] copyItems:YES];
}

- (void)launchPlayerWithPersonalRollEntries
{
    CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_PersonalRoll];
    NSMutableArray *videoFrames = [[NSMutableArray alloc] initWithArray:[dataUtility fetchPersonalRollEntries] copyItems:YES];
}

@end