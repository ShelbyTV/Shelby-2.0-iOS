//
//  ShelbyTopContainerViewController.m
//  Shelby.tv
//
//  Created by Keren on 1/8/14.
//  Copyright (c) 2014 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyTopContainerViewController.h"
#import "ShelbyCurrentlyOnViewController.h"
#import "ShelbyNavigationViewController.h"
#import "SPShareController.h"
#import "VideoControlsViewController.h" // <-- for the constants... TODO: refactor

#define FULLSCREEN_ANIMATION_DURATION 0.75
#define FULLSCREEN_ANIMATION_DELAY 0.f
#define FULLSCREEN_ANIMATION_DAMPING 1.0
#define FULLSCREEN_ANIMATION_VELOCITY 8.f
#define FULLSCREEN_ANIMATION_OPTIONS UIViewAnimationCurveEaseInOut | UIViewAnimationOptionBeginFromCurrentState

#define LEFT_SIDE_CONSTRAINT_HORIZONTAL_ADJUSTMENT 400
#define RIGHT_SIDE_CONSTRAINT_HORIZONTAL_ADJUSTMENT 2000

@interface ShelbyTopContainerViewController ()
//container Views
@property (weak, nonatomic) IBOutlet UIView *navigationViewContainer;
@property (weak, nonatomic) IBOutlet UIView *currentlyOnViewContainer;
@property (weak, nonatomic) IBOutlet UIView *videoReelViewContainer;

//constraints
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *videoReelWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *navigationCenterXConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *currentlyOnCenterXConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *videoReelHorizontalSpaceRightSideConstraint;

//View Controllers
@property (nonatomic, strong) ShelbyVideoReelViewController *videoReelVC;
@property (nonatomic, strong) ShelbyNavigationViewController *sideNavigationVC;
@property (nonatomic, strong) ShelbyCurrentlyOnViewController *currentlyOnVC;
@end

@implementation ShelbyTopContainerViewController {
    CGFloat _fullscreenVideoWidth, _smallscreenVideoWidth;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _fullscreenVideoWidth = 1024;
    _smallscreenVideoWidth = self.videoReelWidthConstraint.constant;
    
    [self observeFullscreenNotifications];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.navigationCenterXConstraint.constant += LEFT_SIDE_CONSTRAINT_HORIZONTAL_ADJUSTMENT;
    self.currentlyOnCenterXConstraint.constant += LEFT_SIDE_CONSTRAINT_HORIZONTAL_ADJUSTMENT;
    self.videoReelHorizontalSpaceRightSideConstraint.constant -= RIGHT_SIDE_CONSTRAINT_HORIZONTAL_ADJUSTMENT;
    [self.view layoutIfNeeded];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [UIView animateWithDuration:FULLSCREEN_ANIMATION_DURATION delay:FULLSCREEN_ANIMATION_DELAY usingSpringWithDamping:FULLSCREEN_ANIMATION_DAMPING initialSpringVelocity:FULLSCREEN_ANIMATION_VELOCITY options:UIViewAnimationCurveEaseIn animations:^{
        
        self.navigationCenterXConstraint.constant -= LEFT_SIDE_CONSTRAINT_HORIZONTAL_ADJUSTMENT;
        self.currentlyOnCenterXConstraint.constant -= LEFT_SIDE_CONSTRAINT_HORIZONTAL_ADJUSTMENT;
        self.videoReelHorizontalSpaceRightSideConstraint.constant += RIGHT_SIDE_CONSTRAINT_HORIZONTAL_ADJUSTMENT;
        [self.view layoutIfNeeded];
        
    } completion:^(BOOL finished) {
        //?
    }];
}

- (void)animateDisappearanceWithCompletion:(void(^)())completion
{
    [UIView animateWithDuration:FULLSCREEN_ANIMATION_DURATION animations:^{

        self.navigationCenterXConstraint.constant += LEFT_SIDE_CONSTRAINT_HORIZONTAL_ADJUSTMENT;
        self.currentlyOnCenterXConstraint.constant += LEFT_SIDE_CONSTRAINT_HORIZONTAL_ADJUSTMENT;
        self.videoReelHorizontalSpaceRightSideConstraint.constant -= RIGHT_SIDE_CONSTRAINT_HORIZONTAL_ADJUSTMENT;
        [self.view layoutIfNeeded];
        
    } completion:^(BOOL finished) {
        if (completion) {
            completion();
        }
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString *segueIdentifier = segue.identifier;
    if ([segueIdentifier isEqualToString:@"SideNavigation"]) {
        self.sideNavigationVC = segue.destinationViewController;
    } else if ([segueIdentifier isEqualToString:@"VideoReel"]) {
        self.videoReelVC = segue.destinationViewController;
    } else if ([segueIdentifier isEqualToString:@"CurrentlyOn"]) {
        self.currentlyOnVC = segue.destinationViewController;
    }
    
    if (self.sideNavigationVC && self.videoReelVC) {
        self.sideNavigationVC.topContainerDelegate = self;
        self.sideNavigationVC.currentUser = self.currentUser;
        self.sideNavigationVC.videoReelVC = self.videoReelVC;
    }
}

- (void)pushViewController:(UIViewController *)viewController
{
    [self.sideNavigationVC pushViewController:viewController];
}

- (void)pushUserProfileViewController:(ShelbyUserInfoViewController *)viewController
{
    [self.sideNavigationVC pushUserProfileViewController:viewController];
}

- (void)setCurrentUser:(User *)currentUser
{
    if (_currentUser != currentUser) {
        _currentUser = currentUser;
    }

    self.sideNavigationVC.currentUser = currentUser;
}

#pragma mark - ShelbyNavigationProtocol
- (void)userProfileWasTapped:(NSString *)userID
{
    [self.masterDelegate userProfileWasTapped:userID];
}

- (void)openLikersViewForVideo:(Video *)video withLikers:(NSMutableOrderedSet *)likers
{
    [self.masterDelegate openLikersViewForVideo:video withLikers:likers];
}

- (void)logoutUser
{
    [self.masterDelegate logoutUser];

}

#pragma mark - Full/Small Screen Video Size Helpers

- (void)observeFullscreenNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(goFullscreenVideo)
                                                 name:kShelbyRequestFullscreenPlaybackNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(goSmallscreenVideo)
                                                 name:kShelbyRequestSmallscreenPlaybackNotification
                                               object:nil];
}

- (void)goFullscreenVideo
{
    if (![self isVideoFullscreen]) {
        [self animateSizeChangesWithLeftConstantAdjustment:self.navigationViewContainer.bounds.size.width*0.5
                                            videoReelWidth:_fullscreenVideoWidth
                                                 statusBar:YES];
    }
}

- (void)goSmallscreenVideo
{
    if ([self isVideoFullscreen]) {
        [self animateSizeChangesWithLeftConstantAdjustment:-self.navigationViewContainer.bounds.size.width*0.5
                                            videoReelWidth:_smallscreenVideoWidth
                                                 statusBar:NO];
    }
}

- (void)animateSizeChangesWithLeftConstantAdjustment:(CGFloat)leftConstantAdjustment
                                      videoReelWidth:(CGFloat)newWidth
                                           statusBar:(BOOL)hideStatusBar
{
    [UIView animateWithDuration:FULLSCREEN_ANIMATION_DURATION delay:FULLSCREEN_ANIMATION_DELAY usingSpringWithDamping:FULLSCREEN_ANIMATION_DAMPING initialSpringVelocity:FULLSCREEN_ANIMATION_VELOCITY options:FULLSCREEN_ANIMATION_OPTIONS animations:^{
        
        self.navigationCenterXConstraint.constant += leftConstantAdjustment;
        self.currentlyOnCenterXConstraint.constant += leftConstantAdjustment;
        self.videoReelWidthConstraint.constant = newWidth;
        [[UIApplication sharedApplication] setStatusBarHidden:hideStatusBar withAnimation:UIStatusBarAnimationSlide];
        [self.view layoutIfNeeded];
        
    } completion:nil];
}

- (BOOL)isVideoFullscreen
{
    return self.videoReelWidthConstraint.constant == _fullscreenVideoWidth;
}

@end
