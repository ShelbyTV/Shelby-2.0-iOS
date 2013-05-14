//
//  SPVideoReel.m
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 11/1/12.
//  Copyright (c) 2012 Shelby TV. All rights reserved.
//

#import "SPVideoReel.h"
#import "DeviceUtilities.h"
#import "FacebookHandler.h"
#import "Frame+Helper.h"
#import "GAI.h"
#import <QuartzCore/QuartzCore.h>
#import "SPShareController.h"
#import "SPChannelPeekView.h"
#import "SPOverlayView.h"
#import "SPTutorialView.h"
#import "SPVideoExtractor.h"
#import "TwitterHandler.h"
#import "TwitterHandler.h"


#define kShelbySPSlowSpeed 0.2
#define kShelbySPFastSpeed 0.5
#define kShelbyTutorialIntervalBetweenTutorials 3

@interface SPVideoReel ()

@property (weak, nonatomic) SPOverlayView *overlayView;
@property (nonatomic) UIScrollView *videoScrollView;
//Array of DashboardEntry or Frame
@property (nonatomic) NSMutableArray *videoEntities;
@property (nonatomic, strong) DisplayChannel *channel;
@property (nonatomic) NSMutableArray *videoPlayers;
@property (copy, nonatomic) NSString *channelID;
@property (assign, nonatomic) NSUInteger *videoStartIndex;
@property (assign, nonatomic) BOOL fetchingOlderVideos;
@property (assign, nonatomic) BOOL loadingOlderVideos;
@property (nonatomic) SPChannelPeekView *peelChannelView;
@property (nonatomic) SPTutorialView *tutorialView;
@property (nonatomic, assign) NSInteger currentVideoPlayingIndex;
@property (nonatomic, weak) SPVideoPlayer *currentPlayer;
@property (nonatomic, strong) NSMutableArray *possiblyPlayablePlayers;
@property (assign, nonatomic) SPTutorialMode tutorialMode;
@property (nonatomic, strong) SPShareController *shareController;

// Make sure we let user roll immediately after they log in.
@property (nonatomic) NSInvocation *invocationMethod;

/// Action Methods
- (IBAction)shareButtonAction:(id)sender;
- (IBAction)likeAction:(id)sender;
- (IBAction)rollAction:(id)sender;
- (void)rollVideo;

@end

typedef enum {
    SPVideoReelPreloadStrategyNotSet        = -1,
    SPVideoReelPreloadNone                  = 0,
    SPVideoReelPreloadNextOnly              = 1,
    SPVideoReelPreloadNextKeepPrevious      = 2,
    SPVideoReelPreloadNextTwoKeepPrevious   = 3,
    SPVideoReelPreloadNextThreeKeepPrevious = 4
} SPVideoReelPreloadStrategy;
static SPVideoReelPreloadStrategy preloadStrategy = SPVideoReelPreloadStrategyNotSet;

@implementation SPVideoReel

#pragma mark - Memory Management
- (void)dealloc
{
    [self removeObservers];
}

#pragma mark - Initialization
- (id) initWithChannel:(DisplayChannel *)channel
      andVideoEntities:(NSArray *)videoEntities
               atIndex:(NSUInteger)videoStartIndex
{
    self = [super init];
    if (self) {
        _channel = channel;
        _videoEntities = [videoEntities mutableCopy];
        _videoStartIndex = videoStartIndex;
        _currentVideoPlayingIndex = -1;
    }

    return self;
}

#pragma mark - View Lifecycle Methods
- (void)viewDidLoad
{
    [super viewDidLoad];
 
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    [self.view setFrame:CGRectMake(0.0f, 0.0f, kShelbySPVideoWidth, kShelbySPVideoHeight)];
    [self.view setBackgroundColor:[UIColor blackColor]];
    
    _peelChannelView = [[SPChannelPeekView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    
    if ([self.delegate conformsToProtocol:@protocol(SPVideoReelDelegate)] && [self.delegate respondsToSelector:@selector(tutorialModeForCurrentPlayer)]) {
        self.tutorialMode = [self.delegate tutorialModeForCurrentPlayer];
    }

    [self setup];
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    if (self.tutorialMode == SPTutorialModeShow) {
        [self performSelector:@selector(showDoubleTapTutorial) withObject:nil afterDelay:kShelbyTutorialIntervalBetweenTutorials];
     } else if (self.tutorialMode == SPTutorialModePinch) {
        [self performSelector:@selector(showPinchTutorial) withObject:nil afterDelay:kShelbyTutorialIntervalBetweenTutorials];
    }
}

#pragma mark - Setup Methods
- (void)setup
{
    id defaultTracker = [GAI sharedInstance].defaultTracker;
    [defaultTracker sendEventWithCategory:kGAICategoryBrowse
                               withAction:kGAIBrowseActionLaunchPlaylist
                                withLabel:_groupTitle
                                withValue:nil];
    
    [self setTrackedViewName:[NSString stringWithFormat:@"Playlist - %@", _groupTitle]];
    
    if ( !_videoPlayers ) {
        self.videoPlayers = [@[] mutableCopy];
    }
    
    [self setupVideoPreloadStrategy];
    [self setupObservers];
    [self setupVideoScrollView];
    [self setupOverlayView];
    [self setupGestures];
    
    [self setupVideoPlayers];
    [self currentVideoShouldChangeToVideo:self.videoStartIndex];
    
    [self setupAirPlay];
    [self setupOverlayVisibileItems];

}

- (void)setupObservers
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(dataSourceShouldUpdateFromWeb:)
                                                 name:kShelbySPUserDidScrollToUpdate
                                               object:nil];
}

- (void)removeObservers
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kShelbySPUserDidScrollToUpdate
                                                  object:nil];
}

- (void)setupVideoScrollView
{
    if (!self.videoScrollView) {
        _videoScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, kShelbySPVideoWidth, kShelbySPVideoHeight)];
        self.videoScrollView.delegate = self;
        self.videoScrollView.pagingEnabled = YES;
        self.videoScrollView.showsHorizontalScrollIndicator = NO;
        self.videoScrollView.showsVerticalScrollIndicator = NO;
        self.videoScrollView.scrollsToTop = NO;
        [self.videoScrollView setDelaysContentTouches:YES];
        [self.view addSubview:self.videoScrollView];
    }
    
    self.videoScrollView.contentSize = CGSizeMake(kShelbySPVideoWidth * [self.videoEntities count], kShelbySPVideoHeight);
    [self.videoScrollView setContentOffset:CGPointMake(kShelbySPVideoWidth * (int)self.videoStartIndex, 0) animated:YES];
}

- (void)setupOverlayView
{
    STVAssert(!self.overlayView, @"should only setup overlay view once");
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"SPOverlayView" owner:self options:nil];
    STVAssert([nib isKindOfClass:[NSArray class]] && [nib count] > 0 && [nib[0] isKindOfClass:[UIView class]], @"bad overlay view nib");
    self.overlayView = nib[0];
    self.overlayView.alpha = 0;
    self.overlayView.delegate = self;
    [self.view addSubview:self.overlayView];
    [self.overlayView setAccentColor:self.channel.displayColor];
}

//called via -setup via -viewDidLoad
- (void)setupVideoPlayers
{
    if ([self.videoEntities count]) {
        NSInteger i = 0;
        for(id videoEntry in self.videoEntities){
            CGRect viewframe = [self.videoScrollView frame];
            viewframe.origin.x = viewframe.size.width * i;
            viewframe.origin.y = 0.0f;
            SPVideoPlayer *player;
            if([videoEntry isKindOfClass:[DashboardEntry class]]){
                player = [[SPVideoPlayer alloc] initWithBounds:viewframe withVideoFrame:((DashboardEntry *)videoEntry).frame];
            } else if([videoEntry isKindOfClass:[Frame class]]){
                player = [[SPVideoPlayer alloc] initWithBounds:viewframe withVideoFrame:((Frame *)videoEntry)];
            } else {
                STVAssert(false, @"expected videoEntry to be a DashboardEntry or Frame");
            }
            player.videoPlayerDelegate = self;
            [self.videoPlayers addObject:player];
            [self.videoScrollView addSubview:player.view];
            
            i++;
        }
    }
}

- (void)setupAirPlay
{
    // Instantiate AirPlay button for MPVolumeView
    MPVolumeView *volumeView = [[MPVolumeView alloc] initWithFrame:_overlayView.airPlayView.bounds];
    [volumeView setShowsVolumeSlider:NO];
    [volumeView setShowsRouteButton:YES];
    [self.overlayView.airPlayView addSubview:volumeView];
    
    for (UIView *view in volumeView.subviews) {
        
        if ( [view isKindOfClass:[UIButton class]] ) {
            
            self.airPlayButton = (UIButton *)view;
            
        }
    }
}

- (void)setupGestures
{
    STVAssert(![[self.view gestureRecognizers] containsObject:self.toggleOverlayGesuture], @"should only setup gestures once");

    //hide/shower overlay (single tap)
    _toggleOverlayGesuture = [[UITapGestureRecognizer alloc] initWithTarget:_overlayView action:@selector(toggleOverlay)];
    [self.toggleOverlayGesuture setNumberOfTapsRequired:1];
    [self.toggleOverlayGesuture setDelegate:self];
    [self.toggleOverlayGesuture requireGestureRecognizerToFail:self.overlayView.scrubberGesture];
    [self.view addGestureRecognizer:self.toggleOverlayGesuture];

    //change channels (pan vertically)
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panView:)];
    panGesture.minimumNumberOfTouches = 1;
    panGesture.maximumNumberOfTouches = 1;
    [self.view addGestureRecognizer:panGesture];
    
    //change video (pan horizontallay)
    //handled by self.videoScrollView.panGestureRecognizer
    
    //exit (pinch)
    UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchAction:)];
    [self.view addGestureRecognizer:pinchGesture];

    //play/pause (double tap)
    UITapGestureRecognizer *togglePlaybackGesuture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(togglePlayback:)];
    [togglePlaybackGesuture setNumberOfTapsRequired:2];
    [self.view addGestureRecognizer:togglePlaybackGesuture];
    [self.toggleOverlayGesuture requireGestureRecognizerToFail:togglePlaybackGesuture];
    
    //update scroll view to better interact with the above gesure recognizers
    STVAssert(self.videoScrollView && self.videoScrollView.panGestureRecognizer, @"scroll view should be initialized");
    self.videoScrollView.panGestureRecognizer.minimumNumberOfTouches = 1;
    self.videoScrollView.panGestureRecognizer.maximumNumberOfTouches = 1;
    self.videoScrollView.pinchGestureRecognizer.enabled = NO;
}

- (void)setupOverlayVisibileItems
{
    //djs use our model
//    if ([self.model numberOfVideos]) {
//        [self.overlayView showVideoInfo];
//    } else {
//        [self.overlayView hideVideoInfo];
//    }
}

- (void)shutdown
{
    [[SPVideoExtractor sharedInstance] cancelRemainingExtractions];
    
    //resetting all possibly playable players (including current player) will pause and free memory of AVPlayer
    //not entirely true: if the player has an extraction pending, that block holds a reference to the player
    //but resetPlayer: is respected by that block; it will do nothing if it's player has been reset.
    [self.possiblyPlayablePlayers makeObjectsPerformSelector:@selector(resetPlayer)];
}

- (void)animatePlaybackState:(BOOL)videoPlaying
{
    NSString *imageName = nil;
    if (videoPlaying) {
        imageName =  @"pauseButton.png";
    } else {
        imageName = @"playButton.png";
    }
    
    UIImageView *playPauseImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:imageName]];
    [playPauseImage setContentMode:UIViewContentModeScaleAspectFill];
    [self.view addSubview:playPauseImage];
    [self.view bringSubviewToFront:playPauseImage];
    
    CGRect startFrame = CGRectMake((kShelbySPVideoWidth - playPauseImage.frame.size.width) / 2, (kShelbySPVideoHeight - playPauseImage.frame.size.height) / 2, playPauseImage.frame.size.width, playPauseImage.frame.size.height);
    
    [playPauseImage setFrame:startFrame];
    
    CGRect endFrame = CGRectMake(startFrame.origin.x - startFrame.size.width, startFrame.origin.y - startFrame.size.height, startFrame.size.width * 4, startFrame.size.height * 4);
    [UIView animateWithDuration:1 animations:^{
        [playPauseImage setFrame:endFrame];
        [playPauseImage setAlpha:0];
    } completion:^(BOOL finished) {
        [playPauseImage removeFromSuperview];
    }];
}


- (void)togglePlayback:(UIGestureRecognizer *)recognizer
{
    if (self.tutorialMode == SPTutorialModeDoubleTap) {
        [self videoDoubleTapped];
    }
    
    [self animatePlaybackState:self.currentPlayer.isPlaying];

    [self.currentPlayer togglePlayback];
}

- (void)scrubToPercent:(CGFloat)scrubPct
{
    [self.currentPlayer scrubToPct:scrubPct];
}

#pragma mark -  Update Methods (Private)
- (void)currentVideoShouldChangeToVideo:(NSUInteger)position
{
    // Pause current player if there is one
    SPVideoPlayer *previousPlayer = self.currentPlayer;
    self.currentPlayer = nil;
    if (previousPlayer) {
        previousPlayer.shouldAutoplay = NO;
        [previousPlayer pause];
    }
    
    //update overlay
    //FUN: if we had a direction from which the new video was coming, could animate this update
    [self.overlayView showOverlayView];
    [self.overlayView setFrameOrDashboardEntry:self.videoEntities[position]];
    
    // Set the new current player to auto play and get it going...
    self.currentVideoPlayingIndex = position;
    self.currentPlayer = self.videoPlayers[self.currentVideoPlayingIndex];
    
    // If we are in Tutorial Show Mode, we want the video to be paused.
    if (self.tutorialMode != SPTutorialModeShow) {
        self.currentPlayer.shouldAutoplay = YES;
    }
    [self.currentPlayer prepareForStreamingPlayback];
    
    [self manageLoadedVideoPlayersForCurrentPlayer:self.currentPlayer
                                    previousPlayer:previousPlayer];
    [self warmURLExtractionCache];
}

#pragma mark - Video Preload Strategery

/* --Performance testing notes--
 * TEST: DS, ipad Mini 1 w/ SPVideoReelPreloadNextOnly, 5/9/13
 * NB:   NSZombieEnabled=YES -- so this test is more of a worst-case scenario
 * RESULT:
 *  Received occasional memory warning when returning to browse view from video reel,
 *  but generally it ran very well.
 *
 */
- (void)setupVideoPreloadStrategy
{
    if (preloadStrategy == SPVideoReelPreloadStrategyNotSet) {
        if ([[UIScreen mainScreen] isRetinaDisplay]) {
            //TODO: determine best preload strategy for iPad Retina
            preloadStrategy = SPVideoReelPreloadNextThreeKeepPrevious;
            DLog(@"Preload strategy: next 3, keep previous");
        } else if ([DeviceUtilities isIpadMini1]) {
            preloadStrategy = SPVideoReelPreloadNextOnly;
            DLog(@"Preload strategy: next only");
        } else {
            //TODO: determine best preload strategy for iPad2,3
            preloadStrategy = SPVideoReelPreloadNextKeepPrevious;
            DLog(@"Preload strategy: next 1, keep previous");
        }
    }
}

- (void)didReceiveMemoryWarning
{
    DLog(@"Dumping all but current player, degrading video preload strategy");
    [self degradeVideoPreloadStrategy];
}

- (void)degradeVideoPreloadStrategy
{
    if(preloadStrategy > SPVideoReelPreloadNone){
        preloadStrategy--;
    }
    [self manageLoadedVideoPlayersForCurrentPlayer:self.currentPlayer
                                    previousPlayer:nil];
}

- (void)manageLoadedVideoPlayersForCurrentPlayer:(SPVideoPlayer *)currentPlayer previousPlayer:(SPVideoPlayer *)previousPlayer
{
    NSMutableArray *playersToKeep = [@[] mutableCopy];
    SPVideoPlayer *additionalPlayer;
    
    //progressively build up playerToKeep
    switch (preloadStrategy) {
        case SPVideoReelPreloadNextThreeKeepPrevious:
            additionalPlayer = [self preloadPlayerAtIndex:self.currentVideoPlayingIndex+3];
            if(additionalPlayer){ [playersToKeep addObject:additionalPlayer]; }
            
        case SPVideoReelPreloadNextTwoKeepPrevious:
            additionalPlayer = [self preloadPlayerAtIndex:self.currentVideoPlayingIndex+2];
            if(additionalPlayer){ [playersToKeep addObject:additionalPlayer]; }
            
        case SPVideoReelPreloadNextKeepPrevious:
            if(previousPlayer){ [playersToKeep addObject:previousPlayer]; }
            
        case SPVideoReelPreloadNextOnly:
            additionalPlayer = [self preloadPlayerAtIndex:self.currentVideoPlayingIndex+1];
            if(additionalPlayer){ [playersToKeep addObject:additionalPlayer]; }
            
        case SPVideoReelPreloadNone:
        case SPVideoReelPreloadStrategyNotSet:
            [playersToKeep addObject:currentPlayer];
    }
    
    //reset players not on keep list
    if(self.possiblyPlayablePlayers){
        for(SPVideoPlayer *playerToKeep in playersToKeep){
            [self.possiblyPlayablePlayers removeObject:playerToKeep];
        }
        for(SPVideoPlayer *playerToKill in self.possiblyPlayablePlayers){
            [playerToKill resetPlayer];
        }
    }
    
    self.possiblyPlayablePlayers = playersToKeep;
}

- (SPVideoPlayer *)preloadPlayerAtIndex:(NSInteger)idx
{
    //djs TODO: indicate that we need more video!
    if(idx >= [self.videoPlayers count]){
        return nil;
    }
    
    SPVideoPlayer *player = self.videoPlayers[idx];
    if(player){
        player.shouldAutoplay = NO;
        [player prepareForStreamingPlayback];
    }
    return player;
}

- (void)warmURLExtractionCache
{
    //every time video changes, warm up the cache for the next 10 videos
    int maxI = MIN(self.currentVideoPlayingIndex+10, [self.videoPlayers count]);
    for(int i = self.currentVideoPlayingIndex; i < maxI; i++){
        SPVideoPlayer *player = self.videoPlayers[i];
        [player warmVideoExtractionCache];
    }
}

#pragma mark - Action Methods (Private)
- (IBAction)shareButtonAction:(id)sender
{
    UIButton *shareButton = (UIButton *)sender;
    STVAssert([shareButton isKindOfClass:[UIButton class]], @"VideoReel expecting share button");
    
    self.shareController = [[SPShareController alloc] initWithVideoPlayer:self.videoPlayers[self.currentVideoPlayingIndex]
                                                                 fromRect:shareButton.frame];
    [self.shareController share];
    
}

- (IBAction)likeAction:(id)sender
{
    SPVideoPlayer *currentPlayer = self.videoPlayers[self.currentVideoPlayingIndex];
    BOOL didLike = [currentPlayer.videoFrame toggleLike];
    [self.overlayView didLikeCurrentEntry:didLike];
}

- (IBAction)rollAction:(id)sender
{
    if (![[NSUserDefaults standardUserDefaults] boolForKey:kShelbyDefaultUserAuthorized]) {
 
        // KP KP: TODO: invoke this after user logs in.
        // Setting invocation, so we would roll immediately after user logs in.
        NSMethodSignature *rollSignature = [SPVideoReel instanceMethodSignatureForSelector:@selector(rollVideo)];
        NSInvocation *rollInvocation = [NSInvocation invocationWithMethodSignature:rollSignature];
        [rollInvocation setTarget:self];
        [rollInvocation setSelector:@selector(rollVideo)];
        [self setInvocationMethod:rollInvocation];
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:@"You need to be logged in to roll" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Login", nil];
        [alertView show];
        
    } else {
        [self rollVideo];
    }
}

- (void)rollVideo
{
    // TODO
}


- (void)hideOverlayView
{
    [self.overlayView hideOverlayView];
}
#pragma mark - Gesutre Methods (Private)
- (void)switchChannelWithDirectionUp:(BOOL)up
{
    if (self.tutorialView) {
        [self.tutorialView setAlpha:0];
    }
    
    if (self.delegate && [self.delegate conformsToProtocol:@protocol(SPVideoReelDelegate)]) {
        [self.delegate userDidSwitchChannelForDirectionUp:up];
    }
}

- (void)panView:(UIPanGestureRecognizer *)gestureRecognizer
{
    if (![gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
        return;
    }
    
    SPVideoPlayer *currentPlayer = self.videoPlayers[self.currentVideoPlayingIndex];
    
    NSInteger y = currentPlayer.view.frame.origin.y;
    NSInteger x = currentPlayer.view.frame.origin.x;
    CGPoint translation = [gestureRecognizer translationInView:self.view];
    
    BOOL peekUp = y >= 0 ? YES : NO;
    DisplayChannel *dispalayChannel = nil;
    if (self.delegate && [self.delegate conformsToProtocol:@protocol(SPVideoReelDelegate)]) {
       dispalayChannel =  [self.delegate displayChannelForDirection:peekUp];
    }

    int peekHeight = peekUp ? y : -1 * y;
    int yOriginForPeekView = peekUp ? 0 : 768 - peekHeight;
    CGRect peekViewRect = peekViewRect = CGRectMake(0, yOriginForPeekView, kShelbySPVideoWidth, peekHeight);
    
    [self.peelChannelView setupWithChannelDisplay:dispalayChannel];
    if ([gestureRecognizer state] == UIGestureRecognizerStateBegan) {
        [self.view addSubview:self.peelChannelView];
    }
    
    if ([gestureRecognizer state] == UIGestureRecognizerStateBegan || [gestureRecognizer state] == UIGestureRecognizerStateChanged) {
        currentPlayer.view.frame = CGRectMake(x, y + translation.y, currentPlayer.view.frame.size.width, currentPlayer.view.frame.size.height);
        self.overlayView.frame = CGRectMake(self.overlayView.frame.origin.x, y + translation.y, self.overlayView.frame.size.width, self.overlayView.frame.size.height);
        self.peelChannelView.frame = peekViewRect;
        
        [gestureRecognizer setTranslation:CGPointZero inView:self.view];
    } else if ([gestureRecognizer state] == UIGestureRecognizerStateEnded) {
        CGPoint velocity = [gestureRecognizer velocityInView:self.view];
        NSInteger currentY = y + translation.y;
        if (velocity.y < -200) {
            if (-1 * currentY < kShelbySPVideoHeight / 11) {
                [self animateUp:kShelbySPFastSpeed andSwitchChannel:NO];
            } else {
                [self animateUp:kShelbySPFastSpeed andSwitchChannel:YES];
            }
        } else if (velocity.y > 200) {
            if (currentY < kShelbySPVideoHeight / 11) {
                [self animateDown:kShelbySPFastSpeed andSwitchChannel:NO];
            } else {
                [self animateDown:kShelbySPFastSpeed andSwitchChannel:YES];
            }
        } else {
            if (currentY > 0) {
                if (currentY < 3 * kShelbySPVideoHeight / 4) {
                    [self animateUp:kShelbySPSlowSpeed andSwitchChannel:NO];
                } else {
                    [self animateDown:kShelbySPSlowSpeed andSwitchChannel:YES];
                }
            } else if (-1 * currentY < 3 * kShelbySPVideoHeight / 4) {
                [self animateDown:kShelbySPSlowSpeed andSwitchChannel:NO];
            } else {
                [self animateUp:kShelbySPSlowSpeed andSwitchChannel:YES];
            }
        }
    }
}

- (void)animateDown:(float)speed andSwitchChannel:(BOOL)switchChannel
{
    SPVideoPlayer *currentPlayer = self.videoPlayers[self.currentVideoPlayingIndex];
    CGRect currentPlayerFrame = currentPlayer.view.frame;
    
    NSInteger finalyYPosition = switchChannel ? self.view.frame.size.height : 0;
    CGRect peekViewFrame;
    if (switchChannel) {
        peekViewFrame = CGRectMake(0, 0, 1024, 768);
    } else {
        CGFloat finalyY = self.peelChannelView.frame.origin.y;
        if (finalyY != 0) {
            finalyY = 768;
        }
        peekViewFrame = CGRectMake(0, finalyY, 1024, 0);
    }
    
    [UIView animateWithDuration:speed delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
       [currentPlayer.view setFrame:CGRectMake(currentPlayerFrame.origin.x, finalyYPosition, currentPlayerFrame.size.width, currentPlayerFrame.size.height)];
        [self.overlayView setFrame:CGRectMake(self.overlayView.frame.origin.x, finalyYPosition, currentPlayerFrame.size.width, currentPlayerFrame.size.height)];
        [self.peelChannelView setFrame:peekViewFrame];
    } completion:^(BOOL finished) {
        if (switchChannel) {
            [self switchChannelWithDirectionUp:YES];
        }
        [self.peelChannelView removeFromSuperview];
    }];
}

- (void)animateUp:(float)speed andSwitchChannel:(BOOL)switchChannel
{
    SPVideoPlayer *currentPlayer = self.videoPlayers[self.currentVideoPlayingIndex];
    CGRect currentPlayerFrame = currentPlayer.view.frame;
    
    NSInteger finalyYPosition = switchChannel ? -self.view.frame.size.height : 0;
    CGRect peekViewFrame;
    if (switchChannel) {
        peekViewFrame = CGRectMake(0, 0, 1024, 768);
    } else {
        CGFloat finalyY = self.peelChannelView.frame.origin.y;
        if (finalyY != 0) {
            finalyY = 768;
        }
        peekViewFrame = CGRectMake(0, finalyY, 1024, 0);
    }

    [UIView animateWithDuration:speed delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
       [currentPlayer.view setFrame:CGRectMake(currentPlayerFrame.origin.x, finalyYPosition, currentPlayerFrame.size.width, currentPlayerFrame.size.height)];
        [self.overlayView setFrame:CGRectMake(self.overlayView.frame.origin.x, finalyYPosition, currentPlayerFrame.size.width, currentPlayerFrame.size.height)];
        [self.peelChannelView setFrame:peekViewFrame];
    } completion:^(BOOL finished) {
        if (switchChannel) {
            [self switchChannelWithDirectionUp:NO];
        }
        [self.peelChannelView removeFromSuperview];
    }];
}

- (void)pinchAction:(UIPinchGestureRecognizer *)gestureRecognizer
{
    if (![gestureRecognizer isKindOfClass:[UIPinchGestureRecognizer class]]) {
        return;
    }
    
    if ([gestureRecognizer state] == UIGestureRecognizerStateBegan) {
        if (self.delegate && [self.delegate conformsToProtocol:@protocol(SPVideoReelDelegate)]) {
            [self.delegate userDidCloseChannelAtFrame:self.currentPlayer.videoFrame];
        }
    }
}

#pragma mark - Tutorial Methods
- (BOOL)tutorialSetup
{
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"SPTutorialView" owner:self options:nil];
    if ([nib isKindOfClass:[NSArray class]] && [nib count] != 0 && [nib[0] isKindOfClass:[UIView class]]) {
        [self setTutorialView:nib[0]];
        [self.tutorialView setAlpha:0];
        [self.view addSubview:self.tutorialView];
        [self.tutorialView setFrame:CGRectMake(kShelbySPVideoWidth / 2 - self.tutorialView.frame.size.width/2, self.view.frame.size.height / 2 - kShelbySPVideoHeight / 2 - 30, self.tutorialView.frame.size.width, self.tutorialView.frame.size.height)];
        
        [self.view bringSubviewToFront:self.tutorialView];
        
        [self.tutorialView.layer setCornerRadius:10];
        [self.tutorialView.layer setMasksToBounds:YES];
        
        return YES;
    }
    
    return NO;
}

- (void)showDoubleTapTutorial
{
    if ([self tutorialSetup]) {
        [self setTutorialMode:SPTutorialModeDoubleTap];
        [UIView animateWithDuration:0.2 animations:^{
            [self.tutorialView setAlpha:0.9];
        }];
    }
}

- (void)videoDoubleTapped
{
    if (self.tutorialMode == SPTutorialModeDoubleTap) {
        [UIView animateWithDuration:0.2 animations:^{
            [self.tutorialView setAlpha:0];
        } completion:^(BOOL finished) {
            [self setTutorialMode:SPTutorialModeShow];
            [self performSelector:@selector(showSwipeLeftTutorial) withObject:nil afterDelay:kShelbyTutorialIntervalBetweenTutorials];            
        }];
    }
}

- (void)videoSwipedLeft
{
    [UIView animateWithDuration:0.2 animations:^{
        [self.tutorialView setAlpha:0];
    } completion:^(BOOL finished) {
        [self setTutorialMode:SPTutorialModeShow];
        [self performSelector:@selector(showSwipeUpTutorial) withObject:nil afterDelay:kShelbyTutorialIntervalBetweenTutorials];
    }];
}

- (void)videoSwipedUp
{
    if (self.tutorialMode == SPTutorialModeSwipeUp) {
        [UIView animateWithDuration:0.2 animations:^{
            [self.tutorialView setAlpha:0];
        } completion:^(BOOL finished) {
            [self setTutorialMode:SPTutorialModeShow];
            [self performSelector:@selector(showSwipeUpTutorial) withObject:nil afterDelay:kShelbyTutorialIntervalBetweenTutorials];
        }];
    }
}

- (void)showSwipeLeftTutorial
{
    [self setTutorialMode:SPTutorialModeSwipeLeft];
    [self.tutorialView setupWithImage:@"swipeleft.png" andText:@"Swipe left to play next video in this channel"];
    [UIView animateWithDuration:0.2 animations:^{
        [self.tutorialView setAlpha:0.9];
    }];
}

- (void)showSwipeUpTutorial
{
    [self setTutorialMode:SPTutorialModeSwipeUp];
    [self.tutorialView setupWithImage:@"swipeup.png" andText:@"Swipe up to change the channel"];
    [UIView animateWithDuration:0.2 animations:^{
        [self.tutorialView setAlpha:0.9];
    }];    
}

- (void)showPinchTutorial
{
    if ([self tutorialSetup]) {
        [self.tutorialView setupWithImage:@"pinch.png" andText:@"Pinch to close current channel"];
        [UIView animateWithDuration:0.2 animations:^{
            [self.tutorialView setAlpha:0.9];
        }];
    }
}


#pragma mark - SPVideoPlayerDelegete Methods

- (void)videoDidFinishPlayingForPlayer:(SPVideoPlayer *)player{
    [self changeVideoInForwardDirection:YES];
}

- (void)videoDidStallForPlayer:(SPVideoPlayer *)player
{
    if (self.currentPlayer == player) {
        [player pause];
        [self.overlayView showOverlayView];
        //djs TODO: a nice, subtle notification
        //djs IMPORTANT: this is more likely to happen when you seek beyond the buffer
        //** need to handle that case nicely, not just the "normal playback" stalled case
        /* Idea:
         * Keep track of the current playhead and the amount buffered beyond it.
         * Have a fun little view that shows something filling up, getting ready to resume playback!
         * 
         * Focus more time than seems necessary on this, b/c it makes watching a single video very enjoyable.
         */
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Downloading... Slowly..."
                                                            message:@"Give it a little time to buffer.  Then double-tap to resume playback."
                                                           delegate:nil
                                                  cancelButtonTitle:@"whatever"
                                                  otherButtonTitles:nil, nil];
        [alertView show];
    }
}

- (void)videoLoadingStatus:(BOOL)isLoading forPlayer:(SPVideoPlayer *)player
{
    //djs TODO
}

- (void)videoBufferedRange:(CMTimeRange)bufferedRange forPlayer:(SPVideoPlayer *)player
{
    if (self.currentPlayer == player) {
        [self.overlayView updateBufferedRange:bufferedRange];
    }
}

- (void)videoDuration:(CMTime)duration forPlayer:(SPVideoPlayer *)player
{
    if (self.currentPlayer == player) {
        [self.overlayView setDuration:duration];
    }
}

- (void)videoCurrentTime:(CMTime)time forPlayer:(SPVideoPlayer *)player
{
    if (self.currentPlayer == player) {
        [self.overlayView updateCurrentTime:time];
    }
}

- (void)videoPlaybackStatus:(BOOL)isPlaying forPlayer:(SPVideoPlayer *)player
{
    //noop for now
}

- (void)videoExtractionFailForAutoplayPlayer:(SPVideoPlayer *)player
{
    if (self.currentPlayer == player) {
        //djs TODO: a real error and auto-skip
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Problem Video"
                                                            message:@"It won't play right now, so annoying.  Swipe it away..."
                                                           delegate:nil
                                                  cancelButtonTitle:@"whatever"
                                                  otherButtonTitles:nil, nil];
        [alertView show];
        //djs TODO: when user hits OK:
        //[self changeVideoInForwardDirection:YES];
    }
}

- (BOOL)changeVideoInForwardDirection:(BOOL)forward
{
    NSUInteger idx = self.currentVideoPlayingIndex + (forward ? 1 : -1);
    if (idx > 0 && idx < [self.videoEntities count]) {
        CGFloat videoX = idx * kShelbySPVideoWidth;
        CGFloat videoY = self.videoScrollView.contentOffset.y;
        [self.videoScrollView setContentOffset:CGPointMake(videoX, videoY) animated:YES];
        [self currentVideoShouldChangeToVideo:idx];
        return YES;
    } else {
        return NO;
    }
}


#pragma mark - UIScrollViewDelegate Methods
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    //djs fix when we have our model and view controllers
    
    // Switch the indicator when more than 50% of the previous/next page is visible
    CGFloat pageWidth = scrollView.frame.size.width;
    CGFloat scrollAmount = (scrollView.contentOffset.x - pageWidth / 2) / pageWidth;
    NSUInteger page = floor(scrollAmount) + 1;
    
//    // Toggle playback on old and new SPVideoPlayer objects
    if (page == self.currentVideoPlayingIndex) {
        return;
    }

//    [self.videoPlayers makeObjectsPerformSelector:@selector(pause)];
    
    [self currentVideoShouldChangeToVideo:page];
    
    if (self.tutorialMode == SPTutorialModeSwipeLeft) {
        // Doesn't really matter which direction the user swiped - just indicate the user passed the 'SwipeLeft' tutorial
        [self videoSwipedLeft];
    }

//    [self fetchOlderVideos:page];
//
//    // Send event to Google Analytics
//    id defaultTracker = [GAI sharedInstance].defaultTracker;
//    [defaultTracker sendEventWithCategory:kGAICategoryVideoPlayer
//                               withAction:kGAIVideoPlayerActionSwipeHorizontal
//                                withLabel:_groupTitle
//                                withValue:nil];
}

@end
