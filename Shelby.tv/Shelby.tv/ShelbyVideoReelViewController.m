//
//  ShelbyVideoReelViewController.m
//  Shelby.tv
//
//  Created by Keren on 1/9/14.
//  Copyright (c) 2014 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyVideoReelViewController.h"
#import "Appirater.h"
//TODO: refactor these out of brain?
#import "ShelbyBrain.h"
#import "ShelbyDataMediator.h"
#import "SPShareController.h"
#import "SPVideoExtractor.h"
#import "SPVideoReelCollectionViewController.h"
#import "User+Helper.h"
#import "VideoReelBackdropView.h"

#define VIDEO_CONTROLS_AUTOHIDE_TIME 5.0

@interface ShelbyVideoReelViewController ()
@property (nonatomic, strong) SPVideoReelCollectionViewController *videoReelCollectionVC;
@property (nonatomic, strong) VideoReelBackdropView *videoReelBackdropView;
@property (nonatomic, strong) UIView *airPlayBackdropView;
@property (nonatomic, strong) ShelbyAirPlayController *airPlayController;
//we track the current channel and deduped entries for when airplay takes over from video reel
@property (nonatomic, strong) DisplayChannel *currentChannel;
@property (nonatomic, strong) NSArray *currentDeduplicatedEntries;
@property (nonatomic, assign) NSUInteger currentlyPlayingIndexInChannel;
//sharing
@property (nonatomic, strong) SPShareController *shareController;
@property (nonatomic, assign) BOOL wasPlayingBeforeModalViewWasPresented;
@property (nonatomic, assign) NSUInteger presentedModalViewCount;
@property (nonatomic, strong) NSTimer *autoHideVideoControlsTimer;
@end

@implementation ShelbyVideoReelViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.currentlyPlayingIndexInChannel = 0;
    self.presentedModalViewCount = 0;
    
    [self setupAirplayBackdrop];
    [self setupBackdrop];
    [self setupVideoControls];
    [self setupVideoOverlay];
    [self setupAirPlay];
    
    //we listen to current video changes same as everybody else (even tho we create the video reel)
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(videoReelDidChangePlaybackEntityNotification:)
                                                 name:kShelbyPlaybackEntityDidChangeNotification object:nil];
    
    //adjust play/pause when modal views obscure video
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(willPresentModalViewNotification:)
                                                 name:kShelbyWillPresentModalViewNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didDismissModalViewNotification:)
                                                 name:kShelbyDidDismissModalViewNotification object:nil];
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - contained views (video reels, controls, overlay)

- (void)setDeduplicatedEntries:(NSArray *)channelEntries forChannel:(DisplayChannel *)channel
{
    BOOL initialChannel = !self.currentChannel;
    if (self.currentChannel == channel || initialChannel) {
        self.currentChannel = channel;
        self.currentDeduplicatedEntries = channelEntries;
        
        if (initialChannel) {
            //want a video reel so it's pretty from bootup
            STVDebugAssert(!self.videoReelCollectionVC);
            [self presentVideoReelWithChannel:channel
                          deduplicatedEntries:self.currentDeduplicatedEntries
                                      atIndex:0
                                     autoplay:NO];
            self.videoOverlayView.hidden = NO;
            self.videoReelBackdropView.backdropImageEntity = [self.currentDeduplicatedEntries firstObject];
        }
    }
}

- (void)playChannel:(DisplayChannel *)channel withDeduplicatedEntries:(NSArray *)deduplicatedEntries atIndex:(NSUInteger)idx
{
    self.currentChannel = channel;
    self.currentDeduplicatedEntries = deduplicatedEntries;
    self.currentlyPlayingIndexInChannel = idx;
    
    if (self.videoReelCollectionVC) {
        //A) currently playing via VideReel
        if (self.videoReelCollectionVC.channel == channel) {
            [self.videoReelCollectionVC setDeduplicatedEntries:deduplicatedEntries];
            [self.videoReelCollectionVC scrollForPlaybackAtIndex:idx forcingPlayback:YES];
        } else {
            [self dismissCurrentVideoReel];
            [self presentVideoReelWithChannel:channel
                          deduplicatedEntries:deduplicatedEntries
                                      atIndex:idx
                                     autoplay:YES];
        }
        self.videoReelBackdropView.backdropImageEntity = deduplicatedEntries[idx];
        
    } else if ([self.airPlayController isAirPlayActive]) {
        //B) currently playing via AirPlay (simply play index requested, it has no queue)
        [self.airPlayController playEntity:deduplicatedEntries[idx] inChannel:channel];
        self.videoReelBackdropView.backdropImageEntity = deduplicatedEntries[idx];
        
    } else {
        //C) haven't started playing anything yet (bootup)
        [self presentVideoReelWithChannel:channel
                      deduplicatedEntries:deduplicatedEntries
                                  atIndex:idx
                                 autoplay:YES];
        self.videoReelBackdropView.backdropImageEntity = deduplicatedEntries[idx];
    }

    self.videoOverlayView.hidden = NO;
    
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
}

- (void)setupAirplayBackdrop
{
    self.airPlayBackdropView = [[NSBundle mainBundle] loadNibNamed:@"VideoReelAirplayBackdropView" owner:self options:nil][0];
    [self.view addSubview:self.airPlayBackdropView];
    self.airPlayBackdropView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[APBackdrop]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:@{@"APBackdrop":self.airPlayBackdropView}]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[APBackdrop]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:@{@"APBackdrop":self.airPlayBackdropView}]];
    self.airPlayBackdropView.alpha = 0.f;
}

- (void)setupBackdrop
{
    self.videoReelBackdropView = [[VideoReelBackdropView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:self.videoReelBackdropView];
    self.videoReelBackdropView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[backdrop]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:@{@"backdrop":self.videoReelBackdropView}]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[backdrop]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:@{@"backdrop":self.videoReelBackdropView}]];
    self.videoReelBackdropView.showBackdropImage = NO;
}

- (void)setupVideoControls
{
    self.videoControlsVC = [[VideoControlsViewController alloc] initWithNibName:@"VideoControlsView-iPad" bundle:nil];
    self.videoControlsVC.delegate = self;
    [self.videoControlsVC willMoveToParentViewController:self];
    [self.view addSubview:self.videoControlsVC.view];
    self.videoControlsVC.view.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[controls]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:@{@"controls":self.videoControlsVC.view}]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[controls(60)]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:@{@"controls":self.videoControlsVC.view}]];
    [self addChildViewController:self.videoControlsVC];
    [self.videoControlsVC didMoveToParentViewController:self];
    
    self.videoControlsVC.displayMode = VideoControlsDisplayActionsAndPlaybackControls;
}

- (void)setupVideoOverlay
{
    self.videoOverlayView = [[[NSBundle mainBundle] loadNibNamed:@"VideoOverlayView-iPad" owner:self options:nil] firstObject];
    
    [self.view insertSubview:self.videoOverlayView aboveSubview:self.videoControlsVC.view];
    self.videoOverlayView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[overlay]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:@{@"overlay":self.videoOverlayView}]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[overlay(250)]"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:@{@"overlay":self.videoOverlayView}]];
    self.videoOverlayView.hidden = YES;
}

- (void)setupAirPlay
{
    self.airPlayController = [[ShelbyAirPlayController alloc] init];
    self.airPlayController.delegate = self;
    //if and when airPlayController takes control (from SPVideoReel),
    //it will update video controls w/ current state of SPVideoPlayer
    self.airPlayController.videoControlsVC = _videoControlsVC;
    
    //airplay cares when we become/resign active
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleDidBecomeActiveNotification:)
                                                 name:kShelbyBrainDidBecomeActiveNotification object:nil];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleWillResignActiveNotification:)
                                                 name:kShelbyBrainWillResignActiveNotification object:nil];
}

#pragma mark - Notification Handlers

- (void)videoReelDidChangePlaybackEntityNotification:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;
    // KP: had to comment - wasn't archiving
//    DisplayChannel *channel = userInfo[kShelbyVideoReelChannelKey];
//    STVDebugAssert(self.videoReel.channel == channel, @"these should be in sync");
    
    id<ShelbyVideoContainer> entity = userInfo[kShelbyPlaybackCurrentEntityKey];
    self.videoControlsVC.currentEntity = entity;
    self.videoOverlayView.currentEntity = entity;
    self.videoReelBackdropView.backdropImageEntity = entity;
    self.currentlyPlayingIndexInChannel = [self.currentDeduplicatedEntries indexOfObject:entity];
    
    //show video overlay if we're in full screen mode
    [self showVideoOverlay];
}

- (void)handleDidBecomeActiveNotification:(NSNotification *)notification
{
    [self.airPlayController checkForExistingScreenAndInitializeIfPresent];
}

- (void)handleWillResignActiveNotification:(NSNotification *)notification
{
    [self videoControlsPauseCurrentVideo:nil];
}

- (void)willPresentModalViewNotification:(NSNotification *)notification
{
    self.presentedModalViewCount++;
    
    if (self.presentedModalViewCount > 1) {
        //only care about playback state when first modal view was presented
        return;
    }
    
    self.wasPlayingBeforeModalViewWasPresented = self.videoReelCollectionVC ? [self.videoReelCollectionVC isCurrentPlayerPlaying] : NO;
    if (self.wasPlayingBeforeModalViewWasPresented) {
        [self videoControlsPauseCurrentVideo:nil];
    }
}

- (void)didDismissModalViewNotification:(NSNotification *)notification
{
    self.presentedModalViewCount--;
    
    if (self.presentedModalViewCount > 0) {
        //only resetting playback state when all modals are removed
        return;
    }
    
    if (self.wasPlayingBeforeModalViewWasPresented) {
        [self videoControlsPlayCurrentVideo:nil];
    }
}

#pragma mark - custom gesture recognizers on video reel

- (void)singleTapOnVideoReelDetected:(UIGestureRecognizer *)gestureRecognizer
{
    if (self.videoControlsVC.view.alpha == self.videoOverlayView.alpha) {
        // if the all of the player chrome elements (video controls and video overlay) are in the same visibility state, toggle the player chrome
        [self togglePlayerChrome];
    } else {
        // if their visibility states are unmatched, toggle the video controls to bring
        // them into the same visibility state as the video overlay
        [self togglePlayerChromeIncludingVideoControls:YES IncludingInfoOverlay:NO];
    }
}

- (void)doubleTapOnVideoReelDetected:(UIGestureRecognizer *)gestureRecognizer
{
    [self.videoControlsVC requestToggleFullscreen];
}

#pragma mark - VideoControlsDelegate

- (void)videoControlsPlayCurrentVideo:(VideoControlsViewController *)vcvc
{
    [self.airPlayController playCurrentPlayer];
    [self.videoReelCollectionVC playCurrentPlayer];
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    [self scheduleAutoHideVideoControlsTimer];
}

- (void)videoControlsPauseCurrentVideo:(VideoControlsViewController *)vcvc
{
    [self.airPlayController pauseCurrentPlayer];
    [self.videoReelCollectionVC pauseCurrentPlayer];
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    [self invalidateAutoHideVideoControlsTimer];
}

- (void)videoControls:(VideoControlsViewController *)vcvc scrubCurrentVideoTo:(CGFloat)pct
{
    [self.airPlayController scrubCurrentPlayerTo:pct];
    [self.videoReelCollectionVC scrubCurrentPlayerTo:pct];
    [self scheduleAutoHideVideoControlsTimer];
}

- (void)videoControls:(VideoControlsViewController *)vcvc isScrubbing:(BOOL)isScrubbing
{
    if (isScrubbing) {
        [self.airPlayController beginScrubbing];
        [self.videoReelCollectionVC beginScrubbing];
    } else {
        [self.airPlayController endScrubbing];
        [self.videoReelCollectionVC endScrubbing];
    }
    [self scheduleAutoHideVideoControlsTimer];
}

- (void)videoControlsLikeCurrentVideo:(VideoControlsViewController *)vcvc
{
    // Analytics
    [ShelbyVideoReelViewController sendEventWithCategory:kAnalyticsCategoryPrimaryUX
                                              withAction:kAnalyticsUXLike
                                     withNicknameAsLabel:YES];
    [ShelbyAnalyticsClient sendLocalyticsEvent:kLocalyticsLikeVideo];
    // Appirater Event
    [Appirater userDidSignificantEvent:YES];

    [self scheduleAutoHideVideoControlsTimer];

    BOOL didLike = [self likeVideo:vcvc.currentEntity];
    if (!didLike) {
        DLog(@"***ERROR*** Tried to Like '%@', but action resulted in UNLIKE of the video", vcvc.currentEntity.containedVideo.title);
    } else {
        //NB: just copied this heart animation code from HomeVC
        dispatch_async(dispatch_get_main_queue(), ^{
            
            UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"heart-large"]];
            NSInteger imageHeight = imageView.frame.size.height;
            NSInteger imageWidth = imageView.frame.size.width;
            NSInteger viewHeight = self.view.frame.size.height;
            NSInteger viewWidth = self.view.frame.size.width;
            imageView.frame = CGRectMake(viewWidth/2 - imageWidth/4, viewHeight/2 - imageHeight/4, imageWidth/2, imageHeight/2);
            [self.view addSubview:imageView];
            [UIView animateWithDuration:0.1 animations:^{
                imageView.frame = CGRectMake(viewWidth/2 - imageWidth/2, viewHeight/2 - imageHeight/2, imageWidth, imageHeight);
            } completion:^(BOOL finished) {
                [UIView animateWithDuration:0.3 animations:^{
                    imageView.alpha = 0.99;
                } completion:^(BOOL finished) {
                    [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationCurveEaseIn animations:^{
                        imageView.frame = CGRectMake(viewWidth/2 - imageWidth/4, viewHeight/2 - imageHeight/4, imageWidth/2, imageHeight/2);
                        imageView.alpha = 0;
                    } completion:^(BOOL finished) {
                        [imageView removeFromSuperview];
                    }];
                }];
            }];
        });
    }
}

- (void)videoControlsUnlikeCurrentVideo:(VideoControlsViewController *)vcvc
{
    [ShelbyVideoReelViewController sendEventWithCategory:kAnalyticsCategoryPrimaryUX
                                              withAction:kAnalyticsUXUnlike
                                     withNicknameAsLabel:YES];
    [self scheduleAutoHideVideoControlsTimer];
    BOOL didUnlike = [self unlikeVideo:vcvc.currentEntity];
    if (!didUnlike) {
        DLog(@"***ERROR*** Tried to unlike '%@', but action resulted in LIKE of the video", vcvc.currentEntity.containedVideo.title);
    }
}

- (void)videoControlsShareCurrentVideo:(VideoControlsViewController *)vcvc
{
    self.shareController = [[SPShareController alloc] initWithVideoFrame:[Frame frameForEntity:vcvc.currentEntity]
                                                      fromViewController:self
                                                                  atRect:CGRectMake(515, 700, 60, 60)]; // From where Share button should be
    [self.shareController shareWithCompletionHandler:^(BOOL completed) {
        self.shareController = nil;
    }];
}

- (void)videoControlsRequestFullScreen:(VideoControlsViewController *)vcvc isExpanding:(BOOL)isExpanding
{
    [self scheduleAutoHideVideoControlsTimer];
}

- (void)videoControlsRevealAirplayPicker:(VideoControlsViewController *)vcvc airplayButton:(UIButton *)button
{
    [self scheduleAutoHideVideoControlsTimer];
}

#pragma mark - SPVideoReelDelegate

- (void)loadMoreEntriesInChannel:(DisplayChannel *)channel sinceEntry:(NSManagedObject *)entry
{
    [[ShelbyDataMediator sharedInstance] fetchEntriesInChannel:channel sinceEntry:entry];
}

- (BOOL)canRoll
{
    //on iPhone, only criteria was that we had a logged in user
    //this may change w/ the introduction of anonymous users...
    User *u = [User currentAuthenticatedUserInContext:[ShelbyDataMediator sharedInstance].mainThreadContext];
    //TODO: do we care if this user is anonymous or not?
    return u != nil;
}

- (void)userAskForFacebookPublishPermissions
{
    [[ShelbyDataMediator sharedInstance] userAskForFacebookPublishPermissions];
}

- (void)userAskForTwitterPublishPermissions
{
    //get topmost visible view
    UIViewController *topViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    while ([topViewController presentedViewController]) {
        topViewController = [topViewController presentedViewController];
    }
    
    [[ShelbyDataMediator sharedInstance] connectTwitterWithViewController:topViewController];
}

- (void)videoDidAutoadvance
{
    //show video overlay if we're in fullscreen mode (otherwise overlay is still on screen)
    [self showVideoOverlay];
}

- (void)userDidSwitchChannelForDirectionUp:(BOOL)up
{
    STVDebugAssert(NO, @"unused");
}

- (void)userDidCloseChannelAtFrame:(Frame *)frame
{
    STVDebugAssert(NO, @"unused");
}

- (DisplayChannel *)displayChannelForDirection:(BOOL)up
{
    STVDebugAssert(NO, @"unused");
    return nil;
}

- (void)userDidRequestPlayCurrentPlayer
{
    [self videoControlsPlayCurrentVideo:nil];
}

#pragma mark - ShelbyAirPlayControllerDelegate

- (void)airPlayControllerDidBeginAirPlay:(ShelbyAirPlayController *)airPlayController
{
    // current player has a new owner: _airPlayController, we can kill the reel
    if (self.videoReelCollectionVC) {
        // current SPVideoPlayer will not reset itself b/c it's in external playback mode
        [self dismissCurrentVideoReel];
        [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    }
    
    [self showAirPlayViewMode:YES];
}

- (void)airPlayControllerDidEndAirPlay:(ShelbyAirPlayController *)airPlayController
{
    // _airPlayController handles shutdown of SPVideoPlayer
    // we present a video reel for continuity
    [self presentVideoReelWithChannel:self.currentChannel
                  deduplicatedEntries:self.currentDeduplicatedEntries
                              atIndex:self.currentlyPlayingIndexInChannel
                             autoplay:NO];
    
    [self showAirPlayViewMode:NO];
}

- (void)airPlayControllerShouldAutoadvance:(ShelbyAirPlayController *)airPlayController
{
    if ([self.currentDeduplicatedEntries count] > self.currentlyPlayingIndexInChannel+1) {
        //we're not on the last video, advance!
        self.currentlyPlayingIndexInChannel++;
        [self playChannel:self.currentChannel withDeduplicatedEntries:self.currentDeduplicatedEntries atIndex:self.currentlyPlayingIndexInChannel];
    }
    
    // Do something based on the *next* video (after advancing)
    if ([self.currentDeduplicatedEntries count] == (NSUInteger)self.currentlyPlayingIndexInChannel+1) {
        //fetch more if we're now on the last entity in our array
        [self loadMoreEntriesInChannel:self.currentChannel
                            sinceEntry:[self.currentDeduplicatedEntries lastObject]];
    } else {
        //otherwise, warm cache for the next entity
        [[SPVideoExtractor sharedInstance] warmCacheForVideoContainer:self.currentDeduplicatedEntries[self.currentlyPlayingIndexInChannel+1]];
    }
}

#pragma mark - Helpers

- (BOOL)likeVideo:(id<ShelbyVideoContainer>)entity
{
    Frame *f = [Frame frameForEntity:entity];
    BOOL didLike = [f doLike];
    return didLike;
}

- (BOOL)unlikeVideo:(id<ShelbyVideoContainer>)entity
{
    Frame *f = [Frame frameForEntity:entity];
    BOOL didUnlike = [f doUnlike];
    return didUnlike;
}

- (void)dismissCurrentVideoReel
{
    STVDebugAssert([NSThread isMainThread], @"expecting to be called on main thread");
    if (!self.videoReelCollectionVC) {
        return;
    }
    
    if (!self.airPlayController.isAirPlayActive){
        [self.videoReelCollectionVC pauseCurrentPlayer];
    }
    
    [self.videoReelCollectionVC shutdown];
    [self.videoReelCollectionVC willMoveToParentViewController:nil];
    [self.videoReelCollectionVC.view removeFromSuperview];
    [self.videoReelCollectionVC removeFromParentViewController];
    self.videoReelCollectionVC = nil;
}

- (void)presentVideoReelWithChannel:(DisplayChannel *)channel
                deduplicatedEntries:(NSArray *)deduplicatedChannelEntries
                            atIndex:(NSUInteger)videoStartIndex
                           autoplay:(BOOL)autoplay
{
    self.videoReelCollectionVC = ({
        //initialize with default layout
        SPVideoReelCollectionViewController *reel = [[SPVideoReelCollectionViewController alloc] init];
        reel.delegate = self;
        reel.videoPlaybackDelegate = self.videoControlsVC;
        
        reel.view.frame = self.view.bounds;
        //iPad only modifications to SPVideoReel
        reel.view.backgroundColor = [UIColor clearColor];
        reel.backdropView = self.videoReelBackdropView;
        reel;
    });
    
    [self addChildViewController:self.videoReelCollectionVC];
    [self.view insertSubview:self.videoReelCollectionVC.view belowSubview:self.videoControlsVC.view];
    [self.videoReelCollectionVC didMoveToParentViewController:self];
    
    self.videoReelCollectionVC.channel = channel;
    [self.videoReelCollectionVC setDeduplicatedEntries:deduplicatedChannelEntries];
    [self.videoReelCollectionVC scrollForPlaybackAtIndex:videoStartIndex forcingPlayback:autoplay];
    
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTapOnVideoReelDetected:)];
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapOnVideoReelDetected:)];
    doubleTap.numberOfTapsRequired = 2;
    [singleTap requireGestureRecognizerToFail:doubleTap];
    [self.videoReelCollectionVC addGestureRecognizer:singleTap];
    [self.videoReelCollectionVC addGestureRecognizer:doubleTap];
    
    //to allow SPVideoReel controls the hidden state of backdrop image
    self.videoReelBackdropView.showBackdropImage = YES;
}

- (void)showAirPlayViewMode:(BOOL)airplayMode
{
    if (airplayMode) {
        if (self.videoControlsVC.displayMode == VideoControlsDisplayForAirPlay) {
            return;
        }
        //enter airplay mode
        [UIView animateWithDuration:0.2 animations:^{
            self.airPlayBackdropView.alpha = 1.f;
            self.videoReelBackdropView.alpha = 0.f;
            self.videoControlsVC.view.alpha = 1.f;
            self.videoControlsVC.displayMode = VideoControlsDisplayForAirPlay;
        }];
        // no longer want to autohide video controls
        [self invalidateAutoHideVideoControlsTimer];
    } else {
        //exit airplay mode
        STVDebugAssert(self.videoControlsVC.displayMode == VideoControlsDisplayForAirPlay, @"shouldn't exit airplay when not in airplay");
        [UIView animateWithDuration:0.2 animations:^{
            self.airPlayBackdropView.alpha = 0.f;
            self.videoReelBackdropView.alpha = 1.f;
            self.videoControlsVC.displayMode = VideoControlsDisplayActionsAndPlaybackControls;
        }];

    }
}

- (void)togglePlayerChromeIncludingVideoControls:(BOOL)includeVideoControls
                            IncludingInfoOverlay:(BOOL)includeInfoOverlay
{

    CGFloat oldAlpha;
    if (includeInfoOverlay) {
        oldAlpha = self.videoOverlayView.alpha;
    } else {
        oldAlpha = self.videoControlsVC.view.alpha;
    }

    CGFloat newAlpha;
    if (oldAlpha == 0.f) {
        newAlpha = 1.f;
        [self scheduleAutoHideVideoControlsTimer];
    } else {
        newAlpha = 0.f;
    }

    [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        if (includeVideoControls) {
            self.videoControlsVC.view.alpha = newAlpha;
        }
        if (includeInfoOverlay) {
            self.videoOverlayView.alpha = newAlpha;
        }
    } completion:nil];
}

- (void)togglePlayerChrome
{
    [self togglePlayerChromeIncludingVideoControls:YES IncludingInfoOverlay:YES];
}

- (void)hidePlayerChrome
{
    // if the player chrome is visible, toggle it so it will be hidden
    // video chrome visibility will always match overlay view visibility so we key off of that
    if (self.videoOverlayView.alpha == 1.f) {
        [self togglePlayerChrome];
    }
}

- (void)showVideoOverlay
{
    if (self.videoOverlayView.alpha == 0.f) {
        // if the overlay view is not visible, show it
        [self togglePlayerChromeIncludingVideoControls:false IncludingInfoOverlay:true];
    } else {
        //otherwise, something happened that made us want to display this again, so increase
        //the amount of time it will be on screen by resetting the autohide timer
        [self scheduleAutoHideVideoControlsTimer];
    }
}

- (void) scheduleAutoHideVideoControlsTimer
{
    // we only auto hide the video controls when a video is playing and we're not on airplay
    if (self.videoControlsVC.videoIsPlaying && (self.videoControlsVC.displayMode != VideoControlsDisplayForAirPlay)) {
        if (self.autoHideVideoControlsTimer && [self.autoHideVideoControlsTimer isValid]) {
            //if there's already a timer, reset it to the full autohide timeout
            [self.autoHideVideoControlsTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:VIDEO_CONTROLS_AUTOHIDE_TIME]];
        } else {
            //otherwise, create a new timer and set it to hide the video controls after
            // the autohide timeout
            self.autoHideVideoControlsTimer =
            [NSTimer scheduledTimerWithTimeInterval:VIDEO_CONTROLS_AUTOHIDE_TIME
                                             target:self
                                           selector:@selector(hidePlayerChrome)
                                           userInfo:nil
                                            repeats:NO];
        }
    }
}

- (void) invalidateAutoHideVideoControlsTimer
{
    if (self.autoHideVideoControlsTimer) {
        [self.autoHideVideoControlsTimer invalidate];
    }
}

@end
