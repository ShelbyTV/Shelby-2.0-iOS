//
//  SPVideoReel.m
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 11/1/12.
//  Copyright (c) 2012 Shelby TV. All rights reserved.
//

#import "SPVideoReel.h"

#import <CoreMedia/CoreMedia.h>
#import "DashboardEntry+Helper.h"
#import "DeviceUtilities.h"
#import "FacebookHandler.h"
#import "Frame+Helper.h"
#import "GAI.h"
#import <MediaPlayer/MediaPlayer.h>
#import <QuartzCore/QuartzCore.h>
#import "ShelbyAlertView.h"
#import "SPChannelPeekView.h"
#import "SPTutorialView.h"
#import "SPVideoExtractor.h"
#import "TwitterHandler.h"
#import "TwitterHandler.h"
#import "UIScreen+Resolution.h"


#define kShelbySPSlowSpeed 0.2
#define kShelbySPFastSpeed 0.5
#define kShelbyTutorialIntervalBetweenTutorials 3

//only show the stalled alert view if it hasn't shown in this much time
#define VIDEO_STALLED_MIN_TIME_BETWEEN_ALERTS -60 // 1m

#define kShelbyFirstTimeLikedAlert @"kShelbyFirstTimeLikedAlert"

@interface SPVideoReel ()

@property (nonatomic) UIScrollView *videoScrollView;
//Array of DashboardEntry or Frame, technically: id<ShelbyVideoContainer>
@property (nonatomic) NSMutableArray *videoEntities;
@property (nonatomic) NSMutableArray *videoPlayers;
@property (copy, nonatomic) NSString *channelID;
@property (assign, nonatomic) NSUInteger *videoStartIndex;
@property (assign, nonatomic) BOOL fetchingOlderVideos;
@property (assign, nonatomic) BOOL loadingOlderVideos;
@property (nonatomic) SPChannelPeekView *peelChannelView;
@property (nonatomic) SPTutorialView *tutorialView;
@property (nonatomic, strong) NSTimer *tutorialTimer;
@property (nonatomic, assign) NSUInteger currentVideoPlayingIndex;
@property (atomic, weak) SPVideoPlayer *currentPlayer;
@property (nonatomic, strong) NSMutableArray *possiblyPlayablePlayers;
@property (assign, nonatomic) SPTutorialMode tutorialMode;
@property (nonatomic, assign) BOOL isShutdown;
@property (nonatomic, strong) NSDate *lastVideoStalledAlertTime;

//allows us to dismiss alert view if video changes or we exit
@property (nonatomic, strong) ShelbyAlertView *currentVideoAlertView;

// Make sure we let user roll immediately after they log in.
@property (nonatomic) NSInvocation *invocationMethod;

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
        _isShutdown = NO;
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
    [self.view setBackgroundColor:[UIColor blackColor]];
    
    _peelChannelView = [[SPChannelPeekView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    
    if ([self.delegate conformsToProtocol:@protocol(SPVideoReelDelegate)] && [self.delegate respondsToSelector:@selector(tutorialModeForCurrentPlayer)]) {
        self.tutorialMode = [self.delegate tutorialModeForCurrentPlayer];
    }

    // Any setup stuff that *doesn't* rely on frame sizing can go here
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    // -setup relies on our frame to correctly size the video players...
    // We used to run it in -viewDidLoad but our frame wasn't yet updated (ie. for landscape)
    // In -viewDidAppear, our frame is sized correctly and -setup will pass that down the view chain
    [self setup];

    if (self.tutorialMode == SPTutorialModeShow) {
        self.tutorialTimer = [NSTimer scheduledTimerWithTimeInterval:kShelbyTutorialIntervalBetweenTutorials target:self selector:@selector(showDoubleTapTutorial) userInfo:nil repeats:NO];
     } else if (self.tutorialMode == SPTutorialModePinch) {
         self.tutorialTimer = [NSTimer scheduledTimerWithTimeInterval:kShelbyTutorialIntervalBetweenTutorials target:self selector:@selector(showPinchTutorial) userInfo:nil repeats:NO];
    }
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskLandscape | UIInterfaceOrientationMaskPortrait;
}

-(BOOL) shouldAutorotate {
    return YES;
}


- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    //since we are subview, our view's frame is correctly set w/r/t orientation
    NSInteger height = self.view.frame.size.height;
    NSInteger width = self.view.frame.size.width;
    
    CGSize contentSize =  CGSizeMake(width, height * [self.videoPlayers count]);
    CGPoint contentOffset = CGPointMake(0, height * self.currentVideoPlayingIndex);
    
    self.videoScrollView.contentSize = contentSize;
    self.videoScrollView.contentOffset = contentOffset;
    
    NSInteger i = 0;
    for (SPVideoPlayer *player in self.videoPlayers) {
        player.view.frame = CGRectMake(0, height * i, width, height);
        i++;
    }
}
- (void)setEntries:(NSArray *)entries
{
    NSUInteger oldCount = [self.videoEntities count];
    self.videoEntities = [entries mutableCopy];
    // do some setup
    [self setupVideoScrollView];
    [self setupVideoPlayersFromIndex:oldCount];
}

#pragma mark - Setup Methods
- (void)setup
{
    [self setTrackedViewName:[NSString stringWithFormat:@"Playlist - %@", _groupTitle]];
    
    if ( !_videoPlayers ) {
        self.videoPlayers = [@[] mutableCopy];
    }
    
    [self setupVideoPreloadStrategy];
    [self setupObservers];
    [self setupVideoScrollView];
    [self setupGestures];
    
    [self setupVideoPlayersFromIndex:0];
    [self currentVideoShouldChangeToVideo:self.videoStartIndex autoplay:YES];
    
    [self setupAirPlay];
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
        _videoScrollView = [[UIScrollView alloc] initWithFrame:self.view.frame];
        self.videoScrollView.delegate = self;
        self.videoScrollView.pagingEnabled = YES;
        self.videoScrollView.showsHorizontalScrollIndicator = NO;
        self.videoScrollView.showsVerticalScrollIndicator = NO;
        self.videoScrollView.scrollsToTop = NO;
        [self.videoScrollView setDelaysContentTouches:YES];
        self.videoScrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.view addSubview:self.videoScrollView];
    }

    if (DEVICE_IPAD) {
        self.videoScrollView.contentSize = CGSizeMake(kShelbySPVideoWidth * [self.videoEntities count], kShelbySPVideoHeight);
        [self.videoScrollView setContentOffset:CGPointMake(kShelbySPVideoWidth * (int)self.videoStartIndex, 0) animated:YES];
    } else {
        CGSize contentSize;
        NSInteger videoHeight = kShelbyFullscreenHeight;
        if ([self isLandscapeOrientation]) {
            videoHeight = kShelbyFullscreenWidth;
            contentSize = CGSizeMake(kShelbyFullscreenHeight, [self.videoEntities count] * videoHeight);
        } else {
            contentSize = CGSizeMake(kShelbyFullscreenWidth, [self.videoEntities count] * videoHeight);
        }
        
        self.videoScrollView.contentSize = contentSize;
        CGPoint offset = CGPointMake(0, (int)self.videoStartIndex * videoHeight);
        [self.videoScrollView setContentOffset:offset animated:NO];
    }

    //XXX LAYOUT TESTING
//    self.videoScrollView.layer.borderColor = [UIColor redColor].CGColor;
//    self.videoScrollView.layer.borderWidth = 4.0;
    //XXX LAYOUT TESTING
}

//called via -setup via -viewDidLoad
- (void)setupVideoPlayersFromIndex:(NSUInteger)index
{
    NSUInteger count = [self.videoEntities count];
    if (count && index < count) {
        for (; index < count; index++) {
            Frame *videoEntry = self.videoEntities[index];
            CGRect viewframe = [self.videoScrollView frame];
            if (DEVICE_IPAD) {
                viewframe.origin.x = viewframe.size.width * index;
                viewframe.origin.y = 0.0f;
            } else {
                NSInteger videoHeight = kShelbyFullscreenHeight;
                if ([self isLandscapeOrientation]) {
                    videoHeight = kShelbyFullscreenWidth;
                }
                viewframe.origin.y = videoHeight * index;
                viewframe.origin.x = 0.0f;
            }
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
            [player willMoveToParentViewController:self];
            [self addChildViewController:player];
            [self.videoScrollView addSubview:player.view];
            [player didMoveToParentViewController:self];
        }
    }
}

- (void)setupAirPlay
{
    // Instantiate AirPlay button for MPVolumeView
    MPVolumeView *volumeView = [[MPVolumeView alloc] initWithFrame:self.airPlayView.bounds];
    [volumeView setShowsVolumeSlider:NO];
    [volumeView setShowsRouteButton:YES];
    [self.airPlayView addSubview:volumeView];
    
    for (UIView *view in volumeView.subviews) {
        
        if ( [view isKindOfClass:[UIButton class]] ) {
            
            self.airPlayButton = (UIButton *)view;
            
        }
    }
}

- (void)setupGestures
{
    //change channels (pan vertically)
    if (DEVICE_IPAD) {
        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panView:)];
        panGesture.minimumNumberOfTouches = 1;
        panGesture.maximumNumberOfTouches = 1;
        [self.view addGestureRecognizer:panGesture];
    }
    //change video (pan horizontallay)
    //handled by self.videoScrollView.panGestureRecognizer
    
    //exit (pinch)
    UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchAction:)];
    [self.view addGestureRecognizer:pinchGesture];
    
    // Making sure the pan gesture of the scrollView waits for Pinch to fail
    NSArray *scrollViewGestures = self.videoScrollView.gestureRecognizers;
    for (UIGestureRecognizer *gesture in scrollViewGestures) {
        if ([gesture isKindOfClass:[UIPanGestureRecognizer class]]) {
            [gesture requireGestureRecognizerToFail:pinchGesture];
        }
    }
    //play/pause (double tap)
    UITapGestureRecognizer *togglePlaybackGesuture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(togglePlayback:)];
    [togglePlaybackGesuture setNumberOfTapsRequired:2];
    [self.view addGestureRecognizer:togglePlaybackGesuture];
    
    //update scroll view to better interact with the above gesure recognizers
    STVAssert(self.videoScrollView && self.videoScrollView.panGestureRecognizer, @"scroll view should be initialized");
    self.videoScrollView.panGestureRecognizer.minimumNumberOfTouches = 1;
    self.videoScrollView.panGestureRecognizer.maximumNumberOfTouches = 1;
    self.videoScrollView.pinchGestureRecognizer.enabled = NO;
}

- (void)shutdown
{
    STVAssert(!self.isShutdown, @"shoult not already be shutdown");
    self.isShutdown = YES;
    
    [[SPVideoExtractor sharedInstance] cancelAllExtractions];
    
    //remove any alert particular to current video
    [self.currentVideoAlertView dismiss];
    
    //resetting all possibly playable players (including current player) will pause and free memory of AVPlayer
    //not entirely true: if the player has an extraction pending, that block holds a reference to the player
    //but resetPlayer: is respected by that block; it will do nothing if it's player has been reset.
    [self.possiblyPlayablePlayers makeObjectsPerformSelector:@selector(resetPlayer)];

    if (self.tutorialTimer) {
        [self.tutorialTimer invalidate];
        self.tutorialTimer = nil;
    }
}

- (BOOL)isLandscapeOrientation
{
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    return UIInterfaceOrientationIsLandscape(orientation);
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
    
    [ShelbyViewController sendEventWithCategory:kAnalyticsCategoryVideoPlayer withAction:kAnalyticsVideoPlayerActionDoubleTap withLabel:nil];
}

- (BOOL)isCurrentPlayerPlaying
{
    return self.currentPlayer.isPlaying;
}

- (BOOL)shouldCurrentPlayerBePlaying
{
    return [self.currentPlayer shouldBePlaying];
}

- (void)pauseCurrentPlayer
{
    [self.currentPlayer pause];
}

- (void)playCurrentPlayer
{
    [self.currentPlayer play];
}

- (void)scrubCurrentPlayerTo:(CGFloat)percent
{
    [self.currentPlayer scrubToPct:percent];
    
    [ShelbyViewController sendEventWithCategory:kAnalyticsCategoryVideoPlayer withAction:kAnalyticsVideoPlayerUserScrub withLabel:[NSString stringWithFormat:@"%2.2f%%", percent * 100]];
}

- (void)scrollTo:(CGPoint)contentOffset
{
    //update view only
    self.videoScrollView.contentOffset = contentOffset;
}

- (void)endDecelerating
{
    //possibly change to a new video
    CGFloat pageHeight = self.videoScrollView.frame.size.height;
    NSUInteger page = self.videoScrollView.contentOffset.y / pageHeight;

    if (page == self.currentVideoPlayingIndex) {
        return;
    }

    [self currentVideoShouldChangeToVideo:page autoplay:self.currentPlayer.isPlaying];
}

#pragma mark -  Update Methods (Private)
- (void)currentVideoShouldChangeToVideo:(NSUInteger)position autoplay:(BOOL)shouldAutoplay
{
    @synchronized(self){
        if (self.isShutdown) {
            return;
        }
        
        // Pause current player if there is one
        SPVideoPlayer *previousPlayer = self.currentPlayer;
        self.currentPlayer = nil;
        if (previousPlayer) {
            previousPlayer.shouldAutoplay = NO;
            [previousPlayer pause];
        }
        
        //remove any alert particular to current video
        [self.currentVideoAlertView dismiss];

        // Set the new current player to auto play and get it going...
        self.currentVideoPlayingIndex = position;
        self.currentPlayer = self.videoPlayers[self.currentVideoPlayingIndex];
        self.currentPlayer.shouldAutoplay = shouldAutoplay;

        [self.currentPlayer prepareForStreamingPlayback];
        
        [self manageLoadedVideoPlayersForCurrentPlayer:self.currentPlayer
                                        previousPlayer:previousPlayer];
        [self warmURLExtractionCache];

        [self.delegate didChangePlaybackToEntity:self.videoEntities[position] inChannel:self.channel];
    }
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
        if (DEVICE_IPAD) {
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
        } else {
            //TODO: determine best preload strategy for array of iPhones
            preloadStrategy = SPVideoReelPreloadNextKeepPrevious;
            DLog(@"iPhone Preload strategy: next 1, keep previous");
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

- (SPVideoPlayer *)preloadPlayerAtIndex:(NSUInteger)idx
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

- (id<ShelbyVideoContainer>)getCurrentPlaybackEntity
{
    return self.videoEntities[self.currentVideoPlayingIndex];
}

#pragma mark - Action Methods (Private)

- (IBAction)closePlayer:(id)sender
{
    if (self.delegate && [self.delegate conformsToProtocol:@protocol(SPVideoReelDelegate)]) {
        [self.delegate userDidCloseChannelAtFrame:self.currentPlayer.videoFrame];
    }
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
        self.tutorialView.layer.borderColor = kShelbyColorTutorialGreen.CGColor;
        self.tutorialView.layer.borderWidth = 15;
        
        return YES;
    }
    
    return NO;
}

- (void)showDoubleTapTutorial
{
    if ([self tutorialSetup]) {
        [self setTutorialMode:SPTutorialModeDoubleTap];
        [self.tutorialView setupWithImage:@"doubletap.png"
                                  andText:NSLocalizedString(@"TUTORIAL_DBLTAP_MESSAGE", @"2) Double Tap")];
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
            self.tutorialTimer = [NSTimer scheduledTimerWithTimeInterval:kShelbyTutorialIntervalBetweenTutorials target:self selector:@selector(showSwipeLeftTutorial) userInfo:nil repeats:NO];
        }];
    }
}

- (void)videoSwipedLeft
{
    [UIView animateWithDuration:0.2 animations:^{
        [self.tutorialView setAlpha:0];
    } completion:^(BOOL finished) {
        [self setTutorialMode:SPTutorialModeShow];
        self.tutorialTimer = [NSTimer scheduledTimerWithTimeInterval:kShelbyTutorialIntervalBetweenTutorials target:self selector:@selector(showSwipeUpTutorial) userInfo:nil repeats:NO];
    }];
}

- (void)videoSwipedUp
{
    if (self.tutorialMode == SPTutorialModeSwipeUp) {
        [UIView animateWithDuration:0.2 animations:^{
            [self.tutorialView setAlpha:0];
        } completion:^(BOOL finished) {
            [self setTutorialMode:SPTutorialModeShow];
            self.tutorialTimer = [NSTimer scheduledTimerWithTimeInterval:kShelbyTutorialIntervalBetweenTutorials target:self selector:@selector(showSwipeUpTutorial) userInfo:nil repeats:NO];
        }];
    }
}

- (void)showSwipeLeftTutorial
{
    [self setTutorialMode:SPTutorialModeSwipeLeft];
    [self.tutorialView setupWithImage:@"swipeleft.png"
                              andText:NSLocalizedString(@"TUTORIAL_SWPH_MESSAGE", @"3) Swipe left to change video")];
    [UIView animateWithDuration:0.2 animations:^{
        [self.tutorialView setAlpha:0.9];
    }];
}

- (void)showSwipeUpTutorial
{
    [self setTutorialMode:SPTutorialModeSwipeUp];
    [self.tutorialView setupWithImage:@"swipeup.png"
                              andText:NSLocalizedString(@"TUTORIAL_SWPV_MESSAGE", @"4) Swipe up to change channel")];
    [UIView animateWithDuration:0.2 animations:^{
        [self.tutorialView setAlpha:0.9];
    }];    
}

- (void)showPinchTutorial
{
    if ([self tutorialSetup]) {
        [self.tutorialView setupWithImage:@"pinch.png"
                                  andText:NSLocalizedString(@"TUTORIAL_PINCH_MESSAGE", @"5) Pinch to exit")];
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
        if (self.tutorialMode == SPTutorialModeNone &&
            (self.lastVideoStalledAlertTime == nil || [self.lastVideoStalledAlertTime timeIntervalSinceNow] < VIDEO_STALLED_MIN_TIME_BETWEEN_ALERTS)) {
            [self.currentVideoAlertView dismiss];
            self.lastVideoStalledAlertTime = [NSDate date];
            self.currentVideoAlertView = [[ShelbyAlertView alloc] initWithTitle:NSLocalizedString(@"PLAYBACK_STALLED_TITLE", @"--Playback Stalled--")
                                                                        message:NSLocalizedString(@"PLAYBACK_STALLED_MESSAGE", nil)
                                                             dismissButtonTitle:NSLocalizedString(@"PLAYBACK_STALLED_BUTTON", nil)
                                                                 autodimissTime:6.0f
                                                                      onDismiss:^(BOOL didAutoDimiss) {
                                                                          self.currentVideoAlertView = nil;
                                                                      }];
            [self.currentVideoAlertView show];
        }
    }
}

- (void)videoLoadingStatus:(BOOL)isLoading forPlayer:(SPVideoPlayer *)player
{
    //djs TODO
}

- (void)videoBufferedRange:(CMTimeRange)bufferedRange forPlayer:(SPVideoPlayer *)player
{
    if (self.currentPlayer == player) {
        [self.videoPlaybackDelegate setBufferedRange:bufferedRange];
    }
}

- (void)videoDuration:(CMTime)duration forPlayer:(SPVideoPlayer *)player
{
    if (self.currentPlayer == player) {
        [self.videoPlaybackDelegate setDuration:duration];
    }
}

- (void)videoCurrentTime:(CMTime)time forPlayer:(SPVideoPlayer *)player
{
    if (self.currentPlayer == player) {
        [self.videoPlaybackDelegate setCurrentTime:time];
    }
}

- (void)videoPlaybackStatus:(BOOL)isPlaying forPlayer:(SPVideoPlayer *)player
{
    if (self.currentPlayer == player) {
        [self.videoPlaybackDelegate setVideoIsPlaying:isPlaying];
    }
}

- (void)videoExtractionFailForAutoplayPlayer:(SPVideoPlayer *)player
{
    if (self.currentPlayer == player) {
        if (self.tutorialMode == SPTutorialModeNone) {
            [self.currentVideoAlertView dismiss];
            self.currentVideoAlertView = [[ShelbyAlertView alloc] initWithTitle:NSLocalizedString(@"EXTRACTION_FAIL_TITLE", @"--Extraction Fail--")
                                                                        message:NSLocalizedString(@"EXTRACTION_FAIL_MESSAGE", nil)
                                                             dismissButtonTitle:NSLocalizedString(@"EXTRACTION_FAIL_BUTTON", nil)
                                                                 autodimissTime:3.0f
                                                                      onDismiss:^(BOOL didAutoDimiss) {
                                                                          if (self.currentPlayer == player) {
                                                                              [self changeVideoInForwardDirection:YES];
                                                                          }
                                                                          self.currentVideoAlertView = nil;
                                                                      }];
            [self.currentVideoAlertView show];
        } else {
            [self changeVideoInForwardDirection:YES];
        }
    }
}

- (BOOL)changeVideoInForwardDirection:(BOOL)forward
{
    NSUInteger idx = self.currentVideoPlayingIndex + (forward ? 1 : -1);
    if (idx > 0 && idx < [self.videoEntities count]) {
        CGFloat videoX = 0.0;
        CGFloat videoY = 0.0;
        
        if (DEVICE_IPAD) {
            videoX = idx * kShelbySPVideoWidth;
            videoY = self.videoScrollView.contentOffset.y;
        } else {
            videoY = idx * kShelbySPVideoHeight;
            videoX = self.videoScrollView.contentOffset.x;
        }
        [self.videoScrollView setContentOffset:CGPointMake(videoX, videoY) animated:YES];
        [self currentVideoShouldChangeToVideo:idx autoplay:YES];
        return YES;
    } else {
        return NO;
    }
}


#pragma mark - UIScrollViewDelegate Methods
//DEPRECATED
//OLD UNUSED
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    //djs fix when we have our model and view controllers
    
    // Switch the indicator when more than 50% of the previous/next page is visible
    CGFloat scrollAmount = 0.0;
    if (DEVICE_IPAD) {
        CGFloat pageWidth = scrollView.frame.size.width;
       scrollAmount = (scrollView.contentOffset.x - pageWidth / 2) / pageWidth;
    } else {
        CGFloat pageHeight = scrollView.frame.size.height;
        scrollAmount = (scrollView.contentOffset.y - pageHeight / 2) / pageHeight;
    }
    NSUInteger page = floor(scrollAmount) + 1;
    
//    // Toggle playback on old and new SPVideoPlayer objects
    if (page == self.currentVideoPlayingIndex) {
        return;
    }

//    [self.videoPlayers makeObjectsPerformSelector:@selector(pause)];
    
    [self currentVideoShouldChangeToVideo:page autoplay:self.currentPlayer.isPlaying];
    
    NSInteger videosBeyond = [self.videoEntities count] - page;
    if(videosBeyond == kShelbyPrefetchEntriesWhenNearEnd && self.channel.canFetchRemoteEntries){
        //since id should come from raw entries, not de-duped entries
        Frame *lastFrame = [[self videoEntities] lastObject];
        if (lastFrame.duplicates && [lastFrame.duplicates count]) {
            lastFrame = lastFrame.duplicates.lastObject;
        }
        [self.delegate loadMoreEntriesInChannel:self.channel
                                     sinceEntry:lastFrame];
    }
    
    if (self.tutorialMode == SPTutorialModeSwipeLeft) {
        // Doesn't really matter which direction the user swiped - just indicate the user passed the 'SwipeLeft' tutorial
        [self videoSwipedLeft];
    }

//    [self fetchOlderVideos:page];

    [ShelbyViewController sendEventWithCategory:kAnalyticsCategoryVideoPlayer withAction:kAnalyticsVideoPlayerActionSwipeHorizontal withLabel:self.title];

}

@end
