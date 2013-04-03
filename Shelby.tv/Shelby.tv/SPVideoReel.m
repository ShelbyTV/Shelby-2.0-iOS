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
#import "GroupsMenuViewController.h"

@interface SPVideoReel ()

@property (weak, nonatomic) AppDelegate *appDelegate;
@property (weak, nonatomic) SPModel *model;
@property (weak, nonatomic) SPOverlayView *overlayView;
@property (nonatomic) GroupsMenuViewController *groupsMenuViewController;
@property (nonatomic) UIScrollView *videoScrollView;
@property (nonatomic) NSMutableArray *videoFrames;
@property (nonatomic) NSMutableArray *moreVideoFrames;
@property (nonatomic) NSMutableArray *videoPlayers;
@property (nonatomic) NSMutableArray *playableVideoPlayers;
@property (nonatomic) NSMutableArray *itemViews;
@property (copy, nonatomic) NSString *categoryID;
@property (assign, nonatomic) BOOL fetchingOlderVideos;
@property (assign, nonatomic) BOOL loadingOlderVideos;
@property (assign, nonatomic) BOOL playlistIsVisible;

/// Setup Methods
- (void)setup;
- (void)setupVideoFrames:(NSArray *)videoFrames;
- (void)setupVariables;
- (void)setupObservers;
- (void)setupVideoScrollView;
- (void)setupVideoListScrollView;
- (void)setupOverlayView;
- (void)setupAirPlay;
- (void)setupVideoPlayers;
- (void)setupSwipeGestures;

/// Storage Methods
- (void)storeIdentifierOfCurrentVideoInStream;

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

/// Gesture Methods
- (void)togglePlaylist:(UISwipeGestureRecognizer *)gesture;
- (void)launchGroupsMenuViewController:(UIPinchGestureRecognizer *)gesture;

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
- (void)loadWithGroupType:(GroupType)groupType
               groupTitle:(NSString *)title
              videoFrames:(NSMutableArray *)videoFrames
            andCategoryID:(NSString *)categoryID
{
    [self setCategoryID:categoryID];
    [self loadWithGroupType:groupType groupTitle:title andVideoFrames:videoFrames];
}

- (void)loadWithGroupType:(GroupType)groupType
               groupTitle:(NSString *)title
           andVideoFrames:(NSMutableArray *)videoFrames
{
    [self setGroupType:groupType];
    [self setGroupTitle:title];
    [self setVideoFrames:videoFrames];
    [self setup];
}

#pragma mark - View Lifecycle Methods
- (void)viewDidLoad
{
    [super viewDidLoad];
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    [self.view setFrame:CGRectMake(0.0f, 0.0f, kShelbySPVideoWidth, kShelbySPVideoHeight)];
    [self.view setBackgroundColor:[UIColor blackColor]];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    _groupsMenuViewController = [[GroupsMenuViewController alloc] initWithNibName:@"GroupsMenuViewController"
                                                                           bundle:nil
                                                                     andVideoReel:self];
    [self.view addSubview:[_groupsMenuViewController view]];
}

#pragma mark - Setup Methods
- (void)setup
{
    
    id defaultTracker = [GAI sharedInstance].defaultTracker;
    [defaultTracker sendEventWithCategory:kGAICategoryBrowse
                               withAction:@"User did launch playlist"
                                withLabel:_groupTitle
                                withValue:nil];
    
    if ( _groupsMenuViewController ) {
        
        [self.groupsMenuViewController.view removeFromSuperview];
        self.groupsMenuViewController = nil;
        
    }
    
    if ( _videoPlayers ) {
        [self purgeVideoPlayerInformationFromPreviousVideoGroup];
    }
    
    [self setTrackedViewName:[NSString stringWithFormat:@"Playlist - %@", _groupTitle]];
    [self setupVariables];
    [self setupObservers];
    [self setupVideoScrollView];
    [self setupOverlayView];
    [self setupVideoPlayers];
    [self setupSwipeGestures];
    [self setupVideoListScrollView];
    [self setupAirPlay];
    
    [self.overlayView setHidden:NO];
    
}

- (void)setupVideoFrames:(NSMutableArray *)videoFrames
{
    
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
    self.videoPlayers = [@[] mutableCopy];
    self.itemViews = [@[] mutableCopy];
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
    self.videoScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, kShelbySPVideoWidth, kShelbySPVideoHeight)];
    self.videoScrollView.contentSize = CGSizeMake(kShelbySPVideoWidth * _model.numberOfVideos, kShelbySPVideoHeight - 20);
    self.videoScrollView.delegate = self;
    self.videoScrollView.pagingEnabled = YES;
    self.videoScrollView.showsHorizontalScrollIndicator = NO;
    self.videoScrollView.showsVerticalScrollIndicator = NO;
    self.videoScrollView.scrollsToTop = NO;
    [self.videoScrollView setDelaysContentTouches:YES];
    [self.view addSubview:_videoScrollView];
}

- (void)setupOverlayView
{
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"SPOverlayView" owner:self options:nil];
    if (![nib isKindOfClass:[NSArray class]] || [nib count] == 0 || ![nib[0] isKindOfClass:[UIView class]]) {
        return;
    }
    self.model.overlayView = nib[0];
    self.overlayView = _model.overlayView;
    [self.overlayView.categoryTitleLabel setText:_groupTitle];
    [self.view addSubview:_overlayView];
    
    self.toggleOverlayGesuture = [[UITapGestureRecognizer alloc] initWithTarget:_overlayView action:@selector(toggleOverlay)];
    [self.toggleOverlayGesuture setNumberOfTapsRequired:1];
    [self.view addGestureRecognizer:_toggleOverlayGesuture];
    
    UIPinchGestureRecognizer *pinchOverlayGesuture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(launchGroupsMenuViewController:)];
    [self.view addGestureRecognizer:pinchOverlayGesuture];
}

- (void)setupVideoPlayers
{
    for ( NSUInteger i = 0; i < _model.numberOfVideos; ++i ) {
        
        Frame *videoFrame = (self.videoFrames)[i];

        CGRect viewframe = [self.videoScrollView frame];
        viewframe.origin.x = viewframe.size.width * i;
        viewframe.origin.y = 0.0f;
        SPVideoPlayer *player = [[SPVideoPlayer alloc] initWithBounds:viewframe withVideoFrame:videoFrame];
        
        [self.videoPlayers addObject:player];
        [self.videoScrollView addSubview:player.view];
        
        if ( 0 == i ) {
        
            self.model.currentVideo = 0;
            self.model.currentVideoPlayer = (self.videoPlayers)[_model.currentVideo];
            
        }
        
    }

    if ( _groupType != GroupType_Stream ) { // If not stream, play video in zeroeth position

        [self currentVideoDidChangeToVideo:_model.currentVideo];
        
    } else { // If  stream, play video stored for kShelbySPCurrentVideoStreamID if it exists. Otherwise, default to video at zeroeth position

        for ( NSUInteger i = 0; i < [self.model numberOfVideos]; ++i ) {
            
            Frame *videoFrame = (self.videoFrames)[i];
            NSString *storedStreamID = [[NSUserDefaults standardUserDefaults] objectForKey:kShelbySPCurrentVideoStreamID];
            
            if ( [videoFrame.frameID isEqualToString:storedStreamID] ) {
             
                self.model.currentVideo = i;
                self.model.currentVideoPlayer = (self.videoPlayers)[_model.currentVideo];
                
            }
        }
        
        [self currentVideoDidChangeToVideo:_model.currentVideo];
    }
}

- (void)setupVideoListScrollView
{
    CGFloat itemViewWidth = [SPVideoItemView width];
    CGFloat itemViewHeight = [SPVideoItemView height];
    self.overlayView.videoListScrollView.contentSize = CGSizeMake(itemViewWidth*_model.numberOfVideos, itemViewHeight);
    self.overlayView.videoListScrollView.delegate = self;
    
    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_group_async(group, queue, ^{
        
        for ( NSUInteger i = 0; i < _model.numberOfVideos; ++i ) {
            
            NSManagedObjectContext *context = [self.appDelegate context];
            NSManagedObjectID *objectID = [(self.videoFrames)[i] objectID];
            Frame *videoFrame = (Frame *)[context existingObjectWithID:objectID error:nil];
            
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"SPVideoItemView" owner:self options:nil];
            if (![nib isKindOfClass:[NSArray class]] || [nib count] == 0 || ![nib[0] isKindOfClass:[UIView class]]) {
                return;
            }

            SPVideoItemView *itemView = nib[0];
            [itemView setTag:i];
        
            CGRect itemFrame = itemView.frame;
            itemFrame.origin.x = itemViewWidth * i;
            itemFrame.origin.y = 0.0f;
            [itemView setFrame:itemFrame];
            
            [AsynchronousFreeloader loadImageFromLink:videoFrame.video.thumbnailURL
                                         forImageView:itemView.thumbnailImageView
                                      withPlaceholder:[UIImage imageNamed:@"videoListThumbnail"]
                                       andContentMode:UIViewContentModeCenter];
        
            dispatch_async(dispatch_get_main_queue(), ^{
                
                NSManagedObjectContext *context = [self.appDelegate context];
                NSManagedObjectID *objectID = [(self.videoFrames)[i] objectID];
                Frame *mainQueuevideoFrame = (Frame *)[context existingObjectWithID:objectID error:nil];
                
               [itemView.videoTitleLabel setText:mainQueuevideoFrame.video.title];
                [self.itemViews addObject:itemView];
                [self.overlayView.videoListScrollView addSubview:itemView];
            
                if ( i == _model.currentVideo ) {
                    itemView.backgroundColor = kShelbyColorGreen;
                    itemView.videoTitleLabel.textColor = kShelbyColorBlack;
                }
                
            });
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{

            // Add visual selected state (e.g., green background) to currentVideo's itemView object
            SPVideoItemView *itemView = (self.itemViews)[_model.currentVideo];
            
            // Scroll To currentVideo if self.currentVideo != 0
            if ( 0 != self.model.currentVideo) {
                
                CGFloat x = _videoScrollView.frame.size.width * _model.currentVideo;
                CGFloat y = _videoScrollView.contentOffset.y;
                [self.videoScrollView setContentOffset:CGPointMake(x, y) animated:YES];
                
                CGFloat itemViewX = itemView.frame.size.width * (_model.currentVideo-1);
                CGFloat itemViewY = _overlayView.videoListScrollView.contentOffset.y;
                [self.overlayView.videoListScrollView setContentOffset:CGPointMake(itemViewX, itemViewY) animated:YES];
                
            }
           
            [self.model.overlayView.videoListScrollView flashScrollIndicators];
        
        });
    });
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

- (void)setupSwipeGestures
{
    UISwipeGestureRecognizer *upGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(togglePlaylist:)];
    upGesture.direction = UISwipeGestureRecognizerDirectionUp;
    [self.videoScrollView addGestureRecognizer:upGesture];
    
    UISwipeGestureRecognizer *downGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(togglePlaylist:)];
    downGesture.direction = UISwipeGestureRecognizerDirectionDown;
    [self.videoScrollView addGestureRecognizer:downGesture];
}

#pragma mark - Storage Methods (Public)
- (void)storeLoadedVideoPlayer:(SPVideoPlayer *)player
{
    if ( ![self playableVideoPlayers] ) {
        self.playableVideoPlayers = [@[] mutableCopy];
    }
    
    // Add newly loaded SPVideoPlayer to list of SPVideoPlayers
    [self.playableVideoPlayers addObject:player];
    
    // If screen is retina (e.g., iPad 3 or greater), allow 56 videos. Otherwise, allow only 3 videos to be stored
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
    Frame *videoFrame = (Frame *)[context existingObjectWithID:objectID error:nil];
    
    if ( position < _model.numberOfVideos ) {
        
        if ([videoFrame.video offlineURL] && [[videoFrame.video offlineURL] length] > 0 ) { // Load player from disk if video was previously downloaded
            
            [player loadVideoFromDisk];
            
        } else { // Queue video for mp4 extraction
            
            [player queueVideo];
            
        }
    
    } else {
    
        // Do nothing
    
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

- (IBAction)playButtonAction:(id)sender
{
    [self.model.currentVideoPlayer togglePlayback:self];
}

- (IBAction)shareButtonAction:(id)sender
{
    [self.model.currentVideoPlayer share];
}

- (IBAction)likeAction:(id)sender
{
    // KP KP TODO:
}

- (IBAction)rollAction:(id)sender
{
    // KP KP TODO:
}


- (IBAction)itemButtonAction:(id)sender
{
    // Send event to Google Analytics
    id defaultTracker = [GAI sharedInstance].defaultTracker;
    [defaultTracker sendEventWithCategory:kGAICategoryVideoList
                               withAction:@"Video selected via video list item press"
                                withLabel:_groupTitle
                                withValue:nil];
    
    // Pause currentVideo Player
    [self.model.currentVideoPlayer pause];
    
    // Reference SPVideoItemView from position in videoListScrollView object
    SPVideoItemView *itemView = (SPVideoItemView *)[sender superview];
    NSUInteger position = itemView.tag;
    
    // Force scroll videoScrollView
    CGFloat videoX = kShelbySPVideoWidth * position;
    CGFloat videoY = _videoScrollView.contentOffset.y;
    
    if ( position < _model.numberOfVideos ) {
        [self.videoScrollView setContentOffset:CGPointMake(videoX, videoY) animated:YES];
    }
    
    // Perform actions on videoChange
    [self currentVideoDidChangeToVideo:position];
    
}

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

- (IBAction)beginScrubbing:(id)sender
{
	[[SPVideoScrubber sharedInstance] beginScrubbing];
}

- (IBAction)scrub:(id)sender
{
    [[SPVideoScrubber sharedInstance] scrub];
}

- (IBAction)endScrubbing:(id)sender
{
    [[SPVideoScrubber sharedInstance] endScrubbing];
}

#pragma mark - Storage Methods (Private)
- (void)storeIdentifierOfCurrentVideoInStream
{
    NSManagedObjectContext *context = [self.appDelegate context];
    NSManagedObjectID *objectID = [(self.videoFrames)[_model.currentVideo] objectID];
    if (!objectID) {
        return;
    }

    Frame *videoFrame = (Frame *)[context existingObjectWithID:objectID error:nil];
    
    [[NSUserDefaults standardUserDefaults] setObject:videoFrame.frameID forKey:kShelbySPCurrentVideoStreamID];
    [[NSUserDefaults standardUserDefaults] synchronize];
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
    
    // If videoReel is instance of Stream, store currentVideoID
    if ( _groupType == GroupType_Stream ) {
        
        [self storeIdentifierOfCurrentVideoInStream];
        
    }
    
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
    
    // Set new values on infoPanel
    self.overlayView.videoTitleLabel.text = videoFrame.video.title;
    
    CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
    self.overlayView.videoCaptionLabel.text = [dataUtility fetchTextFromFirstMessageInConversation:videoFrame.conversation];
    self.overlayView.nicknameLabel.text = [NSString stringWithFormat:@"Shared by %@", videoFrame.creator.nickname];
    [AsynchronousFreeloader loadImageFromLink:videoFrame.creator.userImage
                                 forImageView:_overlayView.userImageView
                          withPlaceholder:[UIImage imageNamed:@"infoPanelIconPlaceholder"]
                               andContentMode:UIViewContentModeScaleAspectFit];
    
    // Update videoListScrollView (if _itemViews is initialized)
    if ( 0 < [self.itemViews count] ) {
        
        // Remove selected state color from all SPVideoItemView objects
        for (SPVideoItemView *itemView in self.itemViews) {
            itemView.backgroundColor = [UIColor clearColor];
            itemView.videoTitleLabel.textColor = kShelbyColorBlack;
        }
        
        // Update currentVideo's SPVideoItemView object UI and position in videoListScrollView object
        SPVideoItemView *itemView = (self.itemViews)[position];
        itemView.backgroundColor = kShelbyColorGreen;
        itemView.videoTitleLabel.textColor = kShelbyColorBlack;
        if ( position < _model.numberOfVideos-1 ) {
            CGFloat itemX = itemView.frame.size.width * position;
            CGFloat itemY = 0.0f;
            [self.overlayView.videoListScrollView setContentOffset:CGPointMake(itemX, itemY) animated:YES];
        }
        
    }
    
    // Queue current and next 3 videos
    [self queueMoreVideos:position];
    
}

- (void)updatePlaybackUI
{    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self.overlayView.bufferProgressView setProgress:0.0f];
        [self.overlayView.elapsedTimelabel setText:@"00:00:00"];
        [self.overlayView.totalDurationlabel setText:@"00:00:00"];
        
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
            firstFrame = (Frame *)[context existingObjectWithID:firstFrameObjectID error:nil];
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
            
            // videoScrollView
            NSManagedObjectContext *context = [self.appDelegate context];
            NSManagedObjectID *objectID = [(self.videoFrames)[i] objectID];
            if (!objectID) {
                continue;
            }
            Frame *videoFrame = (Frame *)[context existingObjectWithID:objectID error:nil];
            
            CGRect viewframe = [self.videoScrollView frame];
            viewframe.origin.x = viewframe.size.width * i;
            SPVideoPlayer *player = [[SPVideoPlayer alloc] initWithBounds:viewframe withVideoFrame:videoFrame];
            
            // videoListScrollView
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"SPVideoItemView" owner:self options:nil];
            if (![nib isKindOfClass:[NSArray class]] || [nib count] == 0 || ![nib[0] isKindOfClass:[UIView class]]) {
                return;
            }

            SPVideoItemView *itemView = nib[0];
            if (![itemView isKindOfClass:[UIView class]]) {
                return;
            }
            
            CGFloat itemViewWidth = [SPVideoItemView width];
            CGFloat itemViewHeight = [SPVideoItemView height];
            CGRect itemFrame = itemView.frame;
            itemFrame.origin.x = itemViewWidth * i;
            [itemView setFrame:itemFrame];
            [itemView setTag:i];
            
            [AsynchronousFreeloader loadImageFromLink:videoFrame.video.thumbnailURL
                                         forImageView:itemView.thumbnailImageView
                                      withPlaceholder:[UIImage imageNamed:@"videoListThumbnail"]
                                       andContentMode:UIViewContentModeCenter];
            
            // Update UI on Main Thread
            dispatch_async(dispatch_get_main_queue(), ^{
                
                // Reference _videoFrames[i] on main thread
                NSManagedObjectContext *context = [self.appDelegate context];
                NSManagedObjectID *objectID = [(self.videoFrames)[i] objectID];
                if (!objectID) {
                    return ;
                }
                Frame *mainQueuevideoFrame = (Frame *)[context existingObjectWithID:objectID error:nil];
                
                // Update scrollViews
                self.videoScrollView.contentSize = CGSizeMake(kShelbySPVideoWidth * (i + 1), kShelbySPVideoHeight);
                [self.videoPlayers addObject:player];
                [self.videoScrollView addSubview:player.view];
                [self.videoScrollView setNeedsDisplay];
                
                // Update itemViews
                itemView.backgroundColor = [UIColor clearColor];
                itemView.videoTitleLabel.textColor = kShelbyColorBlack;
                [itemView.videoTitleLabel setText:mainQueuevideoFrame.video.title];
                self.overlayView.videoListScrollView.contentSize = CGSizeMake(itemViewWidth*(i+1), itemViewHeight+20.0f);
                [self.itemViews addObject:itemView];
                [self.overlayView.videoListScrollView addSubview:itemView];
                [self.overlayView.videoListScrollView setNeedsDisplay];
                
                // Set flags
                [self setFetchingOlderVideos:NO];
                [self setLoadingOlderVideos:NO];
            });
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

- (void)purgeVideoPlayerInformationFromPreviousVideoGroup
{
    // Cancel remaining MP4 extractions
    [[SPVideoExtractor sharedInstance] cancelRemainingExtractions];
    
    // Remove Scrubber Timer and Observer
    [[SPVideoScrubber sharedInstance] stopObserving];
    
    // Remove references on model
    [self.model destroyModel];
    
    // Stop residual audio playback (this shouldn't be happening to begin with)
    [self.videoPlayers makeObjectsPerformSelector:@selector(pause)];
    
    // Release everything
    [self.videoPlayers removeAllObjects];
    self.videoPlayers = nil;
    
    [self.playableVideoPlayers removeAllObjects];
    self.videoPlayers = nil;
    
    [[self.videoScrollView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self.videoScrollView removeFromSuperview];
    self.videoScrollView = nil;
    
    [self.itemViews removeAllObjects];
    self.itemViews = nil;
    
    [self.videoFrames removeAllObjects];
    self.videoFrames = nil;
    
    [self.moreVideoFrames removeAllObjects];
    self.moreVideoFrames = nil;
    
    // Instantiate dataUtility for cleanup
    CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
    
    // Remove older videos (categoryID will be nil for stream, likes, and personal roll)
    [dataUtility removeOlderVideoFramesForGroupType:_groupType andCategoryID:_categoryID];
    
    // All video.extractedURL references are temporary (session-dependent), so they should be removed when the app shuts down.
    [dataUtility removeAllVideoExtractionURLReferences];
}

#pragma mark - Gesture Methods (Private)
- (void)launchGroupsMenuViewController:(UIPinchGestureRecognizer *)gesture
{
    [self.overlayView setHidden:YES];

        _groupsMenuViewController = [[GroupsMenuViewController alloc] initWithNibName:@"GroupsMenuViewController"
                                                                               bundle:nil
                                                                         andVideoReel:self];
        
        [self.videoScrollView addSubview:_groupsMenuViewController.view];
}

- (void)togglePlaylist:(UISwipeGestureRecognizer *)gesture
{
    UISwipeGestureRecognizerDirection direction = [gesture direction];
    
    if ([self.overlayView isOverlayHidden]) {
        [self.overlayView toggleOverlay];
    } else {
        // Do nothing
    }
    
    if (direction == UISwipeGestureRecognizerDirectionUp) {
        [self launchPlaylist];
    } else if (direction == UISwipeGestureRecognizerDirectionDown) {
        [self dismissPlaylist];
    } else {
        // Do nothing
    }
}

- (void)launchPlaylist
{
    DLog(@"Launched Playlist");
    [self setPlaylistIsVisible:YES];
    [self.overlayView toggleVideoListView];
}

- (void)dismissPlaylist
{
    DLog(@"Dismissed Playlist");
    [self setPlaylistIsVisible:NO];
    [self.overlayView toggleVideoListView];
}

#pragma mark - UIScrollViewDelegate Methods
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if ( scrollView == _model.overlayView.videoListScrollView ) {
        
        [scrollView flashScrollIndicators];
        
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    
    if ( scrollView == _videoScrollView ) {
        
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
    
    } else if ( scrollView == _overlayView.videoListScrollView ) {
        
        // Switch the indicator when more than 50% of the previous/next page is visible
        CGFloat pageWidth = scrollView.frame.size.width;
        CGFloat scrollAmount = 2.85*(scrollView.contentOffset.x - pageWidth / 2) / pageWidth; // Multiply by ~3 since each visible section has ~3 videos.
        NSUInteger page = floor(scrollAmount) + 1;
        [self fetchOlderVideos:page];
        
        // Send event to Google Analytics
        id defaultTracker = [GAI sharedInstance].defaultTracker;
        [defaultTracker sendEventWithCategory:kGAICategoryVideoList
                                   withAction:@"Swiped video list"
                                    withLabel:_groupTitle
                                    withValue:nil];
        
        [self.overlayView rescheduleOverlayTimer];
        
    }
}

@end
