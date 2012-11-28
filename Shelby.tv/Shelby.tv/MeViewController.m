//
//  MeViewController.m
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 10/17/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

#import "MeViewController.h"
#import "SPVideoReel.h"

@interface MeViewController ()

- (void)launchPlayerWithStreamEntries;
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

#pragma mark - Private Methods
- (void)launchPlayerWithStreamEntries
{
    CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Stream];
    NSArray *videoFrames = [[NSArray alloc] initWithArray:[dataUtility fetchStreamEntries]];
    SPVideoReel *reel = [[SPVideoReel alloc] initWithVideoFrames:videoFrames];
    [self presentViewController:reel animated:YES completion:nil];
    DLog(@"Stream Frames Count: %d", [videoFrames count]);
}

- (void)launchPlayerWithQueueRollEntries
{
    CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_QueueRoll];
    NSArray *videoFrames = [dataUtility fetchQueueRollEntries];
    SPVideoReel *reel = [[SPVideoReel alloc] initWithVideoFrames:videoFrames];
    [self presentViewController:reel animated:YES completion:nil];
    DLog(@"Queue Frames Count: %d", [videoFrames count]);
}

- (void)launchPlayerWithPersonalRollEntries
{
    CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_PersonalRoll];
    NSArray *videoFrames = [dataUtility fetchPersonalRollEntries];
    SPVideoReel *reel = [[SPVideoReel alloc] initWithVideoFrames:videoFrames];
    [self presentViewController:reel animated:YES completion:nil];
    DLog(@"Roll Frames Count: %d", [videoFrames count]);
}

@end