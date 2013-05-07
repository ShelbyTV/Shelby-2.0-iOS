//
//  SPVideoReel.m
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 11/1/12.
//  Copyright (c) 2012 Shelby TV. All rights reserved.
//

#import "SPVideoReel.h"
#import <QuartzCore/QuartzCore.h>

// Views
#import "SPOverlayView.h"
#import "SPChannelPeekView.h"
#import "SPTutorialView.h"

// Controllers
#import "SPVideoExtractor.h"
#import "SPVideoScrubber.h"

// Utilities
#import "DeviceUtilities.h"
#import "TwitterHandler.h"
#import "FacebookHandler.h"

//Core Data Models
#import "Frame+Helper.h"

#define kShelbySPSlowSpeed 0.2
#define kShelbySPFastSpeed 0.5

@interface SPVideoReel ()

@property (weak, nonatomic) AppDelegate *appDelegate;
//djs
//@property (weak, nonatomic) SPModel *model;
@property (weak, nonatomic) SPOverlayView *overlayView;
@property (nonatomic) UIScrollView *videoScrollView;
@property (nonatomic) NSMutableArray *videoFrames;
@property (nonatomic) NSMutableArray *moreVideoFrames;
@property (nonatomic) NSMutableArray *videoPlayers;
@property (nonatomic) NSMutableArray *playableVideoPlayers;
@property (copy, nonatomic) NSString *channelID;
@property (assign, nonatomic) NSUInteger *videoStartIndex;
@property (assign, nonatomic) BOOL fetchingOlderVideos;
@property (assign, nonatomic) BOOL loadingOlderVideos;
@property (nonatomic) SPChannelPeekView *peelChannelView;
@property (nonatomic) SPTutorialView *tutorialView;
@property (nonatomic, assign) NSInteger currentVideoPlayingIndex;

// Make sure we let user roll immediately after they log in.
@property (nonatomic) NSInvocation *invocationMethod;

/// Setup Methods
- (void)setup;
- (void)setupVideoFrames:(NSArray *)videoFrames;
- (void)setupVariables;
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
- (void)queueMoreVideos:(NSUInteger)position;
- (void)fetchOlderVideos:(NSUInteger)position;
- (void)dataSourceShouldUpdateFromLocalArray;
- (void)dataSourceShouldUpdateFromWeb:(NSNotification *)notification;
- (void)dataSourceDidUpdate;
- (void)scrollToNextVideoAfterUnplayableVideo:(NSNotification *)notification;
- (void)purgeVideoPlayerInformationFromPreviousVideoGroup;

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

@implementation SPVideoReel 

#pragma mark - Memory Management
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kShelbySPUserDidScrollToUpdate object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kShelbySPLoadVideoAfterUnplayableVideo object:nil];
//    [[NSNotificationCenter defaultCenter] removeObserver:self name:kShelbySPVideoExtracted object:nil];
    
    
    DLog(@"SPVideoReel Deallocated");
}

#pragma mark - Initialization
- (id)initWithVideoFrames:(NSMutableArray *)videoFrames
                  atIndex:(NSUInteger)videoStartIndex
{
    self = [super init];
    if (self) {
        _videoFrames = videoFrames;
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
    [self setupVariables];
    [self setupObservers];
    [self setupVideoScrollView];
    [self setupOverlayView];
    [self setupGestures];
    [self setupVideoPlayers];
    [self setupAirPlay];
    [self setupOverlayVisibileItems];

}

- (void)setupVideoFrames:(NSMutableArray *)videoFrames
{
    
    if ( _videoFrames ) {
        [self.videoFrames removeAllObjects];
        self.videoFrames = nil;
    }
    
    if ( _moreVideoFrames ) {
        [self.moreVideoFrames removeAllObjects];
        self.moreVideoFrames = nil;
    }
    
    self.videoFrames = [@[] mutableCopy];
    
    if ( [videoFrames count] > 20 ) { // If there are more than 20 frames in videoFrames
        
        for (Frame *videoFrame in videoFrames) {
            
            if ([self.videoFrames count] < 20) { // Load the first 20 videoFrames into _videoFrames
                
                [self.videoFrames addObject:videoFrame];
                
            } else { // Load the rest of the videoFrames into _moreVideoFrames
                
                if (!self.moreVideoFrames) {
                    self.moreVideoFrames = [@[] mutableCopy];
                }
                
                [self.moreVideoFrames addObject:videoFrame];
                
            }
        }
        
    } else { // If there are <= 20 frames in videoFrames
        
        self.videoFrames = [NSMutableArray arrayWithArray:videoFrames];
        
    }
}

- (void)setupVariables
{
    /// AppDelegate
    self.appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    /// Model
    //djs
//    self.model = [SPModel sharedInstance];
//    self.model.videoReel = self;
//    self.model.groupType = _groupType;
//    self.model.numberOfVideos = [self.videoFrames count];

    /// NSMutableArrays
    if ( !_videoPlayers ) {
        self.videoPlayers = [@[] mutableCopy];
    }
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
    
    //djs use the model handed to us
    self.videoScrollView.contentSize = CGSizeMake(kShelbySPVideoWidth * [self.videoFrames count], kShelbySPVideoHeight);
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

- (void)setupVideoPlayers
{
    //djs just use the model handed to us, and then uncomment most of this stuff:
    if ([self.videoFrames count]) {
        NSInteger i = 0;
        for (DashboardEntry *dashboardEntry in self.videoFrames) {
            CGRect viewframe = [self.videoScrollView frame];
            viewframe.origin.x = viewframe.size.width * i;
            viewframe.origin.y = 0.0f;
            SPVideoPlayer *player = [[SPVideoPlayer alloc] initWithBounds:viewframe withVideoFrame:dashboardEntry.frame];
            player.videoPlayerDelegate = self;
            [self.videoPlayers addObject:player];
            [self.videoScrollView addSubview:player.view];
            
            i++;
        }
        
        // Making sure we are not accessing index beyond our array. And if we do, go to the last video available.
//        NSInteger currentVideo = [self.model currentVideo];
//        if ([self.videoPlayers count] <= currentVideo) {
//            currentVideo = [self.videoPlayers count] - 1;
//        }
        
        [self currentVideoShouldChangeToVideo:self.videoStartIndex];
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
- (void)storeLoadedVideoPlayer:(SPVideoPlayer *)player
{
    if ( ![self playableVideoPlayers] ) {
        self.playableVideoPlayers = [@[] mutableCopy];
    }
    
    // Add newly loaded SPVideoPlayer to list of SPVideoPlayers
    [self.playableVideoPlayers addObject:player];
    
    // If screen is retina (e.g., iPad 3 or greater), allow 3 videos. Otherwise, allow only 3 videos to be stored
    NSUInteger maxVideosAllowed;
    if ([[UIScreen mainScreen] isRetinaDisplay]) {
        maxVideosAllowed = 3;
    } else if (![DeviceUtilities isIpadMini1]) {
        maxVideosAllowed = 2;
    } else {
        maxVideosAllowed = 1;
    }
    
    if ( [self.playableVideoPlayers count] > maxVideosAllowed ) { // If more than X number of videos are loaded, unload the older videos in the list
        
        SPVideoPlayer *oldestPlayer = (SPVideoPlayer *)(self.playableVideoPlayers)[0];

        //djs do this using our own model
//        if ( oldestPlayer != _model.currentVideoPlayer ) { // If oldestPlayer isn't currently being played, remove it
//            
//            [oldestPlayer resetPlayer];
//            [self.playableVideoPlayers removeObject:oldestPlayer];
//            
//        } else { // If oldestPlayer is being played, remove next-oldest video
//            
//            if ( [self.playableVideoPlayers count] > 1) {
//                
//                SPVideoPlayer *nextOldestPlayer = (SPVideoPlayer *)(self.playableVideoPlayers)[1];
//                [nextOldestPlayer resetPlayer];
//                [self.playableVideoPlayers removeObject:nextOldestPlayer];
//
//            }
//        }
    }
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
    SPVideoPlayer *player = self.videoPlayers[self.currentVideoPlayingIndex];
    
    // Animating Play/Pause icon on the screen
    [self animatePlaybackState:player.isPlaying];

    [player togglePlayback];
}

#pragma mark - Update Methods (Public)
- (void)extractVideoForVideoPlayer:(NSUInteger)position
{
    SPVideoPlayer *player = (self.videoPlayers)[position];
    
//    djs same old bullshit... just use the damn video...
//    Frame *videoFrame = player.videoFrame;
    [player prepareForStreamingPlayback];
//    NSManagedObjectContext *context = [self.appDelegate context];
//    NSManagedObjectID *objectID = [player.videoFrame objectID];
//    if (!objectID) {
//        return;
//    }
//    
//    Frame *videoFrame = (Frame *)[context existingObjectWithID:objectID error:nil];
//    if (!videoFrame) {
//        return;
//    }

    //djs
//    if ( position < _model.numberOfVideos ) {
//        //djs XXX this is not the right way to determine if we should use offline vs. streaming video
//        //djs TODO: check the OfflineVideoManager to see if we're in offline mode
//        if ([videoFrame.video offlineURL] && [[videoFrame.video offlineURL] length] > 0 ) {
//            [player prepareForLocalPlayback];
//        } else {
//            [player prepareForStreamingPlayback];
//        }
//    } 
}

#pragma mark -  Update Methods (Private)
- (void)currentVideoShouldChangeToVideo:(NSUInteger)position
{
    
    // Post notification (to rollViews that may have a keyboard loaded in view)
    [[NSNotificationCenter defaultCenter] postNotificationName:kShelbySPUserDidSwipeToNextVideo object:nil];
    
    // Disable timer
    //djs
//    [self.model.overlayTimer invalidate];
    
    // Show Overlay
    [self.overlayView showOverlayView];
    
    // Pause current videoPlayer
    //djs
//    [self.model.currentVideoPlayer pause];
    
    // Stop observing video for videoScrubber
    [[SPVideoScrubber sharedInstance] stopObserving];
    
    // Reset currentVideoPlayer reference after scrolling has finished
    //djs
//    self.model.currentVideo = position;
//    self.model.currentVideoPlayer = (self.videoPlayers)[position];
    
    // Deal with playback methods & UI of current and previous video
    [self updatePlaybackUI];
    
    // Clear old values on infoCard
    [self.overlayView.videoTitleLabel setText:nil];
    [self.overlayView.videoCaptionLabel setText:nil];
    [self.overlayView.nicknameLabel setText:nil];
    [self.overlayView.userImageView setImage:nil];
    
//    // Reference NSManageObjectContext
//    NSManagedObjectContext *context = [self.appDelegate context];
//    NSManagedObjectID *objectID = [(self.videoFrames)[_model.currentVideo] objectID];
//    if (!objectID) {
//        return;
//    }
//    Frame *videoFrame = (Frame *)[context existingObjectWithID:objectID error:nil];
//    if (!videoFrame) {
//        return;
//    }
//
    // Set current player to not autoplay and pause player
    SPVideoPlayer *player = nil;
    if (self.currentVideoPlayingIndex >= 0) {
        player = (self.videoPlayers)[self.currentVideoPlayingIndex];
        player.shouldAutoPlay = NO;
        [player pause];
    }
    
    // Set the new current player to auto play.
    self.currentVideoPlayingIndex = position;
    player = (self.videoPlayers)[self.currentVideoPlayingIndex];
    player.shouldAutoPlay = YES;

    // KP KP: TODO: if video is already loaded, start playing and return

    
    //djs uncommont most of this stuff when we have a proper model
    DashboardEntry *dashboardEntry = self.videoFrames[self.currentVideoPlayingIndex];
    
    // Set new values on infoPanel
    self.overlayView.videoTitleLabel.text = dashboardEntry.frame.video.title;
    
    // Set index of video playing
    [self setVideoStartIndex:position];
 
    //Show the rollers caption, fallback to video title;
    self.overlayView.videoCaptionLabel.text = [dashboardEntry.frame creatorsInitialCommentWithFallback:YES];
    
    self.overlayView.videoTimestamp.text = [dashboardEntry.frame createdAt];
    self.overlayView.nicknameLabel.text = [NSString stringWithFormat:@"%@", dashboardEntry.frame.creator.nickname];
    [AsynchronousFreeloader loadImageFromLink:dashboardEntry.frame.creator.userImage
                                 forImageView:_overlayView.userImageView
                              withPlaceholder:[UIImage imageNamed:@"infoPanelIconPlaceholder"]
                               andContentMode:UIViewContentModeScaleAspectFit];
    
    
    // notify all players they are not autoplayed
    [self extractVideoForVideoPlayer:self.currentVideoPlayingIndex];
    
    // Queue current and next 3 videos
    [self queueMoreVideos:position];
    
}

- (void)updatePlaybackUI
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self.overlayView.elapsedProgressView setProgress:0.0f];
        [self.overlayView.bufferProgressView setProgress:0.0f];
        [self.overlayView.elapsedTimeLabel setText:@""];
        [self.overlayView.totalDurationLabel setText:@""];

        //djs fix when we have a model
//        if ( [self.model.currentVideoPlayer isPlayable] ) { // Video IS Playable
//            
//            [self.model.currentVideoPlayer play];
//            
//            if ( [self.model.currentVideoPlayer playbackFinished] ) { // Playable video DID finish playing
//
//                [self.overlayView.restartPlaybackButton setHidden:NO];
//                
//            } else { // Playable video DID NOT finish playing
//                
//                [self.overlayView.restartPlaybackButton setHidden:YES];
//                
//            }
//            
//        } else { // Video IS NOT Playable
//            
//            [self.overlayView.restartPlaybackButton setHidden:YES];
//            
//        }
        
    });
    
}

- (void)queueMoreVideos:(NSUInteger)position
{
    //djs fix when we have a real model
//    if ( [self.videoPlayers count] ) {
//        // For all iPads
//        [[SPVideoExtractor sharedInstance] cancelRemainingExtractions];
//        [self extractVideoForVideoPlayer:position]; // Load video for current visible view
//        if (position + 1 < self.model.numberOfVideos) {
//            [self extractVideoForVideoPlayer:position+1];
//        }
//        
//        // iPad 3 or better (e.g., device with more RAM and better processor)
//        if ([[UIScreen mainScreen] isRetinaDisplay]) {
//            if (position + 2 < self.model.numberOfVideos) {
//                [self extractVideoForVideoPlayer:position+2];
//            }
//        }
//    }
}

- (void)fetchOlderVideos:(NSUInteger)position
{

    //djs going to do this by calling on a protocol, hey, fetch us some more data!
    
//    if ( [self.moreVideoFrames count] ) { // Load older videos from Database
//        
//        [self dataSourceShouldUpdateFromLocalArray];
//        
//    } else { // Get older videos from Web
//        
//        if ( position >= _model.numberOfVideos - 7 && ![self fetchingOlderVideos] ) {
//            
//            self.fetchingOlderVideos = YES;
//            
//            switch ( _groupType ) {
//                    
//                case GroupType_Stream: {
//                    
//                    //djs
//                    DLog(@"TODO: need more videos for our Stream!");
////                    djs not yet sure how we're going to do this, but it's not like this...
////                    CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
////                    User *user = [dataUtility fetchUser];
////                    NSUInteger totalNumberOfVideosInDatabase = [dataUtility fetchDashboardEntriesInDashboard:user.userID];
////                    NSString *numberToString = [NSString stringWithFormat:@"%d", totalNumberOfVideosInDatabase];
////                    [ShelbyAPIClient getMoreFramesInStream:numberToString];
//                    
//                } break;
//                    
//                case GroupType_Likes: {
//
//                    //djs
//                    DLog(@"TODO: need more videos for our Likes!");
////                    CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
////                    NSUInteger totalNumberOfVideosInDatabase = [dataUtility fetchLikesCount];
////                    NSString *numberToString = [NSString stringWithFormat:@"%d", totalNumberOfVideosInDatabase];
////                    [ShelbyAPIClient getMoreFramesInLikes:numberToString];
//                    
//                } break;
//                    
//                case GroupType_PersonalRoll: {
//
//                    //djs
//                    DLog(@"TODO: need more videos for our personal Roll!");
////                    CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
////                    NSUInteger totalNumberOfVideosInDatabase = [dataUtility fetchPersonalRollCount];
////                    NSString *numberToString = [NSString stringWithFormat:@"%d", totalNumberOfVideosInDatabase];
////                    [ShelbyAPIClient getMoreFramesInPersonalRoll:numberToString];
//                    
//                } break;
//                    
//                case GroupType_ChannelDashboard: {
//                    
//                    //djs
//                    DLog(@"Need more videos for some channel");
////                    CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
////                    NSUInteger totalNumberOfVideosInDatabase = [dataUtility fetchCountForChannelDashboard:_channelID];
////                    NSString *numberToString = [NSString stringWithFormat:@"%d", totalNumberOfVideosInDatabase];
////                    [ShelbyAPIClient getMoreDashboardEntries:numberToString forChannelDashboard:_channelID];
//                    
//                } break;
//                    
//                case GroupType_ChannelRoll: {
//
//                    //djs
//                    DLog(@"Need more videos for some roll");
////                    CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
////                    NSUInteger totalNumberOfVideosInDatabase = [dataUtility fetchCountForChannelRoll:_channelID];
////                    NSString *numberToString = [NSString stringWithFormat:@"%d", totalNumberOfVideosInDatabase];
////                    [ShelbyAPIClient getMoreFrames:numberToString forChannelRoll:_channelID];
//                    
//                } break;
//                    
//                case GroupType_Unknown: {
//                    
//                    // Do nothing
//                    
//                } break;
//            }
//        }
//    }
}

- (void)dataSourceShouldUpdateFromLocalArray
{
    
    if ( [self.moreVideoFrames count] > 20 ) { // If there are more than 20 frames in videoFrames
        
        NSArray *tempMoreVideoFrames = [NSArray arrayWithArray:_moreVideoFrames];
        
        for ( NSUInteger i = 0; i<20; i++ ) {
            
            [self.videoFrames addObject:[tempMoreVideoFrames objectAtIndex:i]];
            [self.moreVideoFrames removeObjectAtIndex:0];
            
        }
        
    } else { // If there are <= 20 frames in videoFrames
        
        [self.videoFrames addObjectsFromArray:_moreVideoFrames];
        [self.moreVideoFrames removeAllObjects];
        
    }
    
    [self dataSourceDidUpdate];
    
}

- (void)dataSourceShouldUpdateFromWeb:(NSNotification *)notification
{
    
    if ( [self fetchingOlderVideos] && ![self loadingOlderVideos] ) {
        
        [self setLoadingOlderVideos:YES];
        
//        NSManagedObjectContext *context = [self.appDelegate context];
//        NSManagedObjectID *lastFramedObjectID = [[self.videoFrames lastObject] objectID];
//        if (!lastFramedObjectID) {
//            return;
//        }
//        Frame *lastFrame = (Frame *)[context existingObjectWithID:lastFramedObjectID error:nil];
//        if (!lastFrame) {
//            return;
//        }
        //djs again, just using the frame we're holding
        Frame *lastFrame = [self.videoFrames lastObject];
        
//        NSDate *date = lastFrame.timestamp;
        
        NSMutableArray *olderFramesArray = [@[] mutableCopy];
        
        //djs actually, we probably won't be getting data this way anymore...
        DLog(@"HOLY SHIT! We need to do something with all this data...");
//        switch ( _groupType ) {
//                
//            case GroupType_Likes:{
//                CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
//                [olderFramesArray addObjectsFromArray:[dataUtility fetchMoreLikesEntriesAfterDate:date]];
//            } break;
//                
//            case GroupType_PersonalRoll:{
//                CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
//                [olderFramesArray addObjectsFromArray:[dataUtility fetchMorePersonalRollEntriesAfterDate:date]];
//            } break;
//                
//            case GroupType_Stream:{
//                CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
//                User *user = [dataUtility fetchUser];
//                [olderFramesArray addObjectsFromArray:[dataUtility fetchMoreDashboardEntriesInDashboard:user.userID afterDate:date]];
//            } break;
//                
//            case GroupType_ChannelDashboard:{
//                CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
//                [olderFramesArray addObjectsFromArray:[dataUtility fetchMoreDashboardEntriesInDashboard:_channelID afterDate:date]];
//            } break;
//                
//            case GroupType_ChannelRoll:{
//                CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
//                [olderFramesArray addObjectsFromArray:[dataUtility fetchMoreFramesInChannelRoll:_channelID afterDate:date]];
//            } break;
//                
//            case GroupType_Unknown: {
//                // Do nothing
//            } break;
//                
//        }
        
        // Compare last video from _videoFrames against first result of olderFramesArrays, and deduplicate if necessary
        if ( [olderFramesArray count] ) {
            
            Frame *firstFrame = (Frame *)olderFramesArray[0];
            //djs what's wrong with the frame above?
//            NSManagedObjectID *firstFrameObjectID = [firstFrame objectID];
//            if (!firstFrameObjectID) {
//                return;
//            }
//            firstFrame = (Frame *)[context existingObjectWithID:firstFrameObjectID error:nil];
//            if (!firstFrame) {
//                return;
//            }
            
            
            if ( [firstFrame.videoID isEqualToString:lastFrame.videoID] ) {
                [olderFramesArray removeObject:firstFrame];
            }
            
            // Add deduplicated frames from olderFramesArray to videoFrames
            [self.videoFrames addObjectsFromArray:olderFramesArray];
            
            [self dataSourceDidUpdate];
            
        } else {
            
            // No older videos fetched.
            
            [self setFetchingOlderVideos:NO];
            [self setLoadingOlderVideos:NO];
            
        }
    }
}

- (void)dataSourceDidUpdate
{
    //djs this goes hand in hand w/ the other data update fixes
    
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//        
//        // Update variables
//        NSUInteger numberOfVideosBeforeUpdate = [self.model numberOfVideos];
//        self.model.numberOfVideos = [self.videoFrames count];
//        
//        // Update videoScrollView and videoListScrollView
//        for ( NSUInteger i = numberOfVideosBeforeUpdate; i < _model.numberOfVideos; ++i ) {
//            
//            if ( [self.videoFrames count] >= i ) {
//                
//                // videoScrollView
////                NSManagedObjectContext *context = [self.appDelegate context];
////                NSManagedObjectID *objectID = [(self.videoFrames)[i] objectID];
////                if (!objectID) {
////                    continue;
////                }
////                Frame *videoFrame = (Frame *)[context existingObjectWithID:objectID error:nil];
////                if (!videoFrame) {
////                    return;
////                }
//                //djs don't see any reason we can't use the frame we've already got
//                Frame *videoFrame = self.videoFrames[i];
//                
//                
//                CGRect viewframe = [self.videoScrollView frame];
//                viewframe.origin.x = viewframe.size.width * i;
//                SPVideoPlayer *player = [[SPVideoPlayer alloc] initWithBounds:viewframe withVideoFrame:videoFrame];
//                
//                // Update UI on Main Thread
//                dispatch_async(dispatch_get_main_queue(), ^{
//
//                    //djs jesus h christ, we're not even using the frame we get in this convoluted manner!
////                    // Reference _videoFrames[i] on main thread
////                    NSManagedObjectContext *context = [self.appDelegate context];
////                    if (!self.videoFrames || [self.videoFrames count] <= i) {
////                        return;
////                    }
////                    NSManagedObjectID *objectID = [(self.videoFrames)[i] objectID];
////                    if (!objectID) {
////                        return ;
////                    }
////                    Frame *mainQueuevideoFrame = (Frame *)[context existingObjectWithID:objectID error:nil];
////                    if (!mainQueuevideoFrame) {
////                        return;
////                    }
//                    // Update scrollViews
//                    self.videoScrollView.contentSize = CGSizeMake(kShelbySPVideoWidth * (i + 1), kShelbySPVideoHeight);
//                    [self.videoPlayers addObject:player];
//                    [self.videoScrollView addSubview:player.view];
//                    [self.videoScrollView setNeedsDisplay];
//                    
//                    // Set flags
//                    [self setFetchingOlderVideos:NO];
//                    [self setLoadingOlderVideos:NO];
//                });
//                
//            }
//            
//        }
//    });
}

- (void)scrollToNextVideoAfterUnplayableVideo:(NSNotification *)notification
{

    //djs uncomment all this when we have a proper model
    
//    // Position after unloadable video (e.g., next video's position)
//    NSUInteger position = _model.currentVideo + 1;
//    
//    if ( position < _model.numberOfVideos ) { // If next video isn't the last loaded video
//        NSString *skippedVideoID = [notification object];
//        if (![skippedVideoID isKindOfClass:[NSString class]]) {
//            skippedVideoID = nil;
//        }
//        
////        NSManagedObjectContext *context = [self.appDelegate context];
////        NSManagedObjectID *currentVideoFrameObjectID = [self.model.currentVideoPlayer.videoFrame objectID];
////        Frame *currentVideoFrame = (Frame *)[context existingObjectWithID:currentVideoFrameObjectID error:nil];
////        if (!currentVideoFrame) {
////            return;
////        }
////        NSString *currentVideoID = [currentVideoFrame videoID];
//        //djs just using the stuff we have, we're not saving anything here!
//        NSString *currentVideoID = [self.model.currentVideoPlayer.videoFrame videoID];
//        
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
    //djs uncomment with proper model
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

// KP KP: TODO: this is no longer getting called - figure out if we need to call it or can deal with the cleanup differently.
- (void)cleanup
{
    [self purgeVideoPlayerInformationFromPreviousVideoGroup];
}

- (void)purgeVideoPlayerInformationFromPreviousVideoGroup
{
    // Cancel remaining MP4 extractions
    [[SPVideoExtractor sharedInstance] cancelRemainingExtractions];
    
    // Remove Scrubber Timer and Observer
    [[SPVideoScrubber sharedInstance] stopObserving];
    
    // Remove references on model
//    [self.model destroyModel];
    
    // Remove videoPlayers
    [self.videoPlayers makeObjectsPerformSelector:@selector(pause)];
//    [self.videoPlayers removeAllObjects];
//    self.videoPlayers = nil;
    
    // Remove playableVideoPlayers (e.g., videoPlayers that are stored in local cache)
    [self.playableVideoPlayers makeObjectsPerformSelector:@selector(pause)];
//    [self.playableVideoPlayers removeAllObjects];
//    [self setPlayableVideoPlayers:nil];
    
//    [[self.videoScrollView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
//    [self.videoScrollView removeFromSuperview];
//    [self setVideoScrollView:nil];

//    // Instantiate dataUtility for cleanup
//    CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
//    
//    // Remove older videos (channelID will be nil for stream, likes, and personal-roll)
//    [dataUtility removeOlderVideoFramesForGroupType:_groupType andChannelID:_channelID];
//    
//    // All video.extractedURL references are temporary (session-dependent), so they should be removed when the app shuts down.
//    [dataUtility removeAllVideoExtractionURLReferences];
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
