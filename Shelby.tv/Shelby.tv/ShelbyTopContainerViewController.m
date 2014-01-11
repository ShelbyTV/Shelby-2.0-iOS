//
//  ShelbyTopContainerViewController.m
//  Shelby.tv
//
//  Created by Keren on 1/8/14.
//  Copyright (c) 2014 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyTopContainerViewController.h"
#import "ShelbyNavigationViewController.h"
#import "ShelbyVideoReelViewController.h"

@interface ShelbyTopContainerViewController ()
//container Views
@property (weak, nonatomic) IBOutlet UIView *navigationViewContainer;
@property (weak, nonatomic) IBOutlet UIView *currentlyPlayingViewContainer;
@property (weak, nonatomic) IBOutlet UIView *videoReelViewContainer;

//constraints
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *videoReelWidthConstraint;

//View Controllers
@property (nonatomic, strong) ShelbyVideoReelViewController *videoReelVC;
@property (nonatomic, strong) ShelbyNavigationViewController *sideNavigation;
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
    
    //Uncomment for some fun layout testing
//    [NSTimer scheduledTimerWithTimeInterval:3.0f target:self selector:@selector(toggleFullscreenVideo) userInfo:nil repeats:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)toggleFullscreenVideo
{
    CGFloat newWidth;
    CGAffineTransform navTransform;
    if ([self isVideoFullscreen]) {
        newWidth = _smallscreenVideoWidth;
        navTransform = CGAffineTransformIdentity;
    } else {
        newWidth = _fullscreenVideoWidth;
        navTransform = CGAffineTransformMakeScale(0.8, 0.8);
    }
    
    [UIView animateWithDuration:.75 delay:0 usingSpringWithDamping:.8 initialSpringVelocity:12.f options:UIViewAnimationCurveEaseIn animations:^{
        
        self.navigationViewContainer.transform = navTransform;
        self.currentlyPlayingViewContainer.transform = navTransform;
        self.videoReelWidthConstraint.constant = newWidth;
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
        self.sideNavigation = segue.destinationViewController;
    } else if ([segueIdentifier isEqualToString:@"VideoReel"]) {
        self.videoReelVC = segue.destinationViewController;
    } else if ([segueIdentifier isEqualToString:@"NowPlaying"]) {
        // TODO
    }
    
    if (self.sideNavigation && self.videoReelVC) {
        self.sideNavigation.currentUser = self.currentUser;
        self.sideNavigation.videoReelVC = self.videoReelVC;
    }
}

- (void)pushViewController:(UIViewController *)viewController
{
    [self.sideNavigation pushViewController:viewController];
}

- (void)setupTopLevelNavigationDelegate:(id<ShelbyNavigationProtocol>)delegate
{
    self.sideNavigation.masterDelegate = delegate;
}
@end
