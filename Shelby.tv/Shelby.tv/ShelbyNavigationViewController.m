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

- (void)setMasterDelegate:(id<ShelbyNavigationProtocol>)masterDelegate
{
    _masterDelegate = masterDelegate;
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
    [self.masterDelegate userProfileWasTapped:userID];
}

- (void)openLikersViewForVideo:(Video *)video withLikers:(NSMutableOrderedSet *)likers
{
    [self.masterDelegate openLikersViewForVideo:video withLikers:likers];
}
@end
