     
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
#import "ImageUtilities.h"

@interface SPVideoReel ()

@property (weak, nonatomic) AppDelegate *appDelegate;
@property (weak, nonatomic) SPModel *model;
@property (weak, nonatomic) SPOverlayView *overlayView;
@property (nonatomic) UIScrollView *videoScrollView;
@property (nonatomic) NSMutableArray *videoFrames;
@property (nonatomic) NSMutableArray *moreVideoFrames;
@property (nonatomic) NSMutableArray *videoPlayers;
@property (nonatomic) NSMutableArray *playableVideoPlayers;
@property (nonatomic) NSMutableArray *itemViews;
@property (copy, nonatomic) NSString *categoryTitle;
@property (copy, nonatomic) NSString *channelID;
@property (assign, nonatomic) BOOL fetchingOlderVideos;
@property (assign, nonatomic) BOOL loadingOlderVideos;

// Transition Properties
@property (strong, nonatomic) UIImageView *screenshot;
@property (strong, nonatomic) UIImageView *zoomInScreenshot;
@property (assign, nonatomic) CGRect zoomInScreenshotFrame;
@property (assign, nonatomic) BOOL inTransition;
@property (strong, nonatomic) UIImage *playerScreenshot;


/// Setup Methods
- (void)setupVideoFrames:(NSArray *)videoFrames;
- (void)setupVariables;
- (void)setupObservers;
- (void)setupVideoScrollView;
- (void)setupVideoListScrollView;
- (void)setupOverlayView;
- (void)setupAirPlay;
- (void)setupVideoPlayers;

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

/// Transition Methods
- (void)transformInAnimation;
- (void)fadeOutAnimationForTransformIn;
- (void)transformOutAnimation;
- (void)fadeOutAnimationForTransformOut:(UIImageView *)currentScreenshotImage;
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
- (id)initWithCategoryType:(CategoryType)categoryType
             categoryTitle:(NSString *)title
            andVideoFrames:(NSMutableArray *)videoFrames
{
    
    if ( (self = [super init]) ) {
        
        self.categoryType = categoryType;
        self.categoryTitle = title;
        [self setupVideoFrames:videoFrames];
        
    }
    
    return self;
}

- (id)initWithCategoryType:(CategoryType)categoryType
             categoryTitle:(NSString *)title
               videoFrames:(NSMutableArray *)videoFrames
              andChannelID:(NSString *)channelID
{
    if ( (self = [super init]) ) {
        
        self.categoryType = categoryType;
        self.categoryTitle = title;
        self.channelID = channelID;

        [self setupVideoFrames:videoFrames];

    }
    
    return self;
}

- (void)setupTransition:(UIImageView *)screenshot andZoomInScreenshot:(UIImageView *)zoomInScreenshot
{
    [self setScreenshot:screenshot];
    [self setZoomInScreenshot:zoomInScreenshot];
    [self setZoomInScreenshotFrame:zoomInScreenshot.frame];
}

#pragma mark - View Lifecycle Methods
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.view setFrame:CGRectMake(0.0f, 0.0f, 1024.0f, 768.0f)];
    [self.view setBackgroundColor:[UIColor blackColor]];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self setupVariables];
    [self setupVideoScrollView];
    [self setupOverlayView];
    [self setupVideoPlayers];
    [self setupObservers];
    [self setupAirPlay];

    [self setInTransition:NO];
    if (self.screenshot) {
        [self transformInAnimation];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self setupVideoListScrollView];
}

#pragma mark - Setup Methods
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
    self.model.categoryType = _categoryType;
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
    self.videoScrollView = [[UIScrollView alloc] initWithFrame:self.view.frame];
    self.videoScrollView.contentSize = CGSizeMake(1024.0f*_model.numberOfVideos, 748.0f);
    self.videoScrollView.delegate = self;
    self.videoScrollView.pagingEnabled = YES;
    self.videoScrollView.showsHorizontalScrollIndicator = NO;
    self.videoScrollView.showsVerticalScrollIndicator = NO;
    self.videoScrollView.scrollsToTop = NO;
    [self.view addSubview:_videoScrollView];
}

- (void)setupOverlayView
{
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"SPOverlayView" owner:self options:nil];
    self.model.overlayView = nib[0];
    self.overlayView = _model.overlayView;
    [self.overlayView.categoryTitleLabel setText:_categoryTitle];
    [self.view addSubview:_overlayView];
    
    self.toggleOverlayGesuture = [[UITapGestureRecognizer alloc] initWithTarget:_overlayView action:@selector(toggleOverlay)];
    [self.toggleOverlayGesuture setNumberOfTapsRequired:1];
    [self.view addGestureRecognizer:_toggleOverlayGesuture];
    
    UIPinchGestureRecognizer *pinchOverlayGesuture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(homeButtonAction:)];
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

    if ( self.categoryType != CategoryType_Stream ) { // If not stream, play video in zeroeth position

        [self currentVideoDidChangeToVideo:_model.currentVideo];
        
    } else { // If  stream, play video stored for kShelbySPCurrentVideoStreamID if it exists. Otherwise, default to video at zeroeth position

        for ( NSUInteger i = 0; i < _model.numberOfVideos; ++i ) {
            
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
    self.overlayView.videoListScrollView.contentSize = CGSizeMake(itemViewWidth*_model.numberOfVideos, itemViewHeight+20.0f);
    self.overlayView.videoListScrollView.delegate = self;
    
    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_group_async(group, queue, ^{
        
        for ( NSUInteger i = 0; i < _model.numberOfVideos; ++i ) {
            
            NSManagedObjectContext *context = [self.appDelegate context];
            NSManagedObjectID *objectID = [(self.videoFrames)[i] objectID];
            Frame *videoFrame = (Frame *)[context existingObjectWithID:objectID error:nil];
            
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"SPVideoItemView" owner:self options:nil];
            SPVideoItemView *itemView = nib[0];
            [itemView setTag:i];
        
            CGRect itemFrame = itemView.frame;
            itemFrame.origin.x = itemViewWidth * i;
            itemFrame.origin.y = 0.0f;
            [itemView setFrame:itemFrame];
            
            UIImageView *videoListThumbnailPlaceholderView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"videoListThumbnail"]];
            [AsynchronousFreeloader loadImageFromLink:videoFrame.video.thumbnailURL
                                         forImageView:itemView.thumbnailImageView
                                  withPlaceholderView:videoListThumbnailPlaceholderView
                                       andContentMode:UIViewContentModeCenter];
        
            dispatch_async(dispatch_get_main_queue(), ^{
                
               [itemView.videoTitleLabel setText:videoFrame.video.title];
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
        maxVideosAllowed = 4;
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
    
    if ( position < _model.numberOfVideos ) {
        
        [player queueVideo];
    
    } else {
    
        // Do nothing
    
    }
}

- (void)currentVideoDidFinishPlayback
{
    NSUInteger position = _model.currentVideo + 1;
    CGFloat x = position * 1024.0f;
    CGFloat y = _videoScrollView.contentOffset.y;
    
    if ( position <= (_model.numberOfVideos-1) ) {
    
        [self.videoScrollView setContentOffset:CGPointMake(x, y) animated:YES];
        [self currentVideoDidChangeToVideo:position];
    
    }
}

#pragma mark - Action Methods (Public)
- (IBAction)homeButtonAction:(id)sender
{
    
    if (!self.inTransition) {
        [self setInTransition:YES];
        
        if ([self.model.currentVideoPlayer isPlaying]) {
            UIImage *videoCapture = [ImageUtilities captureVideo:self.model.currentVideoPlayer.player toSize:self.screenshot.frame.size];
            if (videoCapture) {
                [self setPlayerScreenshot:videoCapture];
            }
        }
        
        // Cancel remaining MP4 extractions
        [[SPVideoExtractor sharedInstance] cancelRemainingExtractions];
        
        // Remove Scrubber Timer and Observer
        [[SPVideoScrubber sharedInstance] stopObserving];
        
        // Remove references on model
        [self.model destroyModel];
        
        // Stop residual audio playback (this shouldn't be happening to begin with)
        [self.videoPlayers makeObjectsPerformSelector:@selector(pause)];
        
        // Releas everything
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
        
        // Remove older videos (channelID will be nil for stream, likes, and personal roll)
        [dataUtility removeOlderVideoFramesForCategoryType:_categoryType andChannelID:_channelID];
        
        // All video.extractedURL references are temporary (session-dependent), so they should be removed when the app shuts down.
        [dataUtility removeAllVideoExtractionURLReferences];
        
        [self transformOutAnimation];
    
    }
}

- (IBAction)playButtonAction:(id)sender
{
    [self.model.currentVideoPlayer togglePlayback];
}

- (IBAction)shareButtonAction:(id)sender
{
    [self.model.currentVideoPlayer share];
}

- (IBAction)itemButtonAction:(id)sender
{
    
    // Pause currentVideo Player
    [self.model.currentVideoPlayer pause];
    
    // Reference SPVideoItemView from position in videoListScrollView object
    SPVideoItemView *itemView = (SPVideoItemView *)[sender superview];
    NSUInteger position = itemView.tag;
    
    // Force scroll videoScrollView
    CGFloat videoX = 1024 * position;
    CGFloat videoY = _videoScrollView.contentOffset.y;
    
    if ( position < _model.numberOfVideos ) {
        [self.videoScrollView setContentOffset:CGPointMake(videoX, videoY) animated:YES];
    }
    
    // Perform actions on videoChange
    [self currentVideoDidChangeToVideo:position];
    
}

- (void)restartPlaybackButtonAction:(id)sender
{
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
    if ( self.categoryType == CategoryType_Stream ) {
        
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
    Frame *videoFrame = (Frame *)[context existingObjectWithID:objectID error:nil];
    
    // Set new values on infoPanel
    self.overlayView.videoTitleLabel.text = videoFrame.video.title;
    
    CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
    self.overlayView.videoCaptionLabel.text = [dataUtility fetchTextFromFirstMessageInConversation:videoFrame.conversation];
    self.overlayView.nicknameLabel.text = [NSString stringWithFormat:@"Shared by %@", videoFrame.creator.nickname];
    UIImageView *infoPanelIconPlaceholderView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"infoPanelIconPlaceholder"]];
    [AsynchronousFreeloader loadImageFromLink:videoFrame.creator.userImage
                                 forImageView:_overlayView.userImageView
                          withPlaceholderView:infoPanelIconPlaceholderView
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

        if ( [self.model.currentVideoPlayer isPlayable] ) { // Video IS Playable
            
            [self.model.currentVideoPlayer play];
            
            if ( [self.model.currentVideoPlayer playbackFinished] ) { // Playable video DID finish playing
                
                [self.overlayView.restartPlaybackButton setHidden:NO];
                [self.overlayView.playButton setEnabled:NO];
                [self.overlayView.scrubber setEnabled:NO];
                [self.overlayView.shareButton setEnabled:YES]; //
                
            } else { // Playable video DID NOT finish playing
                
                [self.overlayView.restartPlaybackButton setHidden:YES];
                [self.overlayView.playButton setEnabled:YES];
                [self.overlayView.scrubber setEnabled:YES];
                [self.overlayView.shareButton setEnabled:YES];
                
            }
            
        } else { // Video IS NOT Playable
            
            [self.overlayView.restartPlaybackButton setHidden:YES];
            [self.overlayView.playButton setEnabled:NO];
            [self.overlayView.scrubber setEnabled:NO];
            [self.overlayView.shareButton setEnabled:NO];
            
            [self.overlayView.playButton setImage:[UIImage imageNamed:@"playButton"] forState:UIControlStateNormal];
            [self.overlayView.scrubber setValue:0.0f];
            [self.overlayView.scrubberTimeLabel setText:@"00:00:00 / 00:00:00"];
            
        }
        
    });

}

- (void)queueMoreVideos:(NSUInteger)position
{
    if ( [self.videoPlayers count] ) {
    
        if ( [[UIScreen mainScreen] isRetinaDisplay] ) { // iPad 3 or better (e.g., device with more RAM and better processor)
        
            [[SPVideoExtractor sharedInstance] emptyQueue];
            [self extractVideoForVideoPlayer:position]; // Load video for current visible view
            if ( position + 1 < self.model.numberOfVideos ) [self extractVideoForVideoPlayer:position+1];
            if ( position + 2 < self.model.numberOfVideos ) [self extractVideoForVideoPlayer:position+2];
            
        } else { // iPad 2 or iPad Mini 1
            
            [[SPVideoExtractor sharedInstance] emptyQueue];
            [self extractVideoForVideoPlayer:position]; // Load video for current visible view
            if ( position + 1 < self.model.numberOfVideos ) [self extractVideoForVideoPlayer:position+1];
            
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
            
            switch ( self.categoryType ) {
                    
                    
                case CategoryType_Stream:{
                    
                    NSUInteger totalNumberOfVideosInDatabase = [dataUtility fetchStreamCount];
                    NSString *numberToString = [NSString stringWithFormat:@"%d", totalNumberOfVideosInDatabase];
                    [ShelbyAPIClient getMoreFramesInStream:numberToString];
                    
                } break;
                    
                case CategoryType_Likes:{
                    
                    NSUInteger totalNumberOfVideosInDatabase = [dataUtility fetchLikesCount];
                    NSString *numberToString = [NSString stringWithFormat:@"%d", totalNumberOfVideosInDatabase];
                    [ShelbyAPIClient getMoreFramesInLikes:numberToString];
                    
                } break;
                    
                case CategoryType_PersonalRoll:{
                    
                    NSUInteger totalNumberOfVideosInDatabase = [dataUtility fetchPersonalRollCount];
                    NSString *numberToString = [NSString stringWithFormat:@"%d", totalNumberOfVideosInDatabase];
                    [ShelbyAPIClient getMoreFramesInPersonalRoll:numberToString];
                    
                } break;
                    
                case CategoryType_Channel:{
                    
                    NSUInteger totalNumberOfVideosInDatabase = [dataUtility fetchCountForChannel:_channelID];
                    NSString *numberToString = [NSString stringWithFormat:@"%d", totalNumberOfVideosInDatabase];
                    [ShelbyAPIClient getMoreFrames:numberToString forChannel:_channelID];

                    
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
        
        switch ( self.categoryType ) {
                
            case CategoryType_Stream:{
                [olderFramesArray addObjectsFromArray:[dataUtility fetchMoreStreamEntriesAfterDate:date]];
            } break;
                
            case CategoryType_Likes:{
                [olderFramesArray addObjectsFromArray:[dataUtility fetchMoreLikesEntriesAfterDate:date]];
            } break;
                
            case CategoryType_PersonalRoll:{
                [olderFramesArray addObjectsFromArray:[dataUtility fetchMorePersonalRollEntriesAfterDate:date]];
            } break;
                
            case CategoryType_Channel:{
                [olderFramesArray addObjectsFromArray:[dataUtility fetchMoreFramesInChannel:_channelID afterDate:date]];
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
            Frame *videoFrame = (Frame *)[context existingObjectWithID:objectID error:nil];
            
            CGRect viewframe = [self.videoScrollView frame];
            viewframe.origin.x = viewframe.size.width * i;
            SPVideoPlayer *player = [[SPVideoPlayer alloc] initWithBounds:viewframe withVideoFrame:videoFrame];
            
            // videoListScrollView
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"SPVideoItemView" owner:self options:nil];
            SPVideoItemView *itemView = nib[0];
            
            CGFloat itemViewWidth = [SPVideoItemView width];
            CGFloat itemViewHeight = [SPVideoItemView height];
            CGRect itemFrame = itemView.frame;
            itemFrame.origin.x = itemViewWidth * i;
            [itemView setFrame:itemFrame];
            [itemView setTag:i];
            
            UIImageView *videoListThumbnailPlaceholderView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"videoListThumbnail"]];
            [AsynchronousFreeloader loadImageFromLink:videoFrame.video.thumbnailURL
                                         forImageView:itemView.thumbnailImageView
                                  withPlaceholderView:videoListThumbnailPlaceholderView
                                       andContentMode:UIViewContentModeCenter];
            
            // Update UI on Main Thread
            dispatch_async(dispatch_get_main_queue(), ^{
                self.videoScrollView.contentSize = CGSizeMake(1024.0f*(i+1), 768.0f);
                [self.videoPlayers addObject:player];
                [self.videoScrollView addSubview:player.view];
                [self.videoScrollView setNeedsDisplay];
                
                itemView.backgroundColor = [UIColor clearColor];
                itemView.videoTitleLabel.textColor = kShelbyColorBlack;
                [itemView.videoTitleLabel setText:videoFrame.video.title];
                self.overlayView.videoListScrollView.contentSize = CGSizeMake(itemViewWidth*(i+1), itemViewHeight+20.0f);
                [self.itemViews addObject:itemView];
                [self.overlayView.videoListScrollView addSubview:itemView];
                [self.overlayView.videoListScrollView setNeedsDisplay];
                
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
        
        if ( self.model.currentVideoPlayer.videoFrame == [self.videoFrames objectAtIndex:_model.currentVideo]) { // Load AND scroll to nextvideo
            
            [self currentVideoDidChangeToVideo:position];
            
        } else { // Load next video, (but do not scroll)
            
            [self extractVideoForVideoPlayer:position];
            
        }
    }
}

#pragma mark - Transition Methods (Private)
- (void)transformInAnimation
{
    if (self.inTransition) {
        return;
    }
    
    [self setInTransition:YES];
    
    [self.overlayView setAlpha:0];
    [self.view bringSubviewToFront:self.screenshot];
    [self.view bringSubviewToFront:self.zoomInScreenshot];
    
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarStyleBlackTranslucent];
    [UIView animateWithDuration:0.5 animations:^{
        [self.zoomInScreenshot setFrame:CGRectMake(-self.view.frame.size.width / 2, -self.view.frame.size.height / 2, self.view.frame.size.width * 2, self.view.frame.size.height * 2)];
    }];

    [self performSelector:@selector(fadeOutAnimationForTransformIn) withObject:nil afterDelay:0.2];
}

- (void)fadeOutAnimationForTransformIn
{
    [self.screenshot setAlpha:0];
    [UIView animateWithDuration:0.3 animations:^{
        [self.zoomInScreenshot setAlpha:0];
        [self.overlayView setAlpha:1];
    } completion:^(BOOL finished) {
        [self.screenshot removeFromSuperview];
        [self.zoomInScreenshot removeFromSuperview];
        [self setInTransition:NO];

    }];
}

- (void)transformOutAnimation
{
    [self setInTransition:YES];
    
    UIImage *currentScreenshot = nil;
    if (self.playerScreenshot) {
        currentScreenshot = self.playerScreenshot;
    } else {
        currentScreenshot = [ImageUtilities screenshot:self.overlayView];
    }
    
    UIImageView *currentScreenshotImage = [[UIImageView alloc] initWithImage:currentScreenshot];
    [self setPlayerScreenshot:nil];
  
    [self.zoomInScreenshot setAlpha:1];
    [self.zoomInScreenshot setFrame:currentScreenshotImage.frame];
 
    [self.zoomInScreenshot addSubview:currentScreenshotImage];
    
    [self.screenshot setAlpha:1];
    [self.view addSubview:self.screenshot];
    [self.view addSubview:self.zoomInScreenshot];
    
    [self.view bringSubviewToFront:self.screenshot];
    [self.view bringSubviewToFront:self.zoomInScreenshot];
    
    [UIView animateWithDuration:0.5 animations:^{
        [self.zoomInScreenshot setFrame:self.zoomInScreenshotFrame];
    } completion:^(BOOL finished) {
        
    }];
    
    [self performSelector:@selector(fadeOutAnimationForTransformOut:) withObject:currentScreenshotImage afterDelay:0.2];
    
}

- (void)fadeOutAnimationForTransformOut:(UIImageView *)currentScreenshot
{
    [UIView animateWithDuration:0.3 animations:^{
        [currentScreenshot setAlpha:0];
    } completion:^(BOOL finished) {
        [self setInTransition:NO];
        
        [self dismissViewControllerAnimated:NO completion:nil];
    }];    
}

#pragma mark - UIScrollViewDelegate Methods
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
            
        }
        
        [self currentVideoDidChangeToVideo:page];
        [self fetchOlderVideos:page];
    
    } else if ( scrollView == _overlayView.videoListScrollView ) {
        
        // Switch the indicator when more than 50% of the previous/next page is visible
        CGFloat pageWidth = scrollView.frame.size.width;
        CGFloat scrollAmount = 2.85*(scrollView.contentOffset.x - pageWidth / 2) / pageWidth; // Multiply by ~3 since each visible section has ~3 videos.
        NSUInteger page = floor(scrollAmount) + 1;
        [self fetchOlderVideos:page];
        
        [self.overlayView rescheduleOverlayTimer];
    }
}

@end
