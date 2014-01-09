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

//View Controllers
@property (nonatomic, strong) ShelbyVideoReelViewController *videoReelVC;
@property (nonatomic, strong) ShelbyNavigationViewController *sideNavigation;
@end

@implementation ShelbyTopContainerViewController {
    CGRect _fullscreenVideoFrame, _smallscreenVideoFrame;
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
	// Do any additional setup after loading the view.
    
    _fullscreenVideoFrame = CGRectMake(0, 0, 1024, 768);
    _smallscreenVideoFrame = self.videoReelViewContainer.frame;
    
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
    CGRect newFrame;
    if ([self isVideoFullscreen]) {
        newFrame = _smallscreenVideoFrame;
    } else {
        newFrame = _fullscreenVideoFrame;
    }

    [UIView animateWithDuration:.5 delay:0 usingSpringWithDamping:.8 initialSpringVelocity:12.f options:UIViewAnimationOptionCurveEaseIn animations:^{
        self.videoReelViewContainer.frame = newFrame;
    } completion:nil];
}

- (BOOL)isVideoFullscreen
{
    return CGRectEqualToRect(self.videoReelViewContainer.frame, _fullscreenVideoFrame);
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

@end
