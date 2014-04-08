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
#import "ShelbyUserFollowingViewController.h"
#import "ShelbyVideoContentBrowsingViewControllerProtocol.h"

NSString * const kShelbyNavigateToSingleVideoEntryNotification = @"kShelbyNavigateToSingleVideoEntryNotification";
NSString * const kShelbyNavigateToChannelKey = @"kShelbyNavigateToChannelKey";
NSString * const kShelbyNavigateToSingleVideoEntryArrayKey = @"kShelbyNavigateToSingleVideoEntryArrayKey";
NSString * const kShelbyNavigateToTitleOverrideKey = @"kShelbyNavigateToTitleOverrideKey";

@interface ShelbyNavigationViewController ()
@property (strong, nonatomic) UIViewController<ShelbyVideoContentBrowsingViewControllerProtocol> *currentlyOnVC;
@end

@implementation ShelbyNavigationViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _bottomInsetForContainedScrollViews = 0.f;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playbackEntityDidChangeNotification:)
                                                 name:kShelbyPlaybackEntityDidChangeNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(requestToShowCurrentlyOnNotification:)
                                                 name:kShelbyRequestToShowCurrentlyOnNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(navigateToSingleVideoEntryNotification:)
                                                 name:kShelbyNavigateToSingleVideoEntryNotification
                                               object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setCurrentUser:(User *)currentUser
{
    if (_currentUser != currentUser) {
        _currentUser = currentUser;
    }
    // Passing the current user down the chain, even if it is the same user. (As the user_type might have changed)
    ShelbyTopLevelNavigationViewController *topLevelNavigationVC = (ShelbyTopLevelNavigationViewController *)self.topViewController;
    if ([topLevelNavigationVC respondsToSelector:@selector(currentUser)]) {
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

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    //If the pushed VC has the same channel as currentlyOnVC, and the currentlyOnVC
    //is not on our stack, we sneakily swap in the currentlyOnVC.
    //hacky?  kinda.  clever?  kinda.  right thing to do?  seemingly. --ds
    if (self.currentlyOnVC &&
        ![self.viewControllers containsObject:self.currentlyOnVC] &&
        [viewController conformsToProtocol:@protocol(ShelbyVideoContentBrowsingViewControllerProtocol)]) {
        UIViewController<ShelbyVideoContentBrowsingViewControllerProtocol> *videoVC = (UIViewController<ShelbyVideoContentBrowsingViewControllerProtocol>*)viewController;
        if ([videoVC displayChannel] == [self.currentlyOnVC displayChannel] && videoVC.singleVideoEntry == self.currentlyOnVC.singleVideoEntry) {
            viewController = self.currentlyOnVC;
        }
    }
    
    //To account for any view overlapping us on the bottom (ie. "currently on")
    //Add content offset to bottom of all scrollviews in pushed VC
    //but don't re-add these offsets for the currently on vc (they were added on its first push)
    if (viewController != self.currentlyOnVC) {
        NSMutableArray *pushedScrollViews = [self scrollViewsInViews:@[viewController.view]];
        if ([pushedScrollViews count]) {
            for (UIScrollView *scrollView in pushedScrollViews) {
                UIEdgeInsets curInsets = scrollView.contentInset;
                [scrollView setContentInset:UIEdgeInsetsMake(curInsets.top,
                                                             curInsets.left,
                                                             curInsets.bottom + self.bottomInsetForContainedScrollViews,
                                                             curInsets.right)];
                UIEdgeInsets curScrollInsets = scrollView.scrollIndicatorInsets;
                [scrollView setScrollIndicatorInsets:UIEdgeInsetsMake(curScrollInsets.top,
                                                                      curScrollInsets.left,
                                                                      curScrollInsets.bottom + self.bottomInsetForContainedScrollViews,
                                                                      curScrollInsets.right)];
            }
        }
    }

    [super pushViewController:viewController animated:animated];
}

- (void)pushUserProfileViewController:(ShelbyUserInfoViewController *)viewController
{
    viewController.streamInfoVC = [self setupStreamInfoViewControllerWithChannel:nil];
    viewController.followingVC = [self setupUserFollowingViewController];
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

- (ShelbyUserFollowingViewController *)setupUserFollowingViewController
{
    ShelbyUserFollowingViewController *followingVC = [[UIStoryboard storyboardWithName:@"UserFollowing" bundle:nil] instantiateInitialViewController];
    followingVC.delegate = self;
    
    return followingVC;
}

- (ShelbyStreamInfoViewController *)pushViewControllerForChannel:(DisplayChannel *)channel titleOverride:(NSString *)titleOverride animated:(BOOL)animated
{
    return [self pushViewControllerForChannel:channel titleOverride:titleOverride showUserEducationSections:NO animated:animated];
}

- (ShelbyStreamInfoViewController *)pushViewControllerForChannel:(DisplayChannel *)channel singleVideoEntry:(NSArray *)singleVideoEntry titleOverride:(NSString *)titleOverride animated:(BOOL)animated
{
    ShelbyStreamInfoViewController *streamInfoVC = [self setupStreamInfoViewControllerWithChannel:channel];
    streamInfoVC.title = titleOverride ? titleOverride : (channel.dashboard ? channel.dashboard.displayTitle : channel.roll.displayTitle);
    streamInfoVC.mayShowFollowChannels = NO;
    streamInfoVC.mayShowConnectSocial = NO;
    streamInfoVC.singleVideoEntry = singleVideoEntry;
    [self pushViewController:streamInfoVC animated:animated];
    return streamInfoVC;
}

- (ShelbyStreamInfoViewController *)pushViewControllerForChannel:(DisplayChannel *)channel titleOverride:(NSString *)titleOverride showUserEducationSections:(BOOL)showUserEducationSections animated:(BOOL)animated
{
    ShelbyStreamInfoViewController *streamInfoVC = [self setupStreamInfoViewControllerWithChannel:channel];
    streamInfoVC.title = titleOverride ? titleOverride : (channel.dashboard ? channel.dashboard.displayTitle : channel.roll.displayTitle);
    streamInfoVC.mayShowFollowChannels = showUserEducationSections;
    streamInfoVC.mayShowConnectSocial = showUserEducationSections;
    [self pushViewController:streamInfoVC animated:animated];
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
    DisplayChannel *channel = userInfo[kShelbyPlaybackCurrentChannelKey];
    
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

- (void)navigateToSingleVideoEntryNotification:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;
    DisplayChannel *channel = userInfo[kShelbyNavigateToChannelKey];
    NSArray *videoEntry = userInfo[kShelbyNavigateToSingleVideoEntryArrayKey];
    NSString *titleOverride = userInfo[kShelbyNavigateToTitleOverrideKey];
    
    [self pushViewControllerForChannel:channel singleVideoEntry:videoEntry titleOverride:titleOverride animated:YES];
}

#pragma mark - Helpers

- (NSMutableArray *)scrollViewsInViews:(NSArray *)views
{
    NSMutableArray *scrollViews = [NSMutableArray new];
    if ([views count]) {
        for (UIView *v in views) {
            if ([v isKindOfClass:[UIScrollView class]]) {
                [scrollViews addObject:v];
            } else {
                [scrollViews addObjectsFromArray:[self scrollViewsInViews:v.subviews]];
            }
        }
        return scrollViews;
    } else {
        return nil;
    }
}

@end
