//
//  SPVideoReel.m
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 11/1/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

#import "SPVideoReel.h"
#import "SPOverlayView.h"
#import "SPVideoExtractor.h"
#import "SPVideoItemView.h"
#import "SPVideoPlayer.h"
#import "SPVideoScrubber.h"
#import "DeviceUtilities.h"
#import "TwitterHandler.h"
#import "FacebookHandler.h"


#define kShelbySPSlowSpeed 0.5
#define kShelbySPFastSpeed 0.2

@interface SPVideoReel ()

@property (weak, nonatomic) AppDelegate *appDelegate;
@property (weak, nonatomic) SPModel *model;
@property (weak, nonatomic) SPOverlayView *overlayView;
@property (nonatomic) UIScrollView *videoScrollView;
@property (nonatomic) NSMutableArray *videoFrames;
@property (nonatomic) NSMutableArray *moreVideoFrames;
@property (nonatomic) NSMutableArray *videoPlayers;
@property (nonatomic) NSMutableArray *playableVideoPlayers;
@property (copy, nonatomic) NSString *categoryID;
@property (assign, nonatomic) NSUInteger *videoStartIndex;
@property (assign, nonatomic) BOOL fetchingOlderVideos;
@property (assign, nonatomic) BOOL loadingOlderVideos;

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
- (void)currentVideoDidChangeToVideo:(NSUInteger)position;
- (void)updatePlaybackUI;
- (void)queueMoreVideos:(NSUInteger)position;
- (void)fetchOlderVideos:(NSUInteger)position;
- (void)dataSourceShouldUpdateFromLocalArray;
- (void)dataSourceShouldUpdateFromWeb:(NSNotification *)notification;
- (void)dataSourceDidUpdate;
- (void)scrollToNextVideoAfterUnplayableVideo:(NSNotification*)notification;
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
- (void)animateDown:(float)speed andSwitchCategory:(BOOL)switchCategory;
- (void)animateUp:(float)speed andSwitchCategory:(BOOL)switchCategory;
- (void)switchChannelWithDirectionUp:(BOOL)up;

@end

@implementation SPVideoReel 

#pragma mark - Memory Management
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kShelbySPUserDidScrollToUpdate object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kShelbySPLoadVideoAfterUnplayableVideo object:nil];
    
    DLog(@"SPVideoReel Deallocated");
}

#pragma mark - Initialization
- (id)initWithGroupType:(GroupType)groupType
             groupTitle:(NSString *)groupTitle
            videoFrames:(NSMutableArray *)videoFrames
        videoStartIndex:(NSUInteger)videoStartIndex
          andCategoryID:(NSString *)categoryID
{
    self = [self initWithGroupType:groupType
                        groupTitle:groupTitle
                       videoFrames:videoFrames
                andVideoStartIndex:videoStartIndex];
    
    if (self) {
        _categoryID = categoryID;
    }
    
    return self;
}

- (id)initWithGroupType:(GroupType)groupType
             groupTitle:(NSString *)groupTitle
            videoFrames:(NSMutableArray *)videoFrames
     andVideoStartIndex:(NSUInteger)videoStartIndex
{
    self = [super init];
    if (self) {
        _groupType = groupType;
        _groupTitle = groupTitle;
        _videoFrames = videoFrames;
        _videoStartIndex = videoStartIndex;
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
    
    [self setup];
}

#pragma mark - Setup Methods
- (void)setup
{
    id defaultTracker = [GAI sharedInstance].defaultTracker;
    [defaultTracker sendEventWithCategory:kGAICategoryBrowse
                               withAction:@"User did launch playlist"
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
    self.model = [SPModel sharedInstance];
    self.model.videoReel = self;
    self.model.groupType = _groupType;
    self.model.numberOfVideos = [self.videoFrames count];

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
    
    if ( ![[self.view subviews] containsObject:_videoScrollView] ) {
        
        self.videoScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, kShelbySPVideoWidth, kShelbySPVideoHeight)];
        self.videoScrollView.delegate = self;
        self.videoScrollView.pagingEnabled = YES;
        self.videoScrollView.showsHorizontalScrollIndicator = NO;
        self.videoScrollView.showsVerticalScrollIndicator = NO;
        self.videoScrollView.scrollsToTop = NO;
        [self.videoScrollView setDelaysContentTouches:YES];
        [self.view addSubview:_videoScrollView];
        
    }
    
    self.videoScrollView.contentSize = CGSizeMake(kShelbySPVideoWidth * [self.model numberOfVideos], kShelbySPVideoHeight);
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
        self.model.overlayView = [self overlayView];
        [self.view addSubview:_overlayView];
        
    } else {
        
        self.model.overlayView = [self overlayView];
        
    }

}

- (void)setupVideoPlayers
{
    if ( [self.model numberOfVideos] ) {

        for ( NSUInteger i = 0; i < _model.numberOfVideos; ++i ) {
            
            Frame *videoFrame = (self.videoFrames)[i];
            
            CGRect viewframe = [self.videoScrollView frame];
            viewframe.origin.x = viewframe.size.width * i;
            viewframe.origin.y = 0.0f;
            SPVideoPlayer *player = [[SPVideoPlayer alloc] initWithBounds:viewframe withVideoFrame:videoFrame];
            
            [self.videoPlayers addObject:player];
            [self.videoScrollView addSubview:player.view];
            
        }
        
        [self.model setCurrentVideo:[self videoStartIndex]];
        [self.model setCurrentVideoPlayer:(self.videoPlayers)[[self.model currentVideo]]];
        [self currentVideoDidChangeToVideo:[self.model currentVideo]];
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
        [self.view addGestureRecognizer:panGesture];
        
        UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchAction:)];
        [self.view addGestureRecognizer:pinchGesture];
        
    }
}

- (void)setupOverlayVisibileItems
{
    if ([self.model numberOfVideos]) {
        [self.overlayView showVideoInfo];
    } else {
        [self.overlayView hideVideoInfo];
    }
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
        
        if ( oldestPlayer != _model.currentVideoPlayer ) { // If oldestPlayer isn't currently being played, remove it
            
            [oldestPlayer resetPlayer];
            [self.playableVideoPlayers removeObject:oldestPlayer];
            
        } else { // If oldestPlayer is being played, remove next-oldest video
            
            if ( [self.playableVideoPlayers count] > 1) {
                
                SPVideoPlayer *nextOldestPlayer = (SPVideoPlayer *)(self.playableVideoPlayers)[1];
                [nextOldestPlayer resetPlayer];
                [self.playableVideoPlayers removeObject:nextOldestPlayer];

            }
        }
    }
}

#pragma mark - Update Methods (Public)
- (void)extractVideoForVideoPlayer:(NSUInteger)position
{
    SPVideoPlayer *player = (self.videoPlayers)[position];
    
    NSManagedObjectContext *context = [self.appDelegate context];
    NSManagedObjectID *objectID = [player.videoFrame objectID];
    if (!objectID) {
        return;
    }
    
    Frame *videoFrame = (Frame *)[context existingObjectWithID:objectID error:nil];
    if (!videoFrame) {
        return;
    }
    
    if ( position < _model.numberOfVideos ) {
        if ([videoFrame.video offlineURL] && [[videoFrame.video offlineURL] length] > 0 ) { // Load player from disk if video was previously downloaded
            [player loadVideoFromDisk];
        } else { // Queue video for mp4 extraction
            [player queueVideo];
        }
    } 
}

#pragma mark -  Update Methods (Private)
- (void)currentVideoDidChangeToVideo:(NSUInteger)position
{
    
    // Post notification (to rollViews that may have a keyboard loaded in view)
    [[NSNotificationCenter defaultCenter] postNotificationName:kShelbySPUserDidSwipeToNextVideo object:nil];
    
    // Disable timer
    [self.model.overlayTimer invalidate];
    
    // Show Overlay
    [self.overlayView showOverlayView];
    
    // Pause current videoPlayer
    [self.model.currentVideoPlayer pause];
    
    // Stop observing video for videoScrubber
    [[SPVideoScrubber sharedInstance] stopObserving];
    
    // Reset currentVideoPlayer reference after scrolling has finished
    self.model.currentVideo = position;
    self.model.currentVideoPlayer = (self.videoPlayers)[position];
    
    // Deal with playback methods & UI of current and previous video
    [self updatePlaybackUI];
    
    // Clear old values on infoCard
    [self.overlayView.videoTitleLabel setText:nil];
    [self.overlayView.videoCaptionLabel setText:nil];
    [self.overlayView.nicknameLabel setText:nil];
    [self.overlayView.userImageView setImage:nil];
    
    // Reference NSManageObjectContext
    NSManagedObjectContext *context = [self.appDelegate context];
    NSManagedObjectID *objectID = [(self.videoFrames)[_model.currentVideo] objectID];
    if (!objectID) {
        return;
    }
    
    Frame *videoFrame = (Frame *)[context existingObjectWithID:objectID error:nil];
    if (!videoFrame) {
        return;
    }
    // Set new values on infoPanel
    self.overlayView.videoTitleLabel.text = videoFrame.video.title;
    
    // Set index of video playing
    [self setVideoStartIndex:position];
    
    CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
    self.overlayView.videoCaptionLabel.text = [dataUtility fetchTextFromFirstMessageInConversation:videoFrame.conversation];
    self.overlayView.nicknameLabel.text = [NSString stringWithFormat:@"Shared by %@", videoFrame.creator.nickname];
    [AsynchronousFreeloader loadImageFromLink:videoFrame.creator.userImage
                                 forImageView:_overlayView.userImageView
                              withPlaceholder:[UIImage imageNamed:@"infoPanelIconPlaceholder"]
                               andContentMode:UIViewContentModeScaleAspectFit];
    
    
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
        
        if ( [self.model.currentVideoPlayer isPlayable] ) { // Video IS Playable
            
            [self.model.currentVideoPlayer play];
            
            if ( [self.model.currentVideoPlayer playbackFinished] ) { // Playable video DID finish playing

                [self.overlayView.restartPlaybackButton setHidden:NO];
                
            } else { // Playable video DID NOT finish playing
                
                [self.overlayView.restartPlaybackButton setHidden:YES];
                
            }
            
        } else { // Video IS NOT Playable
            
            [self.overlayView.restartPlaybackButton setHidden:YES];
            
        }
        
    });
    
}

- (void)queueMoreVideos:(NSUInteger)position
{
    if ( [self.videoPlayers count] ) {
        // For all iPads
        [[SPVideoExtractor sharedInstance] cancelRemainingExtractions];
        [self extractVideoForVideoPlayer:position]; // Load video for current visible view
        if (position + 1 < self.model.numberOfVideos) {
            [self extractVideoForVideoPlayer:position+1];
        }
        
        // iPad 3 or better (e.g., device with more RAM and better processor)
        if ([[UIScreen mainScreen] isRetinaDisplay]) {
            if (position + 2 < self.model.numberOfVideos) {
                [self extractVideoForVideoPlayer:position+2];
            }
        }
    }
}

- (void)fetchOlderVideos:(NSUInteger)position
{
    
    if ( [self.moreVideoFrames count] ) { // Load older videos from Database
        
        [self dataSourceShouldUpdateFromLocalArray];
        
    } else { // Get older videos from Web
        
        if ( position >= _model.numberOfVideos - 7 && ![self fetchingOlderVideos] ) {
            
            self.fetchingOlderVideos = YES;
            
            CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
            
            switch ( _groupType ) {
                    
                case GroupType_Stream: {
                    
                    NSUInteger totalNumberOfVideosInDatabase = [dataUtility fetchStreamCount];
                    NSString *numberToString = [NSString stringWithFormat:@"%d", totalNumberOfVideosInDatabase];
                    [ShelbyAPIClient getMoreFramesInStream:numberToString];
                    
                } break;
                    
                case GroupType_Likes: {
                    
                    NSUInteger totalNumberOfVideosInDatabase = [dataUtility fetchLikesCount];
                    NSString *numberToString = [NSString stringWithFormat:@"%d", totalNumberOfVideosInDatabase];
                    [ShelbyAPIClient getMoreFramesInLikes:numberToString];
                    
                } break;
                    
                case GroupType_PersonalRoll: {
                    
                    NSUInteger totalNumberOfVideosInDatabase = [dataUtility fetchPersonalRollCount];
                    NSString *numberToString = [NSString stringWithFormat:@"%d", totalNumberOfVideosInDatabase];
                    [ShelbyAPIClient getMoreFramesInPersonalRoll:numberToString];
                    
                } break;
                    
                case GroupType_CategoryChannel: {
                    
                    NSUInteger totalNumberOfVideosInDatabase = [dataUtility fetchCountForCategoryChannel:_categoryID];
                    NSString *numberToString = [NSString stringWithFormat:@"%d", totalNumberOfVideosInDatabase];
                    [ShelbyAPIClient getMoreFrames:numberToString forCategoryChannel:_categoryID];
                    
                } break;
                    
                case GroupType_CategoryRoll: {
                    
                    NSUInteger totalNumberOfVideosInDatabase = [dataUtility fetchCountForCategoryRoll:_categoryID];
                    NSString *numberToString = [NSString stringWithFormat:@"%d", totalNumberOfVideosInDatabase];
                    [ShelbyAPIClient getMoreFrames:numberToString forCategoryRoll:_categoryID];
                    
                    
                } break;
            }
        }
    }
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
        
        NSManagedObjectContext *context = [self.appDelegate context];
        NSManagedObjectID *lastFramedObjectID = [[self.videoFrames lastObject] objectID];
        if (!lastFramedObjectID) {
            return;
        }
        Frame *lastFrame = (Frame *)[context existingObjectWithID:lastFramedObjectID error:nil];
        if (!lastFrame) {
            return;
        }
        NSDate *date = lastFrame.timestamp;
        
        CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
        NSMutableArray *olderFramesArray = [@[] mutableCopy];
        
        switch ( _groupType ) {
                
            case GroupType_Likes:{
                [olderFramesArray addObjectsFromArray:[dataUtility fetchMoreLikesEntriesAfterDate:date]];
            } break;
                
            case GroupType_PersonalRoll:{
                [olderFramesArray addObjectsFromArray:[dataUtility fetchMorePersonalRollEntriesAfterDate:date]];
            } break;
                
            case GroupType_Stream:{
                [olderFramesArray addObjectsFromArray:[dataUtility fetchMoreStreamEntriesAfterDate:date]];
            } break;
                
            case GroupType_CategoryChannel:{
                [olderFramesArray addObjectsFromArray:[dataUtility fetchMoreFramesInCategoryChannel:_categoryID afterDate:date]];
            } break;
                
            case GroupType_CategoryRoll:{
                [olderFramesArray addObjectsFromArray:[dataUtility fetchMoreFramesInCategoryRoll:_categoryID afterDate:date]];
            } break;
                
        }
        
        // Compare last video from _videoFrames against first result of olderFramesArrays, and deduplicate if necessary
        if ( [olderFramesArray count] ) {
            
            Frame *firstFrame = (Frame *)olderFramesArray[0];
            NSManagedObjectID *firstFrameObjectID = [firstFrame objectID];
            if (!firstFrameObjectID) {
                return;
            }
            
            firstFrame = (Frame *)[context existingObjectWithID:firstFrameObjectID error:nil];
            if (!firstFrame) {
                return;
            }
            if ( [firstFrame.videoID isEqualToString:lastFrame.videoID] ) {
                [olderFramesArray removeObject:firstFrame];
            }
            
            // Add deduplicated frames from olderFramesArray to videoFrames
            [self.videoFrames addObjectsFromArray:olderFramesArray];
            
            [self dataSourceDidUpdate];
            
        } else {
            
            /*
             
             No older videos fetched.
             Don't rest flags to avoid unncessary API calls, since they'll return no older frames.
             
             */
        }
    }
}

- (void)dataSourceDidUpdate
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        // Update variables
        NSUInteger numberOfVideosBeforeUpdate = [self.model numberOfVideos];
        self.model.numberOfVideos = [self.videoFrames count];
        
        // Update videoScrollView and videoListScrollView
        for ( NSUInteger i = numberOfVideosBeforeUpdate; i < _model.numberOfVideos; ++i ) {
            
            if ( [self.videoFrames count] >= i ) {
                
                // videoScrollView
                NSManagedObjectContext *context = [self.appDelegate context];
                NSManagedObjectID *objectID = [(self.videoFrames)[i] objectID];
                if (!objectID) {
                    continue;
                }
                Frame *videoFrame = (Frame *)[context existingObjectWithID:objectID error:nil];
                if (!videoFrame) {
                    return;
                }
                CGRect viewframe = [self.videoScrollView frame];
                viewframe.origin.x = viewframe.size.width * i;
                SPVideoPlayer *player = [[SPVideoPlayer alloc] initWithBounds:viewframe withVideoFrame:videoFrame];
                
                // Update UI on Main Thread
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    // Reference _videoFrames[i] on main thread
                    NSManagedObjectContext *context = [self.appDelegate context];
                    if (!self.videoFrames || [self.videoFrames count] <= i) {
                        return;
                    }
                    NSManagedObjectID *objectID = [(self.videoFrames)[i] objectID];
                    if (!objectID) {
                        return ;
                    }
                    Frame *mainQueuevideoFrame = (Frame *)[context existingObjectWithID:objectID error:nil];
                    if (!mainQueuevideoFrame) {
                        return;
                    }
                    // Update scrollViews
                    self.videoScrollView.contentSize = CGSizeMake(kShelbySPVideoWidth * (i + 1), kShelbySPVideoHeight);
                    [self.videoPlayers addObject:player];
                    [self.videoScrollView addSubview:player.view];
                    [self.videoScrollView setNeedsDisplay];
                    
                    // Set flags
                    [self setFetchingOlderVideos:NO];
                    [self setLoadingOlderVideos:NO];
                });
                
            }
            
        }
    });
}

- (void)scrollToNextVideoAfterUnplayableVideo:(NSNotification *)notification
{
    
    // Position after unloadable video (e.g., next video's position)
    NSUInteger position = _model.currentVideo + 1;
    
    if ( position < _model.numberOfVideos ) { // If next video isn't the last loaded video
        NSString *skippedVideoID = [notification object];
        if (![skippedVideoID isKindOfClass:[NSString class]]) {
            skippedVideoID = nil;
        }
        
        NSManagedObjectContext *context = [self.appDelegate context];
        NSManagedObjectID *currentVideoFrameObjectID = [self.model.currentVideoPlayer.videoFrame objectID];
        Frame *currentVideoFrame = (Frame *)[context existingObjectWithID:currentVideoFrameObjectID error:nil];
        if (!currentVideoFrame) {
            return;
        }
        NSString *currentVideoID = [currentVideoFrame videoID];
        if (![self.model.currentVideoPlayer isPlayable] && [skippedVideoID isEqualToString:currentVideoID]) { // Load AND scroll to next video if current video is in focus
            CGFloat videoX = kShelbySPVideoWidth * position;
            CGFloat videoY = _videoScrollView.contentOffset.y;
            [self.videoScrollView setContentOffset:CGPointMake(videoX, videoY) animated:YES];
            [self currentVideoDidChangeToVideo:position];
        } else { // Load next video, (but do not scroll)
            [self extractVideoForVideoPlayer:position];
        }
    }
}


- (void)currentVideoDidFinishPlayback
{
    NSUInteger position = _model.currentVideo + 1;
    CGFloat x = position * kShelbySPVideoWidth;
    CGFloat y = _videoScrollView.contentOffset.y;
    
    if ( position <= (_model.numberOfVideos-1) ) {
    
        [self.videoScrollView setContentOffset:CGPointMake(x, y) animated:YES];
        [self currentVideoDidChangeToVideo:position];
    
    }
}

#pragma mark - Action Methods (Public)
- (void)restartPlaybackButtonAction:(id)sender
{
    // Send event to Google Analytics
    id defaultTracker = [GAI sharedInstance].defaultTracker;
    [defaultTracker sendEventWithCategory:kGAICategoryVideoPlayer
                               withAction:@"Playback toggled via restart button"
                                withLabel:_groupTitle
                                withValue:nil];
    
    [self.model.currentVideoPlayer restartPlayback];
}

#pragma mark - Action Methods (Private)
- (IBAction)shareButtonAction:(id)sender
{
    // Disable overlayTimer
    [self.model.overlayView showOverlayView];
    [self.model.overlayTimer invalidate];
    
    [self.model.currentVideoPlayer share];
}

- (IBAction)likeAction:(id)sender
{
    NSManagedObjectContext *context = [self.appDelegate context];
    NSManagedObjectID *objectID = [self.model.currentVideoPlayer.videoFrame objectID];
    if (!objectID) {
        return;
    }
    
    Frame *frame = (Frame *)[context existingObjectWithID:objectID error:nil];
    if (!frame) {
        return;
    }
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kShelbyDefaultUserAuthorized]) {
        [ShelbyAPIClient postFrameToLikes:frame.frameID];
    } else { // Logged Out
        CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_StoreLoggedOutLike];
        [ShelbyAPIClient postFrameToLikes:frame.frameID];
        [dataUtility storeFrameInLoggedOutLikes:frame];
    }
    
    SPModel *model = (SPModel *)[SPModel sharedInstance];
    [model.overlayView showOverlayView];
    [model.overlayView showLikeNotificationView];
    [NSTimer scheduledTimerWithTimeInterval:5.0f
                                     target:model.overlayView
                                   selector:@selector(hideLikeNotificationView)
                                   userInfo:nil
                                    repeats:NO];
}

- (IBAction)rollAction:(id)sender
{
    if (![[NSUserDefaults standardUserDefaults] boolForKey:kShelbyDefaultUserAuthorized]) {
 
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
    [self.model.overlayView showOverlayView];
    [self.model.overlayTimer invalidate];
    
    [self.model.currentVideoPlayer roll];    
}

#pragma mark - Gesutre Methods (Private)
- (void)switchChannelWithDirectionUp:(BOOL)up
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(userDidSwitchChannel:direction:)]) {
        [self.delegate userDidSwitchChannel:self direction:up];
    }
}

- (void)panView:(UIPanGestureRecognizer *)gestureRecognizer
{
    if (![gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
        return;
    }
    
    int y = self.model.currentVideoPlayer.view.frame.origin.y;
    int x = self.model.currentVideoPlayer.view.frame.origin.x;
    CGPoint translation = [gestureRecognizer translationInView:self.view];
    
    if ([gestureRecognizer state] == UIGestureRecognizerStateBegan || [gestureRecognizer state] == UIGestureRecognizerStateChanged) {
            self.model.currentVideoPlayer.view.frame = CGRectMake(x, y + translation.y, self.model.currentVideoPlayer.view.frame.size.width, self.model.currentVideoPlayer.view.frame.size.height);
            self.overlayView.frame = CGRectMake(self.overlayView.frame.origin.x, y + translation.y, self.overlayView.frame.size.width, self.overlayView.frame.size.height);
        DLog(@"frame = %@\n", NSStringFromCGRect(self.model.currentVideoPlayer.view.frame));
        [gestureRecognizer setTranslation:CGPointZero inView:self.view];
    } else if ([gestureRecognizer state] == UIGestureRecognizerStateEnded) {
        CGPoint velocity = [gestureRecognizer velocityInView:self.view];
        if (velocity.y < -200) {
            [self.view setUserInteractionEnabled:NO];
            [self animateUp:kShelbySPFastSpeed andSwitchCategory:YES];
        } else if (velocity.y > 200) {
            [self.view setUserInteractionEnabled:NO];
            [self animateDown:kShelbySPFastSpeed andSwitchCategory:YES];
        } else if (kShelbySPVideoHeight - (y + translation.y) > self.model.currentVideoPlayer.view.frame.size.height/3) {
            [self animateUp:kShelbySPSlowSpeed andSwitchCategory:NO];
        } else {
            [self animateDown:kShelbySPSlowSpeed andSwitchCategory:NO];
        }
    }

}

- (void)animateDown:(float)speed andSwitchCategory:(BOOL)switchCategory
{
    CGRect currentPlayerFrame = self.model.currentVideoPlayer.view.frame;
 
    NSInteger finalyYPosition = switchCategory ? self.view.frame.size.height : 0;

    [UIView animateWithDuration:speed animations:^{
        [self.model.currentVideoPlayer.view setFrame:CGRectMake(currentPlayerFrame.origin.x, finalyYPosition, currentPlayerFrame.size.width, currentPlayerFrame.size.height)];
        [self.overlayView setFrame:CGRectMake(self.overlayView.frame.origin.x, finalyYPosition, currentPlayerFrame.size.width, currentPlayerFrame.size.height)];
    } completion:^(BOOL finished) {
        if (switchCategory) {
            [self switchChannelWithDirectionUp:YES];
        }
    }];

}

- (void)animateUp:(float)speed andSwitchCategory:(BOOL)switchCategory
{
    CGRect currentPlayerFrame = self.model.currentVideoPlayer.view.frame;
    
    NSInteger finalyYPosition = switchCategory ? -self.view.frame.size.height : 0;
    
    [UIView animateWithDuration:speed animations:^{
        [self.model.currentVideoPlayer.view setFrame:CGRectMake(currentPlayerFrame.origin.x, finalyYPosition, currentPlayerFrame.size.width, currentPlayerFrame.size.height)];
        [self.overlayView setFrame:CGRectMake(self.overlayView.frame.origin.x, finalyYPosition, currentPlayerFrame.size.width, currentPlayerFrame.size.height)];
    } completion:^(BOOL finished) {
        if (switchCategory) {
            [self switchChannelWithDirectionUp:NO];
        }
    }];
}

- (void)pinchAction:(UIPinchGestureRecognizer *)gestureRecognizer
{
    [self.view setUserInteractionEnabled:NO];
    if (self.delegate && [self.delegate respondsToSelector:@selector(userDidCloseChannel:)]) {
        [self.delegate userDidCloseChannel:self];
    }
}

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
    [self.model destroyModel];
    
    // Remove videoPlayers
    [self.videoPlayers makeObjectsPerformSelector:@selector(pause)];
    [self.videoPlayers removeAllObjects];
    self.videoPlayers = nil;
    
    // Remove playableVideoPlayers (e.g., videoPlayers that are stored in local cache)
    [self.playableVideoPlayers makeObjectsPerformSelector:@selector(pause)];
    [self.playableVideoPlayers removeAllObjects];
    [self setPlayableVideoPlayers:nil];
    
    [[self.videoScrollView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self.videoScrollView removeFromSuperview];
    [self setVideoScrollView:nil];

    // Instantiate dataUtility for cleanup
    CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
    
    // Remove older videos (categoryID will be nil for stream, likes, and personal-roll)
    [dataUtility removeOlderVideoFramesForGroupType:_groupType andCategoryID:_categoryID];
    
    // All video.extractedURL references are temporary (session-dependent), so they should be removed when the app shuts down.
    [dataUtility removeAllVideoExtractionURLReferences];
}

#pragma mark - UIScrollViewDelegate Methods
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    // Switch the indicator when more than 50% of the previous/next page is visible
    CGFloat pageWidth = scrollView.frame.size.width;
    CGFloat scrollAmount = (scrollView.contentOffset.x - pageWidth / 2) / pageWidth;
    NSUInteger page = floor(scrollAmount) + 1;
    
    // Toggle playback on old and new SPVideoPlayer objects
    if ( page != _model.currentVideo ) {
        [self.videoPlayers makeObjectsPerformSelector:@selector(pause)];
    } else {
        return;
    }
    
    [self currentVideoDidChangeToVideo:page];
    [self fetchOlderVideos:page];

    // Send event to Google Analytics
    id defaultTracker = [GAI sharedInstance].defaultTracker;
    [defaultTracker sendEventWithCategory:kGAICategoryVideoPlayer
                               withAction:@"Swiped video player"
                                withLabel:_groupTitle
                                withValue:nil];
}

@end
