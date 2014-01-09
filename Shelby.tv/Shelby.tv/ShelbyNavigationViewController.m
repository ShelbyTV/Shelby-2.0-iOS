//
//  ShelbyNavigationViewController.m
//  Shelby.tv
//
//  Created by Keren on 1/8/14.
//  Copyright (c) 2014 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyNavigationViewController.h"
#import "ShelbyStreamInfoViewController.h"
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

- (void)pushViewControllerForChannel:(DisplayChannel *)channel shouldInitializeVideoReel:(BOOL)shouldInitializeVideoReel
{
    ShelbyStreamInfoViewController *streamInfoVC = [[ShelbyStreamInfoViewController alloc] init];
    streamInfoVC.videoReelVC = self.videoReelVC;
    streamInfoVC.shouldInitializeVideoReel = shouldInitializeVideoReel;
    streamInfoVC.displayChannel = channel;

    [self pushViewController:streamInfoVC animated:YES];
}
@end
