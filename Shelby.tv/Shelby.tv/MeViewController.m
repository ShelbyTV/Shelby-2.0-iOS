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
- (void)logoutButtonAction;

@end

@implementation MeViewController

#pragma mark - Memory Management Methods
- (void)dealloc
{
    self.streamButton = nil;
    self.queueRollButton = nil;
    self.personalRollButton = nil;
    self.logoutButton = nil;
    self.versionLabel = nil;
}

#pragma mark - View Lifecycle Methods
- (void)viewDidLoad
{
    [super viewDidLoad];
 
    // Version
    [self.versionLabel setText:[NSString stringWithFormat:@"Shelby.tv for iPad v%@", kCurrentVersion]];
    
    // Actions
    [self.streamButton addTarget:self action:@selector(launchPlayerWithStreamEntries) forControlEvents:UIControlEventTouchUpInside];
    [self.queueRollButton addTarget:self action:@selector(launchPlayerWithQueueRollEntries) forControlEvents:UIControlEventTouchUpInside];
    [self.personalRollButton addTarget:self action:@selector(launchPlayerWithPersonalRollEntries) forControlEvents:UIControlEventTouchUpInside];
    [self.logoutButton addTarget:self action:@selector(logoutButtonAction) forControlEvents:UIControlEventTouchUpInside];
    
    // Fonts
    [self.streamButton.titleLabel setFont:[UIFont fontWithName:@"Ubuntu-Bold" size:self.streamButton.titleLabel.font.pointSize]];
    [self.queueRollButton.titleLabel setFont:[UIFont fontWithName:@"Ubuntu-Bold" size:self.queueRollButton.titleLabel.font.pointSize]];
    [self.personalRollButton.titleLabel setFont:[UIFont fontWithName:@"Ubuntu-Bold" size:self.personalRollButton.titleLabel.font.pointSize]];
    [self.logoutButton.titleLabel setFont:[UIFont fontWithName:@"Ubuntu-Bold" size:self.logoutButton.titleLabel.font.pointSize]];
    [self.versionLabel setFont:[UIFont fontWithName:@"Ubuntu-Bold" size:self.versionLabel.font.pointSize]];
    
}

#pragma mark - Private Methods
- (void)launchPlayerWithStreamEntries
{
    CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
    NSMutableArray *videoFrames = [dataUtility fetchStreamEntries];

    if ( [videoFrames count] ) {
        
        SPVideoReel *reel = [[SPVideoReel alloc] initWithCategoryType:CategoryType_Stream categoryTitle:@"Stream" andVideoFrames:videoFrames];
        [self presentViewController:reel animated:YES completion:nil];
        
    } else {
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                            message:@"No videos in Stream."
                                                           delegate:self
                                                  cancelButtonTitle:@"Dismiss"
                                                  otherButtonTitles:nil];
        
        [alertView show];
        
    }
    
}

- (void)launchPlayerWithQueueRollEntries
{
    CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
    NSMutableArray *videoFrames = [dataUtility fetchQueueRollEntries];
    
    if ( [videoFrames count] ) {
        
        SPVideoReel *reel = [[SPVideoReel alloc] initWithCategoryType:CategoryType_QueueRoll categoryTitle:@"Queue Roll" andVideoFrames:videoFrames];
        [self presentViewController:reel animated:YES completion:nil];
        
    } else {
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                            message:@"No videos in Queue Roll."
                                                           delegate:self
                                                  cancelButtonTitle:@"Dismiss"
                                                  otherButtonTitles:nil];
        
        [alertView show];
        
    }

}

- (void)launchPlayerWithPersonalRollEntries
{
    CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
    NSMutableArray *videoFrames = [dataUtility fetchPersonalRollEntries];
    
    if ( [videoFrames count] ) {
        
        SPVideoReel *reel = [[SPVideoReel alloc] initWithCategoryType:CategoryType_PersonalRoll categoryTitle:@"Personal Roll" andVideoFrames:videoFrames];
        [self presentViewController:reel animated:YES completion:nil];
        
    } else {
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                            message:@"No videos in Personal Roll."
                                                           delegate:self
                                                  cancelButtonTitle:@"Dismiss"
                                                  otherButtonTitles:nil];
        
        [alertView show];
        
    }
    
}

- (void)dismissVideoReel:(SPVideoReel*)reel
{
    __block SPVideoReel *reelSelf = reel;
    
    [reel dismissViewControllerAnimated:YES completion:^{

        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarStyleBlackTranslucent];
    
        reelSelf = nil;
        DLog(@"Reel Dismissed");
        
    }];

}

- (void)logoutButtonAction
{
    AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    [appDelegate logout];
}

@end
