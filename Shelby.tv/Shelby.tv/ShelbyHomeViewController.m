//
//  ShelbyHomeViewController.m
//  Shelby.tv
//
//  Created by Keren on 5/1/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyHomeViewController.h"
#import "Appirater.h"
#import "DashboardEntry+Helper.h"
#import "DisplayChannel.h"
#import "ImageUtilities.h"
#import "Roll+Helper.h"
#import "SettingsViewController.h"
#import "SPVideoReel.h"
#import "User+Helper.h"

@interface ShelbyHomeViewController () {
    SettingsViewController *_settingsVC;
    UIViewController *_currentFullScreenVC;
}
@property (nonatomic, strong) ShelbyNavBarViewController *navBarVC;
@property (nonatomic, weak) UIView *navBar;
@property (nonatomic, strong) UIView *navBarButtonView;

@property (nonatomic, strong) NSMutableArray *streamBrowseVCs;
@property (nonatomic, strong) ShelbyStreamBrowseViewController *currentStreamBrowseVC;
@property (nonatomic, strong) SPVideoReel *videoReel;
@property (nonatomic, assign) BOOL animationInProgress;

@property (nonatomic, strong) VideoControlsViewController *videoControlsVC;


#define OVERLAY_ANIMATION_DURATION 0.2
#define NAV_BUTTON_FADE_TIME 0.1
#define AUTOADVANCE_INFO_PEEK_DURATION 5.0

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

    // Setting background color to avoid seeing the phone's background
    self.view.backgroundColor = [UIColor blackColor];
    

//    if (DEVICE_IPAD) {
//        BrowseViewController *browseViewController = [[BrowseViewController alloc] initWithNibName:@"BrowseView" bundle:nil];
//
//        [self setBrowseVC:browseViewController];
//        [self addChildViewController:browseViewController];
//        [browseViewController.view setFrame:CGRectMake(0, 44, browseViewController.view.frame.size.width, browseViewController.view.frame.size.height)];
//
//        [self.view addSubview:browseViewController.view];
//    
//        [browseViewController didMoveToParentViewController:self];
//    } else {
    
    /* Order of views:
     * On top of everything, navBar.
     * Just below navBar: videoControls.
     * Everything else gets added below the video controls (ie. streamBrowseVC, videoReel)
     */
    [self setupNavBarView];
    [self setupVideoControlsView];
    [self showNavBarButton];
//    }
    
    [self.view bringSubviewToFront:self.channelsLoadingActivityIndicator];
}

- (void)setupNavBarView
{
    self.navBarVC = [[ShelbyNavBarViewController alloc] initWithNibName:@"ShelbyNavBarView" bundle:nil];
    self.navBarVC.delegate = self;
    [self.navBarVC willMoveToParentViewController:self];
    [self addChildViewController:self.navBarVC];
    self.navBar = self.navBarVC.view;
    [self.view addSubview:self.navBar];
    self.navBar.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[navBar]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:@{@"navBar":self.navBar}]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[navBar]"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:@{@"navBar":self.navBar}]];
    [self.navBarVC didMoveToParentViewController:self];

    self.navBarVC.currentUser = self.currentUser;

    //pre-navigate w/o animation for a prettier launch
    if (self.currentUser) {
        [self.navBarVC didNavigateToUsersStream];
    } else {
        [self.navBarVC didNavigateToCommunityChannel];
    }
}

- (void)setupVideoControlsView
{
    _videoControlsVC = [[VideoControlsViewController alloc] initWithNibName:@"VideoControlsView" bundle:nil];
    _videoControlsVC.delegate = self;
    [_videoControlsVC willMoveToParentViewController:self];
    [_videoControlsVC.view setFrame:CGRectMake(0, kShelbyFullscreenHeight - self.videoControlsVC.view.frame.size.height, _videoControlsVC.view.frame.size.width, _videoControlsVC.view.frame.size.height)];
    [self.view insertSubview:_videoControlsVC.view belowSubview:self.navBar];
    _videoControlsVC.view.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[controls]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:@{@"controls":_videoControlsVC.view}]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[controls(88)]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:@{@"controls":_videoControlsVC.view}]];
    [self addChildViewController:_videoControlsVC];
    [_videoControlsVC didMoveToParentViewController:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (NSUInteger)supportedInterfaceOrientations
{
//    if (DEVICE_IPAD) {
//        return UIInterfaceOrientationMaskLandscape;
//    } else {
    return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskLandscape;
//    }
}

-(BOOL) shouldAutorotate {
    return YES;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];

    //after rotation, we're always showing a full page, controls should not be faded at all
    [self fadeVideoControlsForOffset:CGPointMake(0, 0) frameHeight:self.view.frame.size.height];
}


// We assume these are all of our channels, in the correct order (which we cared about on old iPad design)
- (void)setChannels:(NSArray *)channels
{
    if (![channels isEqualToArray:_channels]) {
        //DLog(@"Replacing ALL Channels... %@ --becomes--> %@", _channels, channels);
        _channels = channels;
//        if (DEVICE_IPAD) {
//            self.browseVC.channels = channels;
//            
//        } else {
        //find or create new ShelbyStreamBrowseViewControllers for this array of channels
        NSMutableArray *newStreamBrowseVCs = [@[] mutableCopy];
        for (DisplayChannel *ch in channels) {
            ShelbyStreamBrowseViewController *sbvc = [self streamBrowseViewControllerForChannel:ch];
            if (!sbvc) {
                sbvc = [[ShelbyStreamBrowseViewController alloc] initWithNibName:@"ShelbyStreamBrowseView" bundle:nil];
                [sbvc setEntries:nil forChannel:ch];
                sbvc.browseManagementDelegate = self.masterDelegate;
                //we want to know about scroll events to keep SPVideoReel in sync, when applicable
                sbvc.browseViewDelegate = self;
                sbvc.collectionView.scrollIndicatorInsets = UIEdgeInsetsMake(44, 0, 0, 0);
            }
            [newStreamBrowseVCs addObject:sbvc];
        }
        
        _streamBrowseVCs = newStreamBrowseVCs;
//        }
    }
}

- (void)removeChannel:(DisplayChannel *)channel
{    
    NSMutableArray *lessChannels = [_channels mutableCopy];
    [lessChannels removeObject:channel];
    _channels = lessChannels;
//    if (DEVICE_IPAD) {
//        self.browseVC.channels = _channels;
//    } else {
    ShelbyStreamBrowseViewController *sbvc = [self streamBrowseViewControllerForChannel:channel];
    if (sbvc) {
        if (sbvc.view.superview) {
            [sbvc.view removeFromSuperview];
            [sbvc removeFromParentViewController];
        }
        [_streamBrowseVCs removeObject:sbvc];
    }
//    }
}

//assumes navigation is otherwise correctly set
- (void)focusOnChannel:(DisplayChannel *)channel
{
//    if (DEVICE_IPAD) {
//        //do nothing
//    } else {
//
    ShelbyStreamBrowseViewController *sbvc = [self streamBrowseViewControllerForChannel:channel];
    STVAssert(sbvc, @"should not be asked to focus on a channel we don't have");
    if (sbvc == _currentFullScreenVC) {
        //not changing, nothing to do
        return;
    }

    //our frame NEVER changes b/c we're the root view controller... we just get a 90 deg rotation transform
    //but our bounds reflects this, so we use bounds to set frame on our children...
    sbvc.view.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);

    [self swapOutViewController:_currentFullScreenVC forViewController:sbvc completion:^(BOOL finished) {
        self.currentStreamBrowseVC = sbvc;
        self.videoControlsVC.currentEntity = [self.currentStreamBrowseVC entityForCurrentFocus];
        // If there is no content in Stream, don't show video controls
        self.videoControlsVC.view.hidden = sbvc.hasNoContent;

        [self dismissSettings];
    }];
}

- (void)swapOutViewController:(UIViewController *)oldVC forViewController:(UIViewController *)newVC completion:(void (^)(BOOL finished))completion
{
    [oldVC willMoveToParentViewController:nil];
    [self addChildViewController:newVC];
    [self.view insertSubview:newVC.view belowSubview:self.videoControlsVC.view];

    CGAffineTransform scaleAndTranslateIntoNav = CGAffineTransformConcat(CGAffineTransformMakeScale(.2f, .2f), CGAffineTransformMakeTranslation(0, -self.view.bounds.size.height));
    newVC.view.transform = scaleAndTranslateIntoNav;
    newVC.view.alpha = 1.f;
    [UIView transitionWithView:self.view duration:0.5 options:(UIViewAnimationOptionAllowAnimatedContent | UIViewAnimationOptionCurveEaseOut) animations:^{
        oldVC.view.transform = scaleAndTranslateIntoNav;
        oldVC.view.alpha = 0.f;
        newVC.view.transform = CGAffineTransformIdentity;
        newVC.view.alpha = 1.f;

    } completion:^(BOOL finished) {
        [oldVC removeFromParentViewController];
        [oldVC.view removeFromSuperview];
        oldVC.view.transform = CGAffineTransformIdentity;
        [newVC didMoveToParentViewController:self];
        _currentFullScreenVC = newVC;
        completion(finished);
    }];
}

- (void)focusOnEntity:(id<ShelbyVideoContainer>)entity inChannel:(DisplayChannel *)channel
{
//    if (DEVICE_IPAD) {
        //When we implement new iPad interface, may want to update our persistent stream view here
//    } else {
    [[self streamBrowseViewControllerForChannel:channel] focusOnEntity:entity inChannel:channel];
    self.videoControlsVC.currentEntity = entity;
//    }
}

- (void)setEntries:(NSArray *)channelEntries forChannel:(DisplayChannel *)channel
{
//    if (DEVICE_IPAD) {
//        [self.browseVC setEntries:channelEntries forChannel:channel];
//    } else {
    ShelbyStreamBrowseViewController *sbvc = [self streamBrowseViewControllerForChannel:channel];
    STVAssert(sbvc, @"expected to set entries for a VC we have");
    [sbvc setEntries:channelEntries forChannel:channel];
    if (!self.videoControlsVC.currentEntity && self.currentStreamBrowseVC.channel == channel && [channelEntries count]) {
        //we're bootstrapping, update the video controls for the 0th entity
        self.videoControlsVC.currentEntity = [self.currentStreamBrowseVC deduplicatedEntriesForChannel:channel][0];
    }
//    }
}

- (ShelbyStreamBrowseViewController *)streamBrowseViewControllerForChannel:(DisplayChannel *)channel
{
    for (ShelbyStreamBrowseViewController *sbvc in _streamBrowseVCs) {
        if (sbvc.channel == channel) {
            return sbvc;
        }
    }
    return nil;
}

- (NSInteger)indexOfDisplayedEntry:(id)entry inChannel:(DisplayChannel *)channel
{
    NSArray *dedupdEntries = [self deduplicatedEntriesForChannel:channel];
    return [dedupdEntries indexOfObject:entry];
}

- (void)addEntries:(NSArray *)newChannelEntries toEnd:(BOOL)shouldAppend ofChannel:(DisplayChannel *)channel
{
//    if (DEVICE_IPAD) {
//        [self.browseVC addEntries:newChannelEntries toEnd:shouldAppend ofChannel:channel];
//    } else {
    BOOL playingThisChannel = (self.videoReel && self.videoReel.channel == channel);

    ShelbyStreamBrowseViewController *sbvc = [self streamBrowseViewControllerForChannel:channel];
    [sbvc addEntries:newChannelEntries toEnd:shouldAppend ofChannel:channel maintainingCurrentFocus:playingThisChannel];
//    }

    if (playingThisChannel) {
        [self.videoReel setDeduplicatedEntries:sbvc.deduplicatedEntries];
    }
}

- (void)fetchDidCompleteForChannel:(DisplayChannel *)channel
{
    // This was used for BrowseViewController when we had channels
}

- (NSArray *)entriesForChannel:(DisplayChannel *)channel
{
    return [[self streamBrowseViewControllerForChannel:channel] entriesForChannel:channel];
}

- (NSArray *)deduplicatedEntriesForChannel:(DisplayChannel *)channel
{
//    if (DEVICE_IPAD) {
//        return [self.browseVC deduplicatedEntriesForChannel:channel];
//    } else {
    return [[self streamBrowseViewControllerForChannel:channel] deduplicatedEntriesForChannel:channel];
//    }
}

- (void)refreshActivityIndicatorForChannel:(DisplayChannel *)channel shouldAnimate:(BOOL)shouldAnimate
{
//    if (DEVICE_IPAD) {
//        [self.browseVC refreshActivityIndicatorForChannel:channel shouldAnimate:shouldAnimate];
//    } else {
    [[self streamBrowseViewControllerForChannel:channel] refreshActivityIndicatorShouldAnimate:shouldAnimate];
//    }
}

- (void)loadMoreActivityIndicatorForChannel:(DisplayChannel *)channel shouldAnimate:(BOOL)shouldAnimate
{
//    if (DEVICE_IPAD) {
//        [self.browseVC loadMoreActivityIndicatorForChannel:channel shouldAnimate:shouldAnimate];
//    } else {
        // not currently showing a loadMore activity indicator
        //[[self streamBrowseViewControllerForChannel:channel] loadMoreActivityIndicatorShouldAnimate:shouldAnimate];
//    }
}

- (void)setMasterDelegate:(id)masterDelegate
{
    _masterDelegate = masterDelegate;
//    if (DEVICE_IPAD) {
//        self.browseVC.browseDelegate = masterDelegate;
//    } else {
    for (ShelbyStreamBrowseViewController *sbvc in self.streamBrowseVCs) {
        sbvc.browseManagementDelegate = masterDelegate;
    }
//    }
}

- (void)setCurrentUser:(User *)currentUser
{
    _currentUser = currentUser;

    if (_currentUser) {
        [self.navBarButtonView removeFromSuperview];
        self.navBarButtonView = nil;
    } else {
        [self showNavBarButton];
    }
    
    // If there is SettingsVC, make sure the user is updated
    if (_settingsVC) {
        _settingsVC.user = currentUser;
    }

    self.navBarVC.currentUser = currentUser;
}

- (void)showNavBarButton
{
    if (!self.navBarVC) {
        //views aren't set up yet...
        return;
    }

    if (self.navBarButtonView) {
        [UIView animateWithDuration:NAV_BUTTON_FADE_TIME animations:^{
            self.navBarButtonView.alpha = 1.0;
        }];
    } else if (!self.currentUser) {
        self.navBarButtonView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 86, 44)];
        UIButton *login = [UIButton buttonWithType:UIButtonTypeCustom];
        [login setFrame:CGRectMake(6, 0, 80, 44)];
        [login setTitle:@"SIGN UP" forState:UIControlStateNormal];
        [[login titleLabel] setFont:kShelbyFontH4Bold];
        [login setTitleColor:kShelbyColorGreen forState:UIControlStateNormal];
        [login addTarget:self action:@selector(navBarButtonTapped) forControlEvents:UIControlEventTouchUpInside];
        [self.navBarButtonView addSubview:login];
        
        [self.navBar addSubview:self.navBarButtonView];
        [self.navBarButtonView setAutoresizingMask:UIViewAutoresizingFlexibleRightMargin];
    }
}

- (void)hideNavBarButton
{
    [UIView animateWithDuration:NAV_BUTTON_FADE_TIME animations:^{
        self.navBarButtonView.alpha = 0.0;
    }];
}

- (void)navBarButtonTapped
{
    [ShelbyHomeViewController sendEventWithCategory:kAnalyticsCategoryPrimaryUX
                                         withAction:kAnalyticsUXTapNavBarButton
                                withNicknameAsLabel:YES];
    [self dismissVideoReel];
    [self.masterDelegate presentUserSignup];
}

- (void)playChannel:(DisplayChannel *)channel atIndex:(NSInteger)index
{
    if (self.videoReel) {
        STVAssert(self.videoReel.channel == channel, @"videoReel should have been shutdown or changed when channel was changed");
//        if (DEVICE_IPAD) {
//            //TODO
//            DLog(@"TODO: handle resume video reel for iPad");
//        } else {
        [self.videoReel playCurrentPlayer];
//        }
    } else {
        [self prepareToShowVideoReel];
        [self initializeVideoReelWithChannel:channel atIndex:index];

//        if (DEVICE_IPAD) {
//            //TODO
//            DLog(@"TODO: handle play channel for iPad");
//        } else {
        [self.videoReel willMoveToParentViewController:self];
        [self addChildViewController:self.videoReel];
        [self.view insertSubview:self.videoReel.view belowSubview:self.currentStreamBrowseVC.view];
        [self.videoReel didMoveToParentViewController:self];
        self.videoReel.view.frame = self.currentStreamBrowseVC.view.frame;
        //entering playback: hide the overlays and update controls state
        [UIView animateWithDuration:OVERLAY_ANIMATION_DURATION animations:^{
            self.navBar.alpha = 0.0;
            self.videoControlsVC.view.alpha = 0.0;
            [self streamBrowseViewControllerForChannel:self.videoReel.channel].viewMode = ShelbyStreamBrowseViewForPlaybackWithoutOverlay;
        } completion:^(BOOL finished) {
            [self updateVideoControlsForPage:self.currentStreamBrowseVC.currentPage];
        }];
//        }
    }
}

- (void)prepareToShowVideoReel
{
    // prevent display from sleeping while watching video
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    
//    if (DEVICE_IPAD) {
//        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
//    }
}

- (void)dismissVideoReel
{
    [self.videoReel pauseCurrentPlayer];
    
    [self streamBrowseViewControllerForChannel:self.videoReel.channel].viewMode = ShelbyStreamBrowseViewDefault;
    
    [self.videoReel shutdown];
    [self.videoReel.view removeFromSuperview];
    [self.videoReel removeFromParentViewController];
    self.videoReel = nil;

    //video controls are different w/ and w/o videoReel
    [self updateVideoControlsForPage:self.currentStreamBrowseVC.currentPage];
    
    // The opposite of what we do in: launchPlayerSetup
//    if (DEVICE_IPAD) {
//        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
//    }

    // allow display to sleep
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
}

//DEPRECATED
- (void)animateLaunchPlayerForChannel:(DisplayChannel *)channel atIndex:(NSInteger)index
{
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    
    [self initializeVideoReelWithChannel:channel atIndex:index];
    [self animateOpenChannels:channel];
}

//DEPRECATED
- (void)animateDismissPlayerForChannel:(DisplayChannel *)channel atFrame:(Frame *)videoFrame
{
    [self animateCloseChannels:channel atFrame:videoFrame];
}


#pragma mark - ShelbyHome Private methods

//DEPRECATED
- (void)animateOpenChannels:(DisplayChannel *)channel 
{
//    if (self.animationInProgress) {
//        return;
//    } else {
//        [self setAnimationInProgress:YES];
//    }
//    
//    ShelbyHideBrowseAnimationViews *animationViews = [self.browseVC animationViewForOpeningChannel:channel];
//    
//    CGFloat topBarHeight = self.topBar.frame.size.height;
//    animationViews.topView.frame = CGRectMake(animationViews.topView.frame.origin.x, animationViews.topView.frame.origin.y + topBarHeight, animationViews.topView.frame.size.width, animationViews.topView.frame.size.height);
//    animationViews.centerView.frame = CGRectMake(animationViews.centerView.frame.origin.x, animationViews.centerView.frame.origin.y + topBarHeight, animationViews.centerView.frame.size.width, animationViews.centerView.frame.size.height);
//    animationViews.bottomView.frame = CGRectMake(animationViews.bottomView.frame.origin.x, animationViews.bottomView.frame.origin.y + topBarHeight, animationViews.bottomView.frame.size.width, animationViews.bottomView.frame.size.height);
//    
//    
//    [self.videoReel.view addSubview:animationViews.centerView];
//    [self.videoReel.view addSubview:animationViews.bottomView];
//    [self.videoReel.view addSubview:animationViews.topView];
//
//    [self prepareToShowVideoReel];
//    
//    [self presentViewController:self.videoReel animated:NO completion:^{
//        [UIView animateWithDuration:1 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
//            [animationViews.centerView setFrame:animationViews.finalCenterFrame];
//            [animationViews.centerView setAlpha:0];
//            [animationViews.topView setFrame:animationViews.finalTopFrame];
//            [animationViews.bottomView setFrame:animationViews.finalBottomFrame];
//        } completion:^(BOOL finished) {
//            [animationViews.centerView removeFromSuperview];
//            [animationViews.bottomView removeFromSuperview];
//            [animationViews.topView removeFromSuperview];
//            
//            // KP KP: TODO: send a message to brain that it can start accepting new events
//            [self setAnimationInProgress:NO];
//        }];
//    }];
}

//DEPRECATED
- (void)animateCloseChannels:(DisplayChannel *)channel atFrame:(Frame *)frame
{
//    if (self.animationInProgress) {
//        return;
//    } else {
//        [self setAnimationInProgress:YES];
//    }
//
//    [self.browseVC highlightFrame:frame atChannel:channel];
//    
//    ShelbyHideBrowseAnimationViews *animationViews = [self.browseVC animationViewForClosingChannel:channel];
// 
//    [self.videoReel.view addSubview:animationViews.centerView];
//    [self.videoReel.view addSubview:animationViews.bottomView];
//    [self.videoReel.view addSubview:animationViews.topView];
//    
//    [self.videoReel.view bringSubviewToFront:animationViews.centerView];
//    [self.videoReel.view bringSubviewToFront:animationViews.bottomView];
//    [self.videoReel.view bringSubviewToFront:animationViews.topView];
//    
//    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarStyleBlackTranslucent];
//    [animationViews.centerView setAlpha:0];
//    
//    CGFloat topBarHeight = self.topBar.frame.size.height;
//    CGRect finalTopFrame = CGRectMake(animationViews.finalTopFrame.origin.x, animationViews.finalTopFrame.origin.y + topBarHeight, animationViews.finalTopFrame.size.width, animationViews.finalTopFrame.size.height);
//    CGRect finalCenterFrame = CGRectMake(animationViews.finalCenterFrame.origin.x, animationViews.finalCenterFrame.origin.y + topBarHeight, animationViews.finalCenterFrame.size.width, animationViews.finalCenterFrame.size.height);
//    CGRect finalBottomFrame = CGRectMake(animationViews.finalBottomFrame.origin.x, animationViews.finalBottomFrame.origin.y + topBarHeight, animationViews.finalBottomFrame.size.width, animationViews.finalBottomFrame.size.height);
//    
//    [self.topBar setAlpha:0];
//
//    [UIView animateWithDuration:0.45 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
//        [animationViews.centerView setFrame:finalCenterFrame];
//        [animationViews.centerView setAlpha:1];
//        [animationViews.topView setFrame:finalTopFrame];
//        [animationViews.bottomView setFrame:finalBottomFrame];
//    } completion:^(BOOL finished) {
//        [self.videoReel dismissViewControllerAnimated:NO completion:^{
//            [UIView animateWithDuration:0.5 animations:^{
//                [self.topBar setAlpha:1];
//            }];
//            [self.videoReel shutdown];
//            self.videoReel = nil;
//        }];
//        [self setAnimationInProgress:NO];
//    }];
}

- (void)initializeVideoReelWithChannel:(DisplayChannel *)channel atIndex:(NSInteger)index
{
    STVAssert(!_videoReel, @"expected video reel to be shutdown and nil before initializing a new one");
    
    _videoReel = [[SPVideoReel alloc] initWithChannel:channel
                                     andVideoEntities:[self deduplicatedEntriesForChannel:channel]
                                              atIndex:index];
    self.videoReel.delegate = self.masterDelegate;
    self.videoReel.videoPlaybackDelegate = self.videoControlsVC;
    self.videoReel.airPlayView = self.videoControlsVC.airPlayView;
}

- (void)videoDidAutoadvance
{
    [self doPeekAndHide];
}

- (void)doPeekAndHide
{
    if (self.currentStreamBrowseVC.viewMode == ShelbyStreamBrowseViewForPlaybackWithoutOverlay) {
        //peek basic video info (this is called exactly when the scroll animation to change videos ends)
        [UIView animateWithDuration:OVERLAY_ANIMATION_DURATION*3 animations:^{
            self.currentStreamBrowseVC.viewMode = ShelbyStreamBrowseViewForPlaybackPeeking;
        }];

        //and hide it
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(AUTOADVANCE_INFO_PEEK_DURATION * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            //but make sure user didn't tap and go into regular overlay mode
            if (self.currentStreamBrowseVC.viewMode == ShelbyStreamBrowseViewForPlaybackPeeking) {
                [UIView animateWithDuration:OVERLAY_ANIMATION_DURATION animations:^{
                    self.currentStreamBrowseVC.viewMode = ShelbyStreamBrowseViewForPlaybackWithoutOverlay;
                    self.navBar.alpha = 0.0;
                    self.videoControlsVC.view.alpha = 0.0;
                }];
            }
        });
    }
}

- (void)didNavigateToCommunityChannel
{
    [self.navBarVC didNavigateToCommunityChannel];
}

- (void)didNavigateToUsersStream
{
    [self.navBarVC didNavigateToUsersStream];
}

- (void)didNavigateToUsersLikes
{
    [self.navBarVC didNavigateToUsersLikes];
}

- (void)didNavigateToUsersRoll
{
    [self.navBarVC didNavigateToUsersShares];
}

#pragma mark - ShelbyStreamBrowseViewDelegate

- (void)shelbyStreamBrowseViewController:(ShelbyStreamBrowseViewController *)vc didScrollTo:(CGPoint)contentOffset
{
    if (vc == self.currentStreamBrowseVC) {
        // StreamBrowseView is our leader, videoReel is our follower.  Keep their scrolling synchronized...
        [self.videoReel scrollTo:contentOffset];

        // and fade the video controls when between pages
        [self fadeVideoControlsForOffset:contentOffset frameHeight:vc.view.frame.size.height];
    }
}

//stream browser just landed on a cell.  Update views based on our state...
- (void)shelbyStreamBrowseViewControllerDidEndDecelerating:(ShelbyStreamBrowseViewController *)vc
{
    if (vc != self.currentStreamBrowseVC){
        return;
    }

    if (self.videoReel) {
        BOOL videoShouldHaveBeenPlaying = [self.videoReel shouldCurrentPlayerBePlaying];
        id<ShelbyVideoContainer> previousPlaybackEntity = [self.videoReel getCurrentPlaybackEntity];
        [self.videoReel endDecelerating];
        id<ShelbyVideoContainer> currentPlaybackEntity = [self.videoReel getCurrentPlaybackEntity];
        self.videoControlsVC.currentEntity = currentPlaybackEntity;

        if (!videoShouldHaveBeenPlaying && currentPlaybackEntity != previousPlaybackEntity) {
            //user paused & changed videos: transition to default view mode (from playback view mode)
            STVAssert(vc.viewMode != ShelbyStreamBrowseViewDefault, @"expected a playback mode, since we have a video reel");
            [UIView animateWithDuration:OVERLAY_ANIMATION_DURATION animations:^{
                [self dismissVideoReel];
                STVAssert(vc.viewMode == ShelbyStreamBrowseViewDefault, @"expected dismissVideoReel to update view mode");
                self.navBar.alpha = 1.0;
                self.videoControlsVC.view.alpha = 1.0;
            }];
            [ShelbyHomeViewController sendEventWithCategory:kAnalyticsCategoryPrimaryUX
                                                 withAction:kAnalyticsUXSwipeCardToChangeVideoPlaybackModePaused
                                        withNicknameAsLabel:YES];
        } else {
            //playing & changed videos: controls already updated
            [self doPeekAndHide];
            [ShelbyHomeViewController sendEventWithCategory:kAnalyticsCategoryPrimaryUX
                                                 withAction:kAnalyticsUXSwipeCardToChangeVideoPlaybackModePlaying
                                        withNicknameAsLabel:YES];
        }
    } else {
//        if (DEVICE_IPAD) {
//            //TODO: do video controls care about this?
//        } else {
            //on iPhone, we only show one stream, so current entity did change
        self.videoControlsVC.currentEntity = [vc entityForCurrentFocus];
        [ShelbyHomeViewController sendEventWithCategory:kAnalyticsCategoryPrimaryUX
                                             withAction:kAnalyticsUXSwipeCardToChangeVideoNonPlaybackMode
                                    withNicknameAsLabel:YES];
//        }
    }
}

- (void)shelbyStreamBrowseViewController:(ShelbyStreamBrowseViewController *)browseVC wasTapped:(UITapGestureRecognizer *)tapGestureRecognizer
{
    if (self.videoReel && self.currentStreamBrowseVC == browseVC) {
        [UIView animateWithDuration:OVERLAY_ANIMATION_DURATION animations:^{
            if (browseVC.viewMode == ShelbyStreamBrowseViewForPlaybackWithoutOverlay || browseVC.viewMode == ShelbyStreamBrowseViewForPlaybackPeeking) {
                //show overlays
                self.navBar.alpha = 1.0;
                self.videoControlsVC.view.alpha = 1.0;
                browseVC.viewMode = ShelbyStreamBrowseViewForPlaybackWithOverlay;
            } else {
                //hide overlays
                self.navBar.alpha = 0.0;
                self.videoControlsVC.view.alpha = 0.0;
                browseVC.viewMode = ShelbyStreamBrowseViewForPlaybackWithoutOverlay;
            }
        }];
    }
}

- (void)shelbyStreamBrowseViewController:(ShelbyStreamBrowseViewController *)vc didChangeToPage:(NSUInteger)page
{
    STVAssert(page == 0 || page == 1, @"bad page");
    if (self.currentStreamBrowseVC == vc) {
        [self updateVideoControlsForPage:page];
    }
}

- (void)shelbyStreamBrowseViewController:(ShelbyStreamBrowseViewController *)vc hasNoContnet:(BOOL)noContent
{
    if (self.currentStreamBrowseVC == vc) {
        self.videoControlsVC.view.hidden = noContent;
    }
}

- (void)shelbyStreamBrowseViewControllerTitleTapped:(ShelbyStreamBrowseViewController *)vc
{
    // Ignore if video is playing.
    if (!self.videoControlsVC.videoIsPlaying) {
        [self playChannel:self.currentStreamBrowseVC.channel atIndex:[self.currentStreamBrowseVC indexPathForCurrentFocus].row];
    }
}

- (void)launchMyRoll
{
    if ([self.masterDelegate conformsToProtocol:@protocol(ShelbyHomeDelegate)] && [self.masterDelegate respondsToSelector:@selector(goToUsersRoll)]) {
        [self.masterDelegate goToUsersRoll];
    }
}

- (void)launchMyLikes
{
    if ([self.masterDelegate conformsToProtocol:@protocol(ShelbyHomeDelegate)] && [self.masterDelegate respondsToSelector:@selector(goToUsersLikes)]) {
        [self.masterDelegate goToUsersLikes];
    }
}

- (void)launchMyStream
{
    if ([self.masterDelegate conformsToProtocol:@protocol(ShelbyHomeDelegate)] && [self.masterDelegate respondsToSelector:@selector(goToUsersStream)]) {
        [self.masterDelegate goToUsersStream];
    }
}

- (void)launchCommunityChannel
{
    if ([self.masterDelegate conformsToProtocol:@protocol(ShelbyHomeDelegate)] && [self.masterDelegate respondsToSelector:@selector(goToCommunityChannel)]) {
        [self.masterDelegate goToCommunityChannel];
    }
}

- (IBAction)dvrButtonTapped:(UIButton *)sender {
    //super hacky, fine for now
    if ([sender.titleLabel.text isEqualToString:@"DVR"]) {
        if ([self.masterDelegate conformsToProtocol:@protocol(ShelbyHomeDelegate)] && [self.masterDelegate respondsToSelector:@selector(goToDVR)]) {
            [self.masterDelegate goToDVR];
            [sender setTitle:@"Back" forState:UIControlStateNormal];
        }
    } else {
        if ([self.masterDelegate conformsToProtocol:@protocol(ShelbyHomeDelegate)] && [self.masterDelegate respondsToSelector:@selector(goToCommunityChannel)]) {
            [self.masterDelegate goToCommunityChannel];
            [sender setTitle:@"DVR" forState:UIControlStateNormal];
        }
    }
}

#pragma mark - VideoControlsDelegate

- (void)videoControlsPlayVideoWithCurrentFocus:(VideoControlsViewController *)vcvc
{
    [self playChannel:self.currentStreamBrowseVC.channel atIndex:[self.currentStreamBrowseVC indexPathForCurrentFocus].row];
}

- (void)videoControlsPauseCurrentVideo:(VideoControlsViewController *)vcvc
{
    [self.videoReel pauseCurrentPlayer];
}

- (void)videoControls:(VideoControlsViewController *)vcvc scrubCurrentVideoTo:(CGFloat)pct
{
    [self.videoReel scrubCurrentPlayerTo:pct];
}

-(void)videoControls:(VideoControlsViewController *)vcvc isScrubbing:(BOOL)isScrubbing
{
    //when scrubbing, hide the overlay so we can see (put it back when we're done scrubbing)
    if (isScrubbing) {
        STVAssert(self.currentStreamBrowseVC.viewMode == ShelbyStreamBrowseViewForPlaybackWithOverlay, @"expected overlay to be showing");
        [UIView animateWithDuration:OVERLAY_ANIMATION_DURATION animations:^{
            self.navBar.alpha = 0.0;
            self.currentStreamBrowseVC.viewMode = ShelbyStreamBrowseViewForPlaybackWithoutOverlay;
        }];
        [self.videoReel beginScrubbing];
    } else {
        STVAssert(self.currentStreamBrowseVC.viewMode == ShelbyStreamBrowseViewForPlaybackWithoutOverlay, @"expected overlay not showing");
        [UIView animateWithDuration:OVERLAY_ANIMATION_DURATION animations:^{
            self.navBar.alpha = 1.0;
            self.currentStreamBrowseVC.viewMode = ShelbyStreamBrowseViewForPlaybackWithOverlay;
        }];
        [self.videoReel endScrubbing];
    }
}

- (void)videoControlsLikeCurrentVideo:(VideoControlsViewController *)vcvc
{
    // GA
    [ShelbyHomeViewController sendEventWithCategory:kAnalyticsCategoryPrimaryUX
                                         withAction:kAnalyticsUXLike
                                withNicknameAsLabel:YES];
    // Appirater Event
    [Appirater userDidSignificantEvent:YES];
    
    BOOL didLike = [self toggleLikeCurrentVideo:vcvc.currentEntity];
    if (!didLike) {
        DLog(@"***ERROR*** Tried to Like, but action resulted in UNLIKE of the video");
    }
}

- (void)videoControlsUnlikeCurrentVideo:(VideoControlsViewController *)vcvc
{
    [ShelbyHomeViewController sendEventWithCategory:kAnalyticsCategoryPrimaryUX
                                         withAction:kAnalyticsUXUnlike
                                withNicknameAsLabel:YES];
    BOOL didLike = [self toggleLikeCurrentVideo:vcvc.currentEntity];
    if (didLike) {
        DLog(@"***ERROR*** Tried to unlike, but action resulted in LIKE of the video");
    }
}

//DEPRECATED
- (BOOL)toggleLikeCurrentVideo:(id<ShelbyVideoContainer>)entity
{
    Frame *currentFrame = [Frame frameForEntity:entity];
    BOOL didLike = [currentFrame toggleLike];
    return didLike;
}

- (void)videoControlsShareCurrentVideo:(VideoControlsViewController *)vcvc
{
    [ShelbyHomeViewController sendEventWithCategory:kAnalyticsCategoryPrimaryUX
                                         withAction:kAnalyticsUXShareStart
                                withNicknameAsLabel:YES];
    Frame *frame = [Frame frameForEntity:vcvc.currentEntity];
    SPShareController *shareController = [[SPShareController alloc] initWithVideoFrame:frame fromViewController:self atRect:CGRectZero];
    shareController.delegate = self;
    BOOL shouldResume = [self.videoReel isCurrentPlayerPlaying];
    [self.videoReel pauseCurrentPlayer];
    [shareController shareWithCompletionHandler:^(BOOL completed) {
        if (shouldResume) {
            [self.videoReel playCurrentPlayer];
        }
        
        [self.videoControlsVC resetShareButton];

        if (completed) {
            // GA
            [ShelbyHomeViewController sendEventWithCategory:kAnalyticsCategoryPrimaryUX
                                                 withAction:kAnalyticsUXShareFinish
                                        withNicknameAsLabel:YES];
            
            // Appirater Event
            [Appirater userDidSignificantEvent:YES];
        }
    }];
}

- (void)scrollToTopOfCurrentStreamBrowseVC
{
    [self.currentStreamBrowseVC scrollToTop];
    [self dismissVideoReel];
}

#pragma mark - SPShareControllerDelegate

- (void)shareControllerRequestsFacebookPublishPermissions:(SPShareController *)shareController
{
    [self.masterDelegate userAskForFacebookPublishPermissions];
}

- (void)shareControllerRequestsTwitterPublishPermissions:(SPShareController *)shareController
{
    [self.masterDelegate userAskForTwitterPublishPermissions];
}

#pragma mark - View Helpers

- (void)fadeVideoControlsForOffset:(CGPoint)contentOffset frameHeight:(CGFloat)frameHeight
{
    if (self.currentStreamBrowseVC.viewMode == ShelbyStreamBrowseViewForPlaybackWithoutOverlay || self.currentStreamBrowseVC.viewMode == ShelbyStreamBrowseViewForPlaybackPeeking) {
        return;
    }
    
    // offsetModHeight goes 0->FrameHeight as a page moves offscreen, returning abruptly to 0 as we hit the new page
    NSInteger offsetModHeight = ((NSInteger)contentOffset.y % (NSInteger)frameHeight);
    // normalize offsetModHeight into [0, 1]
    CGFloat offsetModHeightNormalized = offsetModHeight / frameHeight;
    // shift such that we move smoothly from 1->0->1 as we scroll from one page to the next
    CGFloat pageBoundaryDelta = fabsf(1.0 - 2.0 * offsetModHeightNormalized);
    self.videoControlsVC.view.alpha = pageBoundaryDelta*pageBoundaryDelta;
}

- (void)updateVideoControlsForPage:(NSUInteger)page
{
    [UIView animateWithDuration:OVERLAY_ANIMATION_DURATION animations:^{
        if (self.videoReel) {
            //playback, summary or detail page
            self.videoControlsVC.displayMode = VideoControlsDisplayActionsAndPlaybackControls;
        } else {
            if (page == 0) {
                //non playback, summary page
                self.videoControlsVC.displayMode = VideoControlsDisplayDefault;
            } else {
                //non playback, detail page
                self.videoControlsVC.displayMode = VideoControlsDisplayActionsOnly;
            }
        }
    }];
}

#pragma mark - ShelbyNavBarDelegate

- (void)navBarViewControllerWillExpand:(ShelbyNavBarViewController *)navBarVC
{
    [self hideNavBarButton];
}

- (void)navBarViewControllerWillContract:(ShelbyNavBarViewController *)navBarVC
{
    [self showNavBarButton];
}

- (void)navBarViewControllerStreamWasTapped:(ShelbyNavBarViewController *)navBarVC selectionShouldChange:(BOOL)selectedNewRow
{
    if (selectedNewRow) {
        if (self.videoReel) {
            [self dismissVideoReel];
        }
        [self updateVideoControlsForPage:0];
        [self launchMyStream];
    } else {
        [self scrollToTopOfCurrentStreamBrowseVC];
    }

}

- (void)navBarViewControllerLikesWasTapped:(ShelbyNavBarViewController *)navBarVC selectionShouldChange:(BOOL)selectedNewRow
{
    if (selectedNewRow) {
        if (self.videoReel) {
            [self dismissVideoReel];
        }
        [self updateVideoControlsForPage:0];
        [self launchMyLikes];
    } else {
        [self scrollToTopOfCurrentStreamBrowseVC];
    }
}

- (void)navBarViewControllerSharesWasTapped:(ShelbyNavBarViewController *)navBarVC selectionShouldChange:(BOOL)selectedNewRow
{
    if (selectedNewRow) {
        if (self.videoReel) {
            [self dismissVideoReel];
        }
        [self updateVideoControlsForPage:0];
        [self launchMyRoll];
    } else {
        [self scrollToTopOfCurrentStreamBrowseVC];
    }
}

- (void)navBarViewControllerCommunityWasTapped:(ShelbyNavBarViewController *)navBarVC selectionShouldChange:(BOOL)selectedNewRow
{
    if (selectedNewRow) {
        if (self.videoReel) {
            [self dismissVideoReel];
        }
        [self updateVideoControlsForPage:0];
        [self launchCommunityChannel];
    } else {
        [self scrollToTopOfCurrentStreamBrowseVC];
    }
}

- (void)navBarViewControllerSettingsWasTapped:(ShelbyNavBarViewController *)navBarVC selectionShouldChange:(BOOL)selectedNewRow
{
    if (selectedNewRow) {
        if (self.videoReel) {
            [self dismissVideoReel];
        }
        [self presentSettings];
        [navBarVC didNavigateToSettings];
    } else {
        //already showing settings, nothing to do
    }

}

- (void)navBarViewControllerLoginWasTapped:(ShelbyNavBarViewController *)navBarVC selectionShouldChange:(BOOL)selectedNewRow
{
    [self dismissVideoReel];
    [self.masterDelegate presentUserLogin];
    //login is modal, nav hasn't actually changed...
    [navBarVC performSelector:@selector(returnSelectionToPreviousRow) withObject:nil afterDelay:0.3];
}

- (void)presentSettings
{
    if (!_settingsVC) {
        _settingsVC = [[SettingsViewController alloc] initWithUser:self.currentUser andNibName:@"SettingsView-iPhone"];
        _settingsVC.delegate = self.masterDelegate;
        //this gets overriden by autolayout, just using it to set starting point for transition
        _settingsVC.view.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
        [self swapOutViewController:_currentFullScreenVC forViewController:_settingsVC completion:^(BOOL finished) {
            _settingsVC.view.translatesAutoresizingMaskIntoConstraints = NO;
            [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[settings]|"
                                                                              options:0
                                                                              metrics:nil
                                                                                views:@{@"settings":_settingsVC.view}]];
            [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[settings]|"
                                                                              options:0
                                                                              metrics:nil
                                                                                views:@{@"settings":_settingsVC.view}]];

            self.videoControlsVC.view.hidden = YES;
        }];
    }
}

- (void)dismissSettings
{
    if (_settingsVC) {
        [_settingsVC willMoveToParentViewController:nil];
        [_settingsVC.view removeFromSuperview];
        [_settingsVC removeFromParentViewController];
        _settingsVC = nil;
    }
}

@end
