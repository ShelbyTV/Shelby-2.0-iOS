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
#import "SPVideoReel.h"
#import "User+Helper.h"

NSString * const kShelbySingleTapOnVideReelNotification = @"kShelbySingleTapOnVideReelNotification";

@interface ShelbyVideoReelViewController ()
@property (nonatomic, strong) SPVideoReel *videoReel;
@property (nonatomic, strong) ShelbyAirPlayController *airPlayController;
//we track the current channel and deduped entries for when airplay takes over from video reel
@property (nonatomic, strong) DisplayChannel *currentChannel;
@property (nonatomic, strong) NSArray *currentDeduplicatedEntries;
@end

@implementation ShelbyVideoReelViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _airPlayController = [[ShelbyAirPlayController alloc] init];
        _airPlayController.delegate = self;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupVideoControls];
    [self setupVideoOverlay];
    
    //we listen to current video changes same as everybody else (even tho we create the video reel)
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(videoReelDidChangePlaybackEntityNotification:)
                                                 name:kShelbyVideoReelDidChangePlaybackEntityNotification object:nil];
    
    //airplay cares when we become/resign active
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleDidBecomeActiveNotification:)
                                                 name:kShelbyBrainDidBecomeActiveNotification object:nil];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleWillResignActiveNotification:)
                                                 name:kShelbyBrainWillResignActiveNotification object:nil];
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
    if (self.currentChannel == channel || !self.currentChannel) {
        self.currentChannel = channel;
        self.currentDeduplicatedEntries = channelEntries;
    }
}

- (void)playChannel:(DisplayChannel *)channel withDeduplicatedEntries:(NSArray *)deduplicatedEntries atIndex:(NSUInteger)idx
{
    self.currentChannel = channel;
    self.currentDeduplicatedEntries = deduplicatedEntries;
    
    if (self.videoReel) {
        //A) currently playing via VideReel
        if (self.videoReel.channel == channel) {
            [self.videoReel setDeduplicatedEntries:deduplicatedEntries];
        } else {
            [self dismissCurrentVideoReel];
            [self presentVideoReelWithChannel:channel deduplicatedEntries:deduplicatedEntries atIndex:idx];
        }
        [self.videoReel scrollForPlaybackAtIndex:idx forcingPlayback:YES];
        
    } else if (self.airPlayController) {
        //B) currently playing via AirPlay (simply play index requested, it has no queue)
        [self.airPlayController playEntity:deduplicatedEntries[idx]];
        
    } else {
        //C) haven't started playing anything yet (bootup)
        [self presentVideoReelWithChannel:channel deduplicatedEntries:deduplicatedEntries atIndex:idx];
        
    }
    
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
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
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[controls(100)]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:@{@"controls":self.videoControlsVC.view}]];
    [self addChildViewController:self.videoControlsVC];
    [self.videoControlsVC didMoveToParentViewController:self];
    
    self.videoControlsVC.displayMode = VideoControlsDisplayActionsAndPlaybackControls;
    
    //if and when airPlayController takes control (from SPVideoReel), it will update video controls w/ current state of SPVideoPlayer
    self.airPlayController.videoControlsVC = _videoControlsVC;
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
}

#pragma mark - Notification Handlers

- (void)videoReelDidChangePlaybackEntityNotification:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;
    DisplayChannel *channel = userInfo[kShelbyVideoReelChannelKey];
    STVDebugAssert(self.videoReel.channel == channel, @"these should be in sync");
    
    id<ShelbyVideoContainer> entity = userInfo[kShelbyVideoReelEntityKey];
    self.videoControlsVC.currentEntity = entity;
    self.videoOverlayView.currentEntity = entity;
}

- (void)handleDidBecomeActiveNotification:(NSNotification *)notification
{
    [self.airPlayController checkForExistingScreenAndInitializeIfPresent];
}

- (void)handleWillResignActiveNotification:(NSNotification *)notification
{
    [self videoControlsPauseCurrentVideo:nil];
}

#pragma mark - custom gesture recognizers on video reel

- (void)singleTapOnVideoReelDetected:(UIGestureRecognizer *)gestureRecognizer
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kShelbySingleTapOnVideReelNotification object:self];
}

#pragma mark - VideoControlsDelegate

- (void)videoControlsPlayCurrentVideo:(VideoControlsViewController *)vcvc
{
    [self.airPlayController playCurrentPlayer];
    [self.videoReel playCurrentPlayer];
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
}

- (void)videoControlsPauseCurrentVideo:(VideoControlsViewController *)vcvc
{
    [self.airPlayController pauseCurrentPlayer];
    [self.videoReel pauseCurrentPlayer];
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
}

- (void)videoControls:(VideoControlsViewController *)vcvc scrubCurrentVideoTo:(CGFloat)pct
{
    [self.airPlayController scrubCurrentPlayerTo:pct];
    [self.videoReel scrubCurrentPlayerTo:pct];
}

- (void)videoControls:(VideoControlsViewController *)vcvc isScrubbing:(BOOL)isScrubbing
{
    if (isScrubbing) {
        [self.airPlayController beginScrubbing];
        [self.videoReel beginScrubbing];
    } else {
        [self.airPlayController endScrubbing];
        [self.videoReel endScrubbing];
    }
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
    BOOL didUnlike = [self unlikeVideo:vcvc.currentEntity];
    if (!didUnlike) {
        DLog(@"***ERROR*** Tried to unlike '%@', but action resulted in LIKE of the video", vcvc.currentEntity.containedVideo.title);
    }
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
    //TODO iPad TODO
    // on iPhone this does the peek-and-hide of the overlay
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

#pragma mark - ShelbyAirPlayControllerDelegate

- (void)airPlayControllerDidBeginAirPlay:(ShelbyAirPlayController *)airPlayController
{
    // current SPVideoPlayer has a new owner: _airPlayController
    if (self.videoReel) {
        // current SPVideoPlayer will not reset itself b/c it's in external playback mode
        [self dismissCurrentVideoReel];
        [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    }
    
    [self showAirPlayViewMode:YES];
}

- (void)airPlayControllerDidEndAirPlay:(ShelbyAirPlayController *)airPlayController
{
    //NB: _airPlayController handles shutdown of SPVideoPlayer
    [self showAirPlayViewMode:NO];
}

- (void)airPlayControllerShouldAutoadvance:(ShelbyAirPlayController *)airPlayController
{
    DLog(@"AIR PLAY TODO");

    //TODO iPad TODO AirPlay
    
//XXX - below is slightly modified code from HomeVC
//    if ([self.currentDeduplicatedEntries count] > (NSUInteger)self.currentlyPlayingIndexInChannel+1) {
//        [self playChannel:self.currentlyPlayingChannel atIndex:self.currentlyPlayingIndexInChannel+1];
//        //self.currentlyPlayingIndexInChannel is now ++
//    }
//    
//    //fetch more if we're now on the last video in the channel
//    if ([self.currentDeduplicatedEntries count] <= (NSUInteger)self.currentlyPlayingIndexInChannel+1) {
//        [self loadMoreEntriesInChannel:self.currentChannel
//                            sinceEntry:[self.currentDeduplicatedEntries lastObject]];
//    } else {
//        //TODO iPad
//        //TODO - warm video extraction cache for the next entity
//        //       this is why AirPlay doesn't rock on iPhone when we advance beyond cached URLs
//    }
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
    if (!self.videoReel) {
        return;
    }
    
    if (!self.airPlayController.isAirPlayActive){
        [self.videoReel pauseCurrentPlayer];
    }
    
    [self.videoReel shutdown];
    [self.videoReel willMoveToParentViewController:nil];
    [self.videoReel.view removeFromSuperview];
    [self.videoReel removeFromParentViewController];
    self.videoReel = nil;
}

- (void)presentVideoReelWithChannel:(DisplayChannel *)channel
                     deduplicatedEntries:(NSArray *)deduplicatedChannelEntries
                            atIndex:(NSUInteger)videoStartIndex
{
    self.videoReel = ({
        SPVideoReel *reel = [[SPVideoReel alloc] initWithChannel:channel andVideoEntities:deduplicatedChannelEntries atIndex:videoStartIndex];
        reel.delegate = self;
        reel.videoPlaybackDelegate = self.videoControlsVC;
        reel.view.frame = self.view.bounds;
        reel;
    });
    
    [self addChildViewController:self.videoReel];
    [self.view insertSubview:self.videoReel.view belowSubview:self.videoControlsVC.view];
    [self.videoReel didMoveToParentViewController:self];
    
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTapOnVideoReelDetected:)];
    [self.videoReel addGestureRecognizer:singleTap];
}

- (void)showAirPlayViewMode:(BOOL)airplayMode
{
    if (airplayMode) {
        if (self.videoControlsVC.displayMode == VideoControlsDisplayForAirPlay) {
            return;
        }
        //enter airplay mode
        [UIView animateWithDuration:0.2 animations:^{
            self.videoControlsVC.view.alpha = 1.f;
            self.videoControlsVC.displayMode = VideoControlsDisplayForAirPlay;
        }];
        
    } else {
        //exit airplay mode
        STVDebugAssert(self.videoControlsVC.displayMode == VideoControlsDisplayForAirPlay, @"shouldn't exit airplay when not in airplay");
        [UIView animateWithDuration:0.2 animations:^{
            self.videoControlsVC.displayMode = VideoControlsDisplayActionsAndPlaybackControls;
        }];
        
        //TODO iPad - put the video reel back in place?
    }
}

@end
