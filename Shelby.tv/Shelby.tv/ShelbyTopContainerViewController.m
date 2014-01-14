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
                                                 name:kShelbySingleTapOnVideReelNotification
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
    CGFloat newWidth, videoOverlaysAlpha;
    CGAffineTransform navTransform;
    if ([self isVideoFullscreen]) {
        newWidth = _smallscreenVideoWidth;
        navTransform = CGAffineTransformIdentity;
        videoOverlaysAlpha = 1.f;
    } else {
        newWidth = _fullscreenVideoWidth;
        navTransform = CGAffineTransformMakeScale(0.8, 0.8);
        videoOverlaysAlpha = 0.f;
    }
    
    [UIView animateWithDuration:.75 delay:0 usingSpringWithDamping:.75 initialSpringVelocity:7.f options:UIViewAnimationCurveEaseIn animations:^{
        
        self.navigationViewContainer.transform = navTransform;
        self.currentlyOnViewContainer.transform = navTransform;
        self.videoReelWidthConstraint.constant = newWidth;
        self.videoReelVC.videoControlsVC.view.alpha = videoOverlaysAlpha;
        self.videoReelVC.videoOverlayView.alpha = videoOverlaysAlpha;
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
        self.sideNavigationVC.currentUser = self.currentUser;
        self.sideNavigationVC.videoReelVC = self.videoReelVC;
        self.sideNavigationVC.masterDelegate = self.topNavigationDelegate;
    }
}

- (void)pushViewController:(UIViewController *)viewController
{
    [self.sideNavigationVC pushViewController:viewController];
}

@end
