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
#import "ShelbyVideoReelViewController.h"
#import "SPShareController.h"

#define FULLSCREEN_ANIMATION_DURATION 0.75
#define FULLSCREEN_ANIMATION_DELAY 0.f
#define FULLSCREEN_ANIMATION_CONTROLS_DELAY 1.0f
#define FULLSCREEN_ANIMATION_DAMPING .75
#define FULLSCREEN_ANIMATION_VELOCITY 7.f
#define FULLSCREEN_ANIMATION_OPTIONS UIViewAnimationCurveEaseIn | UIViewAnimationOptionBeginFromCurrentState

@interface ShelbyTopContainerViewController ()
//container Views
@property (weak, nonatomic) IBOutlet UIView *navigationViewContainer;
@property (weak, nonatomic) IBOutlet UIView *currentlyOnViewContainer;
@property (weak, nonatomic) IBOutlet UIView *videoReelViewContainer;

//constraints
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *videoReelWidthConstraint;

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

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _fullscreenVideoWidth = 1024;
    _smallscreenVideoWidth = self.videoReelWidthConstraint.constant;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(toggleFullscreenVideo)
                                                 name:kShelbySingleTapOnVideoReelNotification
                                               object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)toggleFullscreenVideo
{
    CGFloat newWidth, videoOverlaysAlpha, controlsDelay;
    CGAffineTransform navTransform;
    VideoControlsDisplayMode controlsDisplayMode;
    if ([self isVideoFullscreen] && self.videoReelVC.videoControlsVC.displayMode != VideoControlsDisplayShowingForIPadFullScreen) {
        newWidth = _smallscreenVideoWidth;
        navTransform = CGAffineTransformIdentity;
        videoOverlaysAlpha = 1.f;
        controlsDisplayMode = VideoControlsDisplayActionsAndPlaybackControls;
        controlsDelay = 0.f;
    } else {
        newWidth = _fullscreenVideoWidth;
        navTransform = CGAffineTransformMakeScale(0.8, 0.8);
        videoOverlaysAlpha = 0.f;
        controlsDisplayMode = VideoControlsDisplayHiddenForIPadFullScreen;
        if (self.videoReelVC.videoControlsVC.displayMode == VideoControlsDisplayShowingForIPadFullScreen) {
            controlsDelay = 0.f;
        } else {
            //fading the video controls slower to give users a hint that they can still bring them up
            controlsDelay = FULLSCREEN_ANIMATION_CONTROLS_DELAY;
        }
    }
    
    //most controls react immediately
    [UIView animateWithDuration:FULLSCREEN_ANIMATION_DURATION delay:FULLSCREEN_ANIMATION_DELAY usingSpringWithDamping:FULLSCREEN_ANIMATION_DAMPING initialSpringVelocity:FULLSCREEN_ANIMATION_VELOCITY options:FULLSCREEN_ANIMATION_OPTIONS animations:^{
        
        self.navigationViewContainer.transform = navTransform;
        self.currentlyOnViewContainer.transform = navTransform;
        self.videoReelWidthConstraint.constant = newWidth;
        self.videoReelVC.videoOverlayView.alpha = videoOverlaysAlpha;
        [self.view layoutIfNeeded];

    } completion:nil];
    
    //controsl may be different (see above)
    [UIView animateWithDuration:FULLSCREEN_ANIMATION_DURATION delay:FULLSCREEN_ANIMATION_DELAY + controlsDelay usingSpringWithDamping:FULLSCREEN_ANIMATION_DAMPING initialSpringVelocity:FULLSCREEN_ANIMATION_VELOCITY options:FULLSCREEN_ANIMATION_OPTIONS animations:^{
        
        [self.videoReelVC.videoControlsVC setDisplayMode:controlsDisplayMode];
        [self.view layoutIfNeeded];
        
    } completion:nil];
}

- (BOOL)isVideoFullscreen
{
    return self.videoReelWidthConstraint.constant == _fullscreenVideoWidth;
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
        self.sideNavigationVC.currentUser = currentUser;
    }
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

- (void)shareVideoFrame:(Frame *)videoFrame
{
    // Might decide to move this to the brain, but for now, leaving here.
    SPShareController *shareController = [[SPShareController alloc] initWithVideoFrame:videoFrame fromViewController:self atRect:CGRectZero];
    [shareController shareWithCompletionHandler:^(BOOL completed) {
        // do stuff!;
    }];
}

- (void)loginUser
{
    [self.masterDelegate presentUserLogin];
}

- (void)logoutUser
{
    [self.masterDelegate logoutUser];

}
@end
