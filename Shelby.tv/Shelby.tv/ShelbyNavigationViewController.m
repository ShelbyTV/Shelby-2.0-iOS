//
//  ShelbyNavigationViewController.m
//  Shelby.tv
//
//  Created by Keren on 1/8/14.
//  Copyright (c) 2014 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyNavigationViewController.h"
#import "Dashboard.h"
#import "Roll.h"
#import "ShelbyTopLevelNavigationViewController.h"
#import "ShelbyVideoContentBrowsingViewControllerProtocol.h"

@interface ShelbyNavigationViewController ()
@property (strong, nonatomic) UIViewController<ShelbyVideoContentBrowsingViewControllerProtocol> *currentlyOnVC;
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

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playbackEntityDidChangeNotification:)
                                                 name:kShelbyVideoReelDidChangePlaybackEntityNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(requestToShowCurrentlyOnNotification:)
                                                 name:kShelbyRequestToShowCurrentlyOnNotification object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setCurrentUser:(User *)currentUser
{
    if (_currentUser != currentUser) {
        _currentUser = currentUser;
    
        ShelbyTopLevelNavigationViewController *topLevelNavigationVC = (ShelbyTopLevelNavigationViewController *)self.topViewController;
        if ([topLevelNavigationVC respondsToSelector:@selector(currentUser)]) {
            topLevelNavigationVC.currentUser = self.currentUser;
        }
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

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    //If the pushed VC has the same channel as currentlyOnVC, and the currentlyOnVC
    //is not on our stack, we sneakily swap in the currentlyOnVC.
    //hacky?  kinda.  clever?  kinda.  right thing to do?  seemingly. --ds
    if (self.currentlyOnVC &&
        ![self.viewControllers containsObject:self.currentlyOnVC] &&
        [viewController conformsToProtocol:@protocol(ShelbyVideoContentBrowsingViewControllerProtocol)]) {
        UIViewController<ShelbyVideoContentBrowsingViewControllerProtocol> *videoVC = (UIViewController<ShelbyVideoContentBrowsingViewControllerProtocol>*)viewController;
        if ([videoVC displayChannel] == [self.currentlyOnVC displayChannel]) {
            viewController = self.currentlyOnVC;
        }
    }
    
    [super pushViewController:viewController animated:animated];
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

- (ShelbyStreamInfoViewController *)pushViewControllerForChannel:(DisplayChannel *)channel
{
    ShelbyStreamInfoViewController *streamInfoVC = [self setupStreamInfoViewControllerWithChannel:channel];
    NSString *description = channel.dashboard ? channel.dashboard.displayTitle : channel.roll.displayTitle;
    streamInfoVC.title = description;
    [self pushViewController:streamInfoVC animated:YES];
    return streamInfoVC;
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

#pragma mark - Notification Handling
- (void)playbackEntityDidChangeNotification:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;
    DisplayChannel *channel = userInfo[kShelbyVideoReelChannelKey];
    
    if ([self.visibleViewController conformsToProtocol:@protocol(ShelbyVideoContentBrowsingViewControllerProtocol)]) {
        UIViewController<ShelbyVideoContentBrowsingViewControllerProtocol> *videoVC = (UIViewController<ShelbyVideoContentBrowsingViewControllerProtocol>*)self.visibleViewController;
        if ([videoVC displayChannel] == channel) {
            self.currentlyOnVC = videoVC;
        }
    }
}

- (void)requestToShowCurrentlyOnNotification:(NSNotification *)notification
{
    if (!self.currentlyOnVC) {
        STVDebugAssert(NO, @"shouldn't request to show currently on w/o having a reference");
        return;
    }
    
    //if currently on is down the stack, pop to it
    if ([self.viewControllers containsObject:self.currentlyOnVC]) {
        [self popToViewController:self.currentlyOnVC animated:YES];
    } else {
        //otehrwise, just push it
        [self pushViewController:self.currentlyOnVC animated:YES];
    }
    
    [self.currentlyOnVC scrollCurrentlyPlayingIntoView];
}

@end
