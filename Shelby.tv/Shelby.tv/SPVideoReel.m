//
//  SPVideoReel.m
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 11/1/12.
//  Copyright (c) 2012 Shelby TV. All rights reserved.
//

#import "SPVideoReel.h"
#import <QuartzCore/QuartzCore.h>
#import "DeviceUtilities.h"
#import "FacebookHandler.h"
#import "Frame+Helper.h"
#import "SPShareController.h"
#import "SPChannelPeekView.h"
#import "SPOverlayView.h"
#import "SPTutorialView.h"
#import "SPVideoExtractor.h"
#import "SPVideoScrubber.h"
#import "TwitterHandler.h"



#define kShelbySPSlowSpeed 0.2
#define kShelbySPFastSpeed 0.5

@interface SPVideoReel ()

@property (weak, nonatomic) SPOverlayView *overlayView;
@property (nonatomic) UIScrollView *videoScrollView;
//Array of DashboardEntry or Frame
@property (nonatomic) NSMutableArray *videoEntities;
@property (nonatomic) NSMutableArray *videoPlayers;
@property (copy, nonatomic) NSString *channelID;
@property (assign, nonatomic) NSUInteger *videoStartIndex;
@property (assign, nonatomic) BOOL fetchingOlderVideos;
@property (assign, nonatomic) BOOL loadingOlderVideos;
@property (nonatomic) SPChannelPeekView *peelChannelView;
@property (nonatomic) SPTutorialView *tutorialView;
@property (nonatomic, assign) NSInteger currentVideoPlayingIndex;
@property (nonatomic, strong) NSMutableArray *possiblyPlayablePlayers;

@property (nonatomic, strong) SPShareController *shareController;

// Make sure we let user roll immediately after they log in.
@property (nonatomic) NSInvocation *invocationMethod;

/// Setup Methods
- (void)setup;
- (void)setupObservers;
- (void)setupVideoScrollView;
- (void)setupOverlayView;
- (void)setupAirPlay;
- (void)setupVideoPlayers;
- (void)setupGestures;
- (void)setupOverlayVisibileItems;

/// Update Methods
- (void)currentVideoShouldChangeToVideo:(NSUInteger)position;
- (void)updatePlaybackUI;
- (void)scrollToNextVideoAfterUnplayableVideo:(NSNotification *)notification;

/// Action Methods
- (IBAction)shareButtonAction:(id)sender;
- (IBAction)likeAction:(id)sender;
- (IBAction)rollAction:(id)sender;
- (void)rollVideo;

/// Gesture Methods
- (void)pinchAction:(UIPinchGestureRecognizer *)gestureRecognizer;

/// Panning Gestures and Animations
// Video List Panning
- (void)panView:(id)sender;
- (void)animateDown:(float)speed andSwitchChannel:(BOOL)switchChannel;
- (void)animateUp:(float)speed andSwitchChannel:(BOOL)switchChannel;
- (void)switchChannelWithDirectionUp:(BOOL)up;

///Tutorial
- (void)showDoubleTapTutorial;
- (void)showSwipeLeftTutorial;
- (void)showSwipeUpTutorial;
- (void)showPinchTutorial;
- (void)videoSwipedLeft;
- (void)videoSwipedUp;
- (BOOL)tutorialSetup;
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
- (id)initWithVideoEntities:(NSArray *)videoEntities
                    atIndex:(NSUInteger)videoStartIndex
{
    self = [super init];
    if (self) {
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
    
    [self setup];
    
    if (self.tutorialMode == SPTutorialModeShow) {
// djs TODO: find another way to determine when to start showing the tutorial
//        [[NSNotificationCenter defaultCenter] addObserver:self
//                                                 selector:@selector(showDoubleTapTutorial)
//                                                     name:kShelbySPVideoExtracted
//                                                   object:nil];
    } else if (self.tutorialMode == SPTutorialModePinch) {
        [self performSelector:@selector(showPinchTutorial) withObject:nil afterDelay:5];
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(scrollToNextVideoAfterUnplayableVideo:)
                                                 name:kShelbySPLoadVideoAfterUnplayableVideo
                                               object:nil];
}

- (void)removeObservers
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kShelbySPUserDidScrollToUpdate
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kShelbySPLoadVideoAfterUnplayableVideo
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
    
    if ( ![[self.view subviews] containsObject:_overlayView] ) {
        
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"SPOverlayView" owner:self options:nil];
        if (![nib isKindOfClass:[NSArray class]] || [nib count] == 0 || ![nib[0] isKindOfClass:[UIView class]]) {
            return;
        }
        
        self.overlayView = nib[0];
        //djs
//        self.model.overlayView = [self overlayView];
        [self.view addSubview:_overlayView];
        
    } else {
        
        //djs
//        self.model.overlayView = [self overlayView];
        
    }

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
                NSAssert(false, @"expected videoEntry to be a DashboardEntry or Frame");
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
    // Setup gestrues only onces - Toggle Overlay Gesture
    if (![[self.view gestureRecognizers] containsObject:self.toggleOverlayGesuture]) {
        _toggleOverlayGesuture = [[UITapGestureRecognizer alloc] initWithTarget:_overlayView action:@selector(toggleOverlay)];
        [self.toggleOverlayGesuture setNumberOfTapsRequired:1];
        [self.toggleOverlayGesuture setDelegate:self];
        [self.toggleOverlayGesuture requireGestureRecognizerToFail:self.overlayView.scrubberGesture];
        [self.view addGestureRecognizer:self.toggleOverlayGesuture];
       
        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panView:)];
        panGesture.minimumNumberOfTouches = 1;
        panGesture.maximumNumberOfTouches = 1;
        [self.view addGestureRecognizer:panGesture];
        
        UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchAction:)];
        [self.view addGestureRecognizer:pinchGesture];
        
        UITapGestureRecognizer *togglePlaybackGesuture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(togglePlayback:)];
        [togglePlaybackGesuture setNumberOfTapsRequired:2];
        [self.view addGestureRecognizer:togglePlaybackGesuture];

        [self.toggleOverlayGesuture requireGestureRecognizerToFail:togglePlaybackGesuture];
        
        
    }
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

#pragma mark - Storage Methods (Public)

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
    SPVideoPlayer *player = self.videoPlayers[self.currentVideoPlayingIndex];
    
    // Animating Play/Pause icon on the screen
    [self animatePlaybackState:player.isPlaying];

    [player togglePlayback];
}

#pragma mark -  Update Methods (Private)
- (void)currentVideoShouldChangeToVideo:(NSUInteger)position
{
    // Post notification (to rollViews that may have a keyboard loaded in view)
    //djs: this seems wrong/bad
    //djs: TODO: remove this or understand and do it differently
//    [[NSNotificationCenter defaultCenter] postNotificationName:kShelbySPUserDidSwipeToNextVideo object:nil];
    
    // Show Overlay
    //djs haven't looked at this yet
    [self.overlayView showOverlayView];
    
    // Stop observing video for videoScrubber
    //djs haven't looked at this yet
    [[SPVideoScrubber sharedInstance] stopObserving];
    
    // Deal with playback methods & UI of current and previous video
    //djs: i haven't looked at this yet
    [self updatePlaybackUI];

    // Pause current player if there is one
    SPVideoPlayer *previousPlayer;
    if (self.currentVideoPlayingIndex >= 0) {
        previousPlayer = self.videoPlayers[self.currentVideoPlayingIndex];
        [previousPlayer pause];
        previousPlayer.shouldAutoplay = NO;
    }
    
    // Set the new current player to auto play and get it going...
    self.currentVideoPlayingIndex = position;
    SPVideoPlayer *player = self.videoPlayers[self.currentVideoPlayingIndex];
    player.shouldAutoplay = YES;
    [player prepareForStreamingPlayback];
    
    
    //djs TODO: FIXME: this could be DashboardEntry or Frame
    DashboardEntry *dashboardEntry = self.videoEntities[self.currentVideoPlayingIndex];
    
    // Set new values on infoPanel
    self.overlayView.videoTitleLabel.text = dashboardEntry.frame.video.title;
    self.overlayView.videoCaptionLabel.text = [dashboardEntry.frame creatorsInitialCommentWithFallback:YES];
    self.overlayView.videoTimestamp.text = [dashboardEntry.frame createdAt];
    self.overlayView.nicknameLabel.text = [NSString stringWithFormat:@"%@", dashboardEntry.frame.creator.nickname];
    [AsynchronousFreeloader loadImageFromLink:dashboardEntry.frame.creator.userImage
                                 forImageView:_overlayView.userImageView
                              withPlaceholder:[UIImage imageNamed:@"infoPanelIconPlaceholder"]
                               andContentMode:UIViewContentModeScaleAspectFit];
    
    [self manageLoadedVideoPlayersForCurrentPlayer:player
                                    previousPlayer:previousPlayer];
    [self warmURLExtractionCache];
}

#pragma mark - Video Preload Strategery

- (void)setupVideoPreloadStrategy
{
    if (preloadStrategy == SPVideoReelPreloadStrategyNotSet) {
        if ([[UIScreen mainScreen] isRetinaDisplay]) {
            //TODO: determine best preload strategy for iPad Retina
            preloadStrategy = SPVideoReelPreloadNextThreeKeepPrevious;
            DLog(@"Preload strategy: next 3, keep previous");
        } else if ([DeviceUtilities isIpadMini1]) {
            //TODO: determine best preload strategy for iPadMini1
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
    [self manageLoadedVideoPlayersForCurrentPlayer:self.videoPlayers[self.currentVideoPlayingIndex]
                                    previousPlayer:nil];
}

- (void)manageLoadedVideoPlayersForCurrentPlayer:(SPVideoPlayer *)currentPlayer previousPlayer:(SPVideoPlayer *)previousPlayer
{
    NSMutableArray *playersToKeep = [@[] mutableCopy];
    SPVideoPlayer *additionalPlayer;
    
    //progressively build up playerToKeep
    switch (preloadStrategy) {
        case SPVideoReelPreloadNextThreeKeepPrevious:
            additionalPlayer = [self preloadedPlayerAtIndex:self.currentVideoPlayingIndex+3];
            if(additionalPlayer){ [playersToKeep addObject:additionalPlayer]; }
            
        case SPVideoReelPreloadNextTwoKeepPrevious:
            additionalPlayer = [self preloadedPlayerAtIndex:self.currentVideoPlayingIndex+2];
            if(additionalPlayer){ [playersToKeep addObject:additionalPlayer]; }
            
        case SPVideoReelPreloadNextKeepPrevious:
            if(previousPlayer){ [playersToKeep addObject:previousPlayer]; }
            
        case SPVideoReelPreloadNextOnly:
            additionalPlayer = [self preloadedPlayerAtIndex:self.currentVideoPlayingIndex+1];
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

- (SPVideoPlayer *)preloadedPlayerAtIndex:(NSInteger)idx
{
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
    int maxI = MAX(self.currentVideoPlayingIndex+10, [self.videoPlayers count]);
    for(int i = self.currentVideoPlayingIndex; i < maxI; i++){
        SPVideoPlayer *player = self.videoPlayers[i];
        [player warmVideoExtractionCache];
    }
}

#pragma mark - stuff

//djs TODO: this doesn't update, it resets... do we still use it?  why?
- (void)updatePlaybackUI
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.overlayView.elapsedProgressView setProgress:0.0f];
        [self.overlayView.bufferProgressView setProgress:0.0f];
        [self.overlayView.elapsedTimeLabel setText:@""];
        [self.overlayView.totalDurationLabel setText:@""];
    });
    
}

- (void)scrollToNextVideoAfterUnplayableVideo:(NSNotification *)notification
{
    //djs TODO
    DLog(@"TODO: Alert about unplayable video & scroll to next video");


    //djs only keeping this for some math, possibly...
//        if (![self.model.currentVideoPlayer isPlayable] && [skippedVideoID isEqualToString:currentVideoID]) { // Load AND scroll to next video if current video is in focus
//            CGFloat videoX = kShelbySPVideoWidth * position;
//            CGFloat videoY = _videoScrollView.contentOffset.y;
//            [self.videoScrollView setContentOffset:CGPointMake(videoX, videoY) animated:YES];
//            [self currentVideoShouldChangeToVideo:position];
//        } else { // Load next video, (but do not scroll)
//            [self extractVideoForVideoPlayer:position];
//        }
//    }
}


- (void)currentVideoDidFinishPlayback
{
    DLog(@"TODO: scroll to next video b/c current one finished");
    
    //djs only keeping this for some math, possibly...
//    NSUInteger position = _model.currentVideo + 1;
//    CGFloat x = position * kShelbySPVideoWidth;
//    CGFloat y = _videoScrollView.contentOffset.y;
//    
//    if ( position <= (_model.numberOfVideos-1) ) {
//    
//        [self.videoScrollView setContentOffset:CGPointMake(x, y) animated:YES];
//        [self currentVideoShouldChangeToVideo:position];
//    
//    }
}

#pragma mark - Action Methods (Public)
- (void)restartPlaybackButtonAction:(id)sender
{
    // Send event to Google Analytics
    id defaultTracker = [GAI sharedInstance].defaultTracker;
    [defaultTracker sendEventWithCategory:kGAICategoryVideoPlayer
                               withAction:kGAIVideoPlayerActionRestartButton
                                withLabel:_groupTitle
                                withValue:nil];
    
    //djs TODO: we should be holding this, and only us!
//    [self.model.currentVideoPlayer restartPlayback];
}

#pragma mark - Action Methods (Private)
- (IBAction)shareButtonAction:(id)sender
{
    // Disable overlayTimer
    //djs TODO: we should hold this, nobody else
//    [self.model.overlayView showOverlayView];
//    [self.model.overlayTimer invalidate];
//    
//    [self.model.currentVideoPlayer share];
    
    self.shareController = [[SPShareController alloc] initWithVideoPlayer:self.videoPlayers[self.currentVideoPlayingIndex] fromRect:self.overlayView.shareButton.frame];
    [self.shareController share];
    
}

- (IBAction)likeAction:(id)sender
{
    DLog(@"TODO: holy shit the like the video! do something great!");
    //djs easier to comment out everything and rebuild later :-] but :-/
//    NSManagedObjectContext *context = [self.appDelegate context];
//    NSManagedObjectID *objectID = [self.model.currentVideoPlayer.videoFrame objectID];
//    if (!objectID) {
//        return;
//    }
//    
//    Frame *frame = (Frame *)[context existingObjectWithID:objectID error:nil];
//    if (!frame) {
//        return;
//    }
//    if ([[NSUserDefaults standardUserDefaults] boolForKey:kShelbyDefaultUserAuthorized]) {
//        [ShelbyAPIClient postFrameToLikes:frame.frameID];
//    } else { // Logged Out
//        CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_StoreLoggedOutLike];
//        [ShelbyAPIClient postFrameToLikes:frame.frameID];
//        [dataUtility storeFrameInLoggedOutLikes:frame];
//    }
//    
//    SPModel *model = (SPModel *)[SPModel sharedInstance];
//    [model.overlayView showOverlayView];
//    [model.overlayView showLikeNotificationView];
//    [NSTimer scheduledTimerWithTimeInterval:5.0f
//                                     target:model.overlayView
//                                   selector:@selector(hideLikeNotificationView)
//                                   userInfo:nil
//                                    repeats:NO];
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
    // Disable overlayTimer
    //djs
//    [self.model.overlayView showOverlayView];
//    [self.model.overlayTimer invalidate];
//    
//    [self.model.currentVideoPlayer roll];
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
            [self.delegate userDidCloseChannel];
        }
    }
}

- (void)shutdown
{
    //resetting all possibly players (including current player) will pause and free memory of AVPlayer
    [self.possiblyPlayablePlayers makeObjectsPerformSelector:@selector(resetPlayer)];
    
    [[SPVideoExtractor sharedInstance] cancelRemainingExtractions];
    
    // Remove Scrubber Timer and Observer
    [[SPVideoScrubber sharedInstance] stopObserving];
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
        
        //djs probably won't need to replace this with anything
//        [[NSNotificationCenter defaultCenter] removeObserver:self name:kShelbySPVideoExtracted object:nil];
    }
}

- (void)videoDoubleTapped
{
    if (self.tutorialMode == SPTutorialModeDoubleTap) {
        [UIView animateWithDuration:0.2 animations:^{
            [self.tutorialView setAlpha:0];
        } completion:^(BOOL finished) {
            [self setTutorialMode:SPTutorialModeShow];
            [self performSelector:@selector(showSwipeLeftTutorial) withObject:nil afterDelay:5];            
        }];
    }
}

- (void)videoSwipedLeft
{
    if (self.tutorialMode == SPTutorialModeSwipeLeft) {
        [UIView animateWithDuration:0.2 animations:^{
            [self.tutorialView setAlpha:0];
        } completion:^(BOOL finished) {
            [self setTutorialMode:SPTutorialModeShow];
            [self performSelector:@selector(showSwipeUpTutorial) withObject:nil afterDelay:5];
        }];
    }
}

- (void)videoSwipedUp
{
    if (self.tutorialMode == SPTutorialModeSwipeUp) {
        [UIView animateWithDuration:0.2 animations:^{
            [self.tutorialView setAlpha:0];
        } completion:^(BOOL finished) {
            [self setTutorialMode:SPTutorialModeShow];
            [self performSelector:@selector(showSwipeUpTutorial) withObject:nil afterDelay:5];
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
- (void)videoDidFinishPlaying
{
    
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
    
    if (page > self.currentVideoPlayingIndex) {
        [self videoSwipedLeft];
    }
//
    
    [self currentVideoShouldChangeToVideo:page];
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
