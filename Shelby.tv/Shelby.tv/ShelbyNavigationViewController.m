//
//  ShelbyNavigationViewController.m
//  Shelby.tv
//
//  Created by Keren on 1/8/14.
//  Copyright (c) 2014 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyNavigationViewController.h"
#import "ShelbyTopLevelNavigationViewController.h"

@interface ShelbyNavigationViewController ()

@end

@implementation ShelbyNavigationViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)setCurrentUser:(User *)currentUser
{
    if (_currentUser != currentUser) {
        _currentUser = currentUser;
    
        ShelbyTopLevelNavigationViewController *topLevelNavigationVC = (ShelbyTopLevelNavigationViewController *)self.topViewController;
        topLevelNavigationVC.currentUser = self.currentUser;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)pushViewController:(UIViewController *)viewController
{
    [self pushViewController:viewController animated:YES];
}

- (void)pushUserProfileViewController:(ShelbyUserInfoViewController *)viewController
{
    viewController.streamInfoVC = [self setupStreamInfoViewControllerWithChannel:nil];
    [self pushViewController:viewController];
}

- (ShelbyStreamInfoViewController *)setupStreamInfoViewControllerWithChannel:(DisplayChannel *)channel
{
    ShelbyStreamInfoViewController *streamInfoVC = [self.storyboard instantiateViewControllerWithIdentifier:@"StreamInfo"];
    streamInfoVC.videoReelVC = self.videoReelVC;
    streamInfoVC.displayChannel = channel;
    streamInfoVC.delegate = self;

    return streamInfoVC;
}

- (void)pushViewControllerForChannel:(DisplayChannel *)channel
{
    ShelbyStreamInfoViewController *streamInfoVC = [self setupStreamInfoViewControllerWithChannel:channel];
    [self pushViewController:streamInfoVC animated:YES];
}

#pragma mark - ShelbyStreamInfoProtocol
- (void)userProfileWasTapped:(NSString *)userID
{
    [self.topContainerDelegate userProfileWasTapped:userID];
}

- (void)openLikersViewForVideo:(Video *)video withLikers:(NSMutableOrderedSet *)likers
{
    [self.topContainerDelegate openLikersViewForVideo:video withLikers:likers];
}

- (void)userLikedVideoFrame:(Frame *)videoFrame
{
    // Here is where we might want to let the currently playing video to animate the heart if that's the currently played video
}

- (void)shareVideoFrame:(Frame *)videoFrame
{
    [self.topContainerDelegate shareVideoFrame:videoFrame];
}
@end
