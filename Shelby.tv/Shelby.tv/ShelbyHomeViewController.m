//
//  ShelbyHomeViewController.m
//  Shelby.tv
//
//  Created by Keren on 5/1/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyHomeViewController.h"
#import "BrowseViewController.h"
#import "DisplayChannel.h"
#import "SPVideoReel.h"
#import "User+Helper.h"
#import "ImageUtilities.h"

@interface ShelbyHomeViewController ()
@property (nonatomic, weak) IBOutlet UIView *topBar;

@property (nonatomic, strong) UIView *settingsView;
@property (nonatomic, strong) BrowseViewController *browseVC;
@property (nonatomic, strong) SPVideoReel *videoReel;
@property (nonatomic, assign) BOOL animationInProgress;

@end

@implementation ShelbyHomeViewController

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

    [self.topBar setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"topbar.png"]]];

    BrowseViewController *browseViewController = [[BrowseViewController alloc] initWithNibName:@"BrowseView" bundle:nil];

    [self setBrowseVC:browseViewController];
    [self addChildViewController:browseViewController];
    [browseViewController.view setFrame:CGRectMake(0, 44, browseViewController.view.frame.size.width, browseViewController.view.frame.size.height)];

    [self.view addSubview:browseViewController.view];
    
    [browseViewController didMoveToParentViewController:self];
    
    [self setupSettingsView];
    
    [self.view bringSubviewToFront:self.channelsLoadingActivityIndicator];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)setChannels:(NSArray *)channels
{
    _channels = channels;
    self.browseVC.channels = channels;
}

- (void)setEntries:(NSArray *)channelEntries forChannel:(DisplayChannel *)channel
{
    [self.browseVC setEntries:channelEntries forChannel:channel];
}

- (NSInteger)indexOfItem:(id)item inChannel:(DisplayChannel *)channel
{
    NSArray *entries = [self entriesForChannel:channel];
    return [entries indexOfObject:item];
}

- (void)addEntries:(NSArray *)newChannelEntries toEnd:(BOOL)shouldAppend ofChannel:(DisplayChannel *)channel
{
    [self.browseVC addEntries:newChannelEntries toEnd:shouldAppend ofChannel:channel];
}

- (NSArray *)entriesForChannel:(DisplayChannel *)channel
{
    return [self.browseVC entriesForChannel:channel];
}

- (void)refreshActivityIndicatorForChannel:(DisplayChannel *)channel shouldAnimate:(BOOL)shouldAnimate
{
    [self.browseVC refreshActivityIndicatorForChannel:channel shouldAnimate:shouldAnimate];
}

- (void)setBrowseAndVideoReelDelegate:(id)browseAndVideoReelDelegate
{
    _browseAndVideoReelDelegate = browseAndVideoReelDelegate;
    self.browseVC.browseDelegate = browseAndVideoReelDelegate;
}

- (void)setCurrentUser:(User *)currentUser
{
    _currentUser = nil;//currentUser;
    // KP KP: TODO: need to have fetch user return the logged in user or nil.
//    [self setupSettingsView];
}

// KP KP: TODO: maybe create a special UserAvatarView, pass a target to it.
- (void)setupSettingsView
{
    // KP KP: TODO: once fetching user done correctly, add the two targets. 
    [self.settingsView removeFromSuperview];
    if (self.currentUser) {
        _settingsView = [[UIView alloc] initWithFrame:CGRectMake(950, 0, 60, 44)];
        UIImageView *userAvatar = [[UIImageView alloc] initWithFrame:CGRectMake(25, 7, 30, 30)];
        [userAvatar.layer setCornerRadius:5];
        [userAvatar.layer setMasksToBounds:YES];
        [AsynchronousFreeloader loadImageFromLink:self.currentUser.userImage
                                     forImageView:userAvatar
                                  withPlaceholder:nil
                                   andContentMode:UIViewContentModeScaleAspectFit];
        [self.settingsView addSubview:userAvatar];
        UIButton *settings = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 60, 44)];
//        [settings addTarget:self action:@selector(showSettings) forControlEvents:UIControlEventTouchUpInside];
        [self.settingsView addSubview:settings];
    } else {
        _settingsView = [[UIView alloc] initWithFrame:CGRectMake(950, 0, 120, 44)];
        UIButton *login = [UIButton buttonWithType:UIButtonTypeCustom];
        [login setFrame:CGRectMake(7, 7, 60, 30)];
        [login setBackgroundImage:[UIImage imageNamed:@"login.png"] forState:UIControlStateNormal];
        [login setTitle:@"Login" forState:UIControlStateNormal];
        [[login titleLabel] setFont:[UIFont fontWithName:@"HelveticaNeue-Bold" size:14]];
        [[login titleLabel] setTextColor:[UIColor whiteColor]];
//        [login addTarget:self action:@selector(login) forControlEvents:UIControlEventTouchUpInside];
        [self.settingsView addSubview:login];
    }
    
    [self.view addSubview:self.settingsView];
}

- (void)launchPlayerForChannel:(DisplayChannel *)channel atIndex:(NSInteger)index
{
    [self initializeVideoReelWithChannel:channel atIndex:index];
    [self presentViewController:self.videoReel animated:NO completion:nil];
}

- (void)dismissPlayer
{
    [self.videoReel dismissViewControllerAnimated:NO completion:nil];
    self.videoReel = nil;
}

- (void)animateLaunchPlayerForChannel:(DisplayChannel *)channel atIndex:(NSInteger)index
{
    [self initializeVideoReelWithChannel:channel atIndex:index];
    [self animateOpenChannels:channel];
}

- (void)animateDismissPlayerForChannel:(DisplayChannel *)channel
{
    [self animateCloseChannels:channel];
}


#pragma mark - ShelbyHome Private methods
- (void)animateOpenChannels:(DisplayChannel *)channel 
{
    if (self.animationInProgress) {
        return;
    } else {
        [self setAnimationInProgress:YES];
    }
    
    ShelbyHideBrowseAnimationViews *animationViews = [self.browseVC animationViewForOpeningChannel:channel];
    
    CGFloat topBarHeight = self.topBar.frame.size.height;
    animationViews.topView.frame = CGRectMake(animationViews.topView.frame.origin.x, animationViews.topView.frame.origin.y + topBarHeight, animationViews.topView.frame.size.width, animationViews.topView.frame.size.height);
    animationViews.centerView.frame = CGRectMake(animationViews.centerView.frame.origin.x, animationViews.centerView.frame.origin.y + topBarHeight, animationViews.centerView.frame.size.width, animationViews.centerView.frame.size.height);
    animationViews.bottomView.frame = CGRectMake(animationViews.bottomView.frame.origin.x, animationViews.bottomView.frame.origin.y + topBarHeight, animationViews.bottomView.frame.size.width, animationViews.bottomView.frame.size.height);
    
    
    [self.videoReel.view addSubview:animationViews.centerView];
    [self.videoReel.view addSubview:animationViews.bottomView];
    [self.videoReel.view addSubview:animationViews.topView];
    
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarStyleBlackTranslucent];
    
    [self presentViewController:self.videoReel animated:NO completion:^{
        [UIView animateWithDuration:1 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            [animationViews.centerView setFrame:animationViews.finalCenterFrame];
            [animationViews.centerView setAlpha:0];
            [animationViews.topView setFrame:animationViews.finalTopFrame];
            [animationViews.bottomView setFrame:animationViews.finalBottomFrame];
        } completion:^(BOOL finished) {
            [animationViews.centerView removeFromSuperview];
            [animationViews.bottomView removeFromSuperview];
            [animationViews.topView removeFromSuperview];
            
            // KP KP: TODO: send a message to brain that it can start accepting new events
            [self setAnimationInProgress:NO];
        }];
    }];
}

- (void)animateCloseChannels:(DisplayChannel *)channel
{
    if (self.animationInProgress) {
        return;
    } else {
        [self setAnimationInProgress:YES];
    }

    ShelbyHideBrowseAnimationViews *animationViews = [self.browseVC animationViewForClosingChannel:channel];
 
    [self.videoReel.view addSubview:animationViews.centerView];
    [self.videoReel.view addSubview:animationViews.bottomView];
    [self.videoReel.view addSubview:animationViews.topView];
    
    [self.videoReel.view bringSubviewToFront:animationViews.centerView];
    [self.videoReel.view bringSubviewToFront:animationViews.bottomView];
    [self.videoReel.view bringSubviewToFront:animationViews.topView];
    
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarStyleBlackTranslucent];
    [animationViews.centerView setAlpha:0];
    
    CGFloat topBarHeight = self.topBar.frame.size.height;
    CGRect finalTopFrame = CGRectMake(animationViews.finalTopFrame.origin.x, animationViews.finalTopFrame.origin.y + topBarHeight, animationViews.finalTopFrame.size.width, animationViews.finalTopFrame.size.height);
    CGRect finalCenterFrame = CGRectMake(animationViews.finalCenterFrame.origin.x, animationViews.finalCenterFrame.origin.y + topBarHeight, animationViews.finalCenterFrame.size.width, animationViews.finalCenterFrame.size.height);
    CGRect finalBottomFrame = CGRectMake(animationViews.finalBottomFrame.origin.x, animationViews.finalBottomFrame.origin.y + topBarHeight, animationViews.finalBottomFrame.size.width, animationViews.finalBottomFrame.size.height);
    
    [self.topBar setAlpha:0];
    [self.videoReel hideOverlayView];
    [UIView animateWithDuration:0.45 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        [animationViews.centerView setFrame:finalCenterFrame];
        [animationViews.centerView setAlpha:1];
        [animationViews.topView setFrame:finalTopFrame];
        [animationViews.bottomView setFrame:finalBottomFrame];
    } completion:^(BOOL finished) {
        [self.videoReel dismissViewControllerAnimated:NO completion:^{
            [UIView animateWithDuration:0.5 animations:^{
                [self.topBar setAlpha:1];
            }];
        }];
        [self setAnimationInProgress:NO];
    }];
}

- (void)initializeVideoReelWithChannel:(DisplayChannel *)channel atIndex:(NSInteger)index
{
    _videoReel = [[SPVideoReel alloc] initWithVideoFrames:[self entriesForChannel:channel] atIndex:index];
    self.videoReel.delegate = self.browseAndVideoReelDelegate;
}

@end
