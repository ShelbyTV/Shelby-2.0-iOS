//
//  SPVideoReel.m
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 11/1/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

#import "SPVideoReel.h"
#import "SPModel.h"
#import "SPOverlayView.h"
#import "SPVideoItemView.h"
#import "SPVideoPlayer.h"
#import "MeViewController.h"

@interface SPVideoReel ()

@property (nonatomic) AppDelegate *appDelegate;
@property (nonatomic) SPModel *model;
@property (nonatomic) SPOverlayView *overlayView;
@property (nonatomic) UIScrollView *videoScrollView;
@property (nonatomic) NSMutableArray *videoFrames;
@property (nonatomic) NSMutableArray *videoPlayers;
@property (nonatomic) NSMutableArray *itemViews;
@property (copy, nonatomic) NSString *categoryTitle;
@property (assign, nonatomic) BOOL fetchingOlderVideos;
@property (assign, nonatomic) BOOL loadingOlderVideos;

/// Setup Methods
- (void)setupVariables;
- (void)setupObservers;
- (void)setupVideoScrollView;
- (void)setupVideoListScrollView;
- (void)setupOverlayView;
- (void)setupAirPlay;
- (void)setupVideoPlayers;

/// Update Methods
- (void)currentVideoDidChangeToVideo:(NSUInteger)position;
- (void)storeIdentifierOfCurrentVideoInStream;
- (void)fetchOlderVideos:(NSUInteger)position;
- (void)dataSourceDidUpdate:(NSNotification*)notification;

@end

@implementation SPVideoReel
@synthesize appDelegate = _appDelegate;
@synthesize model = _model;
@synthesize categoryTitle = _categoryTitle;
@synthesize toggleOverlayGesuture = _toggleOverlayGesuture;
@synthesize categoryType = _categoryType;
@synthesize videoFrames = _videoFrames;
@synthesize videoPlayers = _videoPlayers;
@synthesize itemViews = _itemViews;
@synthesize videoScrollView = _videoScrollView;
@synthesize fetchingOlderVideos = _fetchingOlderVideos;
@synthesize loadingOlderVideos = _loadingOlderVideos;
@synthesize airPlayButton = _airPlayButton;

#pragma mark - Memory Management
- (void)dealloc
{

    [[NSNotificationCenter defaultCenter] removeObserver:self name:kSPUserDidScrollToUpdate object:nil];
    
    // All video.extractedURL references are temporary (session-dependent), so they should be removed when the app shuts down.
    CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
    [dataUtility removeAllVideoExtractionURLReferences];
}

#pragma mark - Initialization
- (id)initWithCategoryType:(CategoryType)categoryType categoryTitle:(NSString *)title andVideoFrames:(NSArray *)videoFrames
{
    
    if ( (self = [super init]) ) {
        
        self.categoryType = categoryType;
        self.categoryTitle = title;
        self.videoFrames = [videoFrames mutableCopy];
        
    }
    
    return self;
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
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self setupVideoListScrollView];
}

#pragma mark - Setup Methods
- (void)setupVariables
{
    self.appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    self.model = [SPModel sharedInstance];
    self.model.videoReel = self;
    self.model.numberOfVideos = [self.videoFrames count];
    self.videoPlayers = [@[] mutableCopy];
    self.itemViews = [@[] mutableCopy];
}

- (void)setupObservers
{

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(dataSourceDidUpdate:)
                                                 name:kSPUserDidScrollToUpdate
                                               object:nil];
}

- (void)setupVideoScrollView
{
    self.videoScrollView = [[UIScrollView alloc] initWithFrame:self.view.frame];
    self.videoScrollView.contentSize = CGSizeMake(1024.0f*self.model.numberOfVideos, 748.0f);
    self.videoScrollView.delegate = self;
    self.videoScrollView.pagingEnabled = YES;
    self.videoScrollView.showsHorizontalScrollIndicator = NO;
    self.videoScrollView.showsVerticalScrollIndicator = NO;
    self.videoScrollView.scrollsToTop = NO;
    [self.view addSubview:self.videoScrollView];
}

- (void)setupOverlayView
{
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"SPOverlayView" owner:self options:nil];
    self.model.overlayView = nib[0];
    self.overlayView = self.model.overlayView;
    [self.overlayView.categoryTitleLabel setText:self.categoryTitle];
    [self.view addSubview:self.overlayView];
    
    self.toggleOverlayGesuture = [[UITapGestureRecognizer alloc] initWithTarget:self.overlayView action:@selector(toggleOverlay)];
    [self.toggleOverlayGesuture setNumberOfTapsRequired:1];
    [self.view addGestureRecognizer:self.toggleOverlayGesuture];
    
    UIPinchGestureRecognizer *pinchOverlayGesuture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(homeButtonAction:)];
    [self.view addGestureRecognizer:pinchOverlayGesuture];
    
}

- (void)setupVideoPlayers
{
    
    for ( NSUInteger i = 0; i < self.model.numberOfVideos; ++i ) {
        
        Frame *videoFrame = (self.videoFrames)[i];

        CGRect viewframe = self.videoScrollView.frame;
        viewframe.origin.x = viewframe.size.width * i;
        viewframe.origin.y = 0.0f;
        SPVideoPlayer *player = [[SPVideoPlayer alloc] initWithBounds:viewframe withVideoFrame:videoFrame];
        
        [self.videoPlayers addObject:player];
        [self.videoScrollView addSubview:player.view];
        
    }

    // If not stream, play video in zeroeth position
    if ( self.categoryType != CategoryType_Stream ) {
        
        self.model.currentVideo = 0;
        self.model.currentVideoPlayer = (self.videoPlayers)[self.model.currentVideo];
        [self currentVideoDidChangeToVideo:self.model.currentVideo];
        
        
    } else {
        
        self.model.currentVideo = 0;
        self.model.currentVideoPlayer = (self.videoPlayers)[self.model.currentVideo];
        
        for ( NSUInteger i = 0; i < self.model.numberOfVideos; ++i ) {
            
            Frame *videoFrame = (self.videoFrames)[i];
            NSString *storedStreamID = [[NSUserDefaults standardUserDefaults] objectForKey:kSPCurrentVideoStreamID];
            
            if ( [videoFrame.frameID isEqualToString:storedStreamID] ) {
             
                self.model.currentVideo = i;
                self.model.currentVideoPlayer = (self.videoPlayers)[self.model.currentVideo];
                
            }
        }
        
        [self currentVideoDidChangeToVideo:self.model.currentVideo];
        
    }
}

- (void)setupVideoListScrollView
{

    CGFloat itemViewWidth = [SPVideoItemView width];
    self.overlayView.videoListScrollView.contentSize = CGSizeMake(itemViewWidth*self.model.numberOfVideos, 217.0f);
    self.overlayView.videoListScrollView.delegate = self;
    
    for ( NSUInteger i = 0; i < self.model.numberOfVideos; ++i ) {
        
        NSManagedObjectContext *context = [self.appDelegate context];
        NSManagedObjectID *objectID = [(self.videoFrames)[i] objectID];
        Frame *videoFrame = (Frame*)[context existingObjectWithID:objectID error:nil];

        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"SPVideoItemView" owner:self options:nil];
        SPVideoItemView *itemView = nib[0];
            
        CGRect itemFrame = itemView.frame;
        itemFrame.origin.x = itemViewWidth * i;
        itemFrame.origin.y = 0.0f;
        [itemView setFrame:itemFrame];
        
        [itemView.videoTitleLabel setText:videoFrame.video.title];
        UIImageView *videoListThumbnailPlaceholderView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"videoListThumbnail"]];
        [AsynchronousFreeloader loadImageFromLink:videoFrame.video.thumbnailURL
                                     forImageView:itemView.thumbnailImageView
                              withPlaceholderView:videoListThumbnailPlaceholderView
                                   andContentMode:UIViewContentModeCenter];
        [itemView setTag:i];
        
        [self.itemViews addObject:itemView];
        [self.overlayView.videoListScrollView addSubview:itemView];
        
    }
    
    // Add visual selected state (e.g., blue background, white text) to currentVideo
    SPVideoItemView *itemView = (self.itemViews)[self.model.currentVideo];
    itemView.backgroundColor = kColorGreen;
    itemView.videoTitleLabel.textColor = kColorBlack;

    // Scroll To currentVideo if self.currentVideo != 0
    if ( 0 != self.model.currentVideo) {
        
        CGFloat x = self.videoScrollView.frame.size.width * self.model.currentVideo;
        CGFloat y = self.videoScrollView.contentOffset.y;
        [self.videoScrollView setContentOffset:CGPointMake(x, y) animated:YES];
        
        CGFloat itemViewX = itemView.frame.size.width * (self.model.currentVideo-1);
        CGFloat itemViewY = self.overlayView.videoListScrollView.contentOffset.y;
        [self.overlayView.videoListScrollView setContentOffset:CGPointMake(itemViewX, itemViewY) animated:YES];
        
    }

}

- (void)setupAirPlay
{
    
    // Instantiate AirPlay button for MPVolumeView
    MPVolumeView *volumeView = [[MPVolumeView alloc] initWithFrame:self.overlayView.airPlayView.bounds];
    [volumeView setShowsVolumeSlider:NO];
    [volumeView setShowsRouteButton:YES];
    [self.overlayView.airPlayView addSubview:volumeView];
    
    for (UIView *view in volumeView.subviews) {
        
        if ( [view isKindOfClass:[UIButton class]] ) {
            
            self.airPlayButton = (UIButton*)view;
            
        }
    }
}

#pragma mark - Public Update Methods
- (void)extractVideoForVideoPlayer:(NSUInteger)position
{
    SPVideoPlayer *player = (self.videoPlayers)[position];
    
    if ( (position >= self.model.numberOfVideos) ) {
        return;
    } else {
       [player queueVideo];
    }

}

- (void)currentVideoDidFinishPlayback
{
    NSUInteger position = self.model.currentVideo + 1;
    CGFloat x = position * 1024.0f;
    CGFloat y = self.videoScrollView.contentOffset.y;
    if ( position <= (self.model.numberOfVideos-1) ) {
        [self.videoScrollView setContentOffset:CGPointMake(x, y) animated:YES];
        [self currentVideoDidChangeToVideo:position];
    }
}

#pragma mark - Private Update Methods
- (void)currentVideoDidChangeToVideo:(NSUInteger)position
{
    
    // Disable timer
    [self.model.overlayTimer invalidate];
    
    // Show Overlay
    [self.overlayView showOverlay];
    
    // Pause current videoPlayer
    if ( [self.model.currentVideoPlayer isPlayable] )
        [self.model.currentVideoPlayer pause];
    
    // Reset currentVideoPlayer reference after scrolling has finished
    self.model.currentVideo = position;
    self.model.currentVideoPlayer = (self.videoPlayers)[position];
    
    // If videoReel is instance of Stream, store currentVideoID
    if ( self.categoryType == CategoryType_Stream )
        [self storeIdentifierOfCurrentVideoInStream];
    
    // Deal with playback methods & UI of current and previous video
    if ( [self.model.currentVideoPlayer isPlayable] ) { // Video IS Playable
        
        [self.model.currentVideoPlayer play];
        [self.model.videoScrubberDelegate syncScrubber];
        
        if ( [self.model.currentVideoPlayer playbackFinished] ) { // PLayable DID finish playing
            
            [self.overlayView.restartPlaybackButton setHidden:NO];
            [self.overlayView.playButton setEnabled:NO];
            [self.overlayView.scrubber setEnabled:NO];
            
        } else { // Playable video DID NOT finish played
            
            [self.overlayView.restartPlaybackButton setHidden:YES];
            [self.overlayView.playButton setEnabled:YES];
            [self.overlayView.scrubber setEnabled:YES];
            
        }
        
    } else { // Video IS NOT Playable
        
        [self.overlayView.restartPlaybackButton setHidden:YES];
        [self.overlayView.playButton setEnabled:NO];
        [self.overlayView.scrubber setEnabled:NO];
        
        [self.overlayView.playButton setImage:[UIImage imageNamed:@"playButton"] forState:UIControlStateNormal];
        [self.overlayView.scrubber setValue:0.0f];
        [self.overlayView.scrubberTimeLabel setText:@"00:00:00 / 00:00:00"];
        
    }
    
    // Clear old values on infoCard
    [self.overlayView.videoTitleLabel setText:nil];
    [self.overlayView.videoCaptionLabel setText:nil];
    [self.overlayView.nicknameLabel setText:nil];
    [self.overlayView.userImageView setImage:nil];
    
    // Reference NSManageObjectContext
    NSManagedObjectContext *context = [self.appDelegate context];
    NSManagedObjectID *objectID = [(self.videoFrames)[self.model.currentVideo] objectID];
    Frame *videoFrame = (Frame*)[context existingObjectWithID:objectID error:nil];
    
    // Set new values on infoPanel
    self.overlayView.videoTitleLabel.text = videoFrame.video.title;
    
    CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
    self.overlayView.videoCaptionLabel.text = [dataUtility fetchTextFromFirstMessageInConversation:videoFrame.conversation];
    self.overlayView.nicknameLabel.text = [NSString stringWithFormat:@"Shared by %@", videoFrame.creator.nickname];
    UIImageView *infoPanelIconPlaceholderView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"infoPanelIconPlaceholder"]];
    [AsynchronousFreeloader loadImageFromLink:videoFrame.creator.userImage
                                 forImageView:self.overlayView.userImageView
                          withPlaceholderView:infoPanelIconPlaceholderView
                               andContentMode:UIViewContentModeScaleAspectFit];
    
    // Update videoListScrollView (if _itemViews is initialized)
    if ( 0 < [self.itemViews count] ) {
        
        // Remove selected state color from all SPVideoItemView objects
        for (SPVideoItemView *itemView in self.itemViews) {
            itemView.backgroundColor = [UIColor clearColor];
            itemView.videoTitleLabel.textColor = kColorBlack;
        }
        
        // Update currentVideo's SPVideoItemView object UI and position in videoListScrollView object
        SPVideoItemView *itemView = (self.itemViews)[position];
        itemView.backgroundColor = kColorGreen;
        itemView.videoTitleLabel.textColor = kColorBlack;
        if ( position < self.model.numberOfVideos ) {
            CGFloat itemX = itemView.frame.size.width * position;
            CGFloat itemY = 0.0f;
            [self.overlayView.videoListScrollView setContentOffset:CGPointMake(itemX, itemY) animated:YES];
        }
        
    }
    
    // Queue current and next 3 videos
    if ( 0 < [self.videoPlayers count] ) {
        [self.model.videoExtractor emptyQueue];
        [self extractVideoForVideoPlayer:position]; // Load video for current visible view
        if ( position + 1 < self.model.numberOfVideos ) [self extractVideoForVideoPlayer:position+1];
        if ( position + 2 < self.model.numberOfVideos ) [self extractVideoForVideoPlayer:position+2];
        if ( position + 3 < self.model.numberOfVideos ) [self extractVideoForVideoPlayer:position+3];
    }
    
}

- (void)storeIdentifierOfCurrentVideoInStream
{
    NSManagedObjectContext *context = [self.appDelegate context];
    NSManagedObjectID *objectID = [(self.videoFrames)[self.model.currentVideo] objectID];
    Frame *videoFrame = (Frame*)[context existingObjectWithID:objectID error:nil];
    
    [[NSUserDefaults standardUserDefaults] setObject:videoFrame.frameID forKey:kSPCurrentVideoStreamID];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)fetchOlderVideos:(NSUInteger)position
{
    if ( position >= self.model.numberOfVideos - 7 && ![self fetchingOlderVideos] ) {
        
        self.fetchingOlderVideos = YES;
        
        CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
        
        switch ( self.categoryType ) {

                
            case CategoryType_Stream:{
                
                NSUInteger totalNumberOfVideosInDatabase = [dataUtility fetchStreamCount];
                NSString *numberToString = [NSString stringWithFormat:@"%d", totalNumberOfVideosInDatabase];
                [ShelbyAPIClient getMoreFramesInStream:numberToString];
                
            } break;
                
            case CategoryType_QueueRoll:{
                
                NSUInteger totalNumberOfVideosInDatabase = [dataUtility fetchQueueRollCount];
                NSString *numberToString = [NSString stringWithFormat:@"%d", totalNumberOfVideosInDatabase];
                [ShelbyAPIClient getMoreFramesInQueueRoll:numberToString];
                
            } break;
                
            case CategoryType_PersonalRoll:{
                
                NSUInteger totalNumberOfVideosInDatabase = [dataUtility fetchPersonalRollCount];
                NSString *numberToString = [NSString stringWithFormat:@"%d", totalNumberOfVideosInDatabase];
                [ShelbyAPIClient getMoreFramesInPersonalRoll:numberToString];
                
            } break;
                
            case CategoryType_Unknown:{
                
            } break;
                
        }
    }
}

- (void)dataSourceDidUpdate:(NSNotification*)notification
{
    
    if ( [self fetchingOlderVideos] && ![self loadingOlderVideos] ) { 
    
        [self setLoadingOlderVideos:YES];
        
        NSManagedObjectContext *context = [self.appDelegate context];
        NSManagedObjectID *lastFramedObjectID = [[self.videoFrames lastObject] objectID];
        Frame *lastFrame = (Frame*)[context existingObjectWithID:lastFramedObjectID error:nil];
        NSDate *date = lastFrame.timestamp;
    
        CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
        NSMutableArray *olderFramesArray = [@[] mutableCopy];
        
        switch ( self.categoryType ) {
                
            case CategoryType_Stream:{
                [olderFramesArray addObjectsFromArray:[dataUtility fetchMoreStreamEntriesAfterDate:date]];
            } break;
                
            case CategoryType_QueueRoll:{
                [olderFramesArray addObjectsFromArray:[dataUtility fetchMoreQueueRollEntriesAfterDate:date]];
            } break;
                
            case CategoryType_PersonalRoll:{
                [olderFramesArray addObjectsFromArray:[dataUtility fetchMorePersonalRollEntriesAfterDate:date]];
            } break;
                
            case CategoryType_Unknown:{
                
            }
        }
        
        // Compare last video from _videoFrames against first result of olderFramesArrays, and deduplicate if necessary
        Frame *firstFrame = (Frame*)olderFramesArray[0];
        NSManagedObjectID *firstFrameObjectID = [firstFrame objectID];
        firstFrame = (Frame*)[context existingObjectWithID:firstFrameObjectID error:nil];
        if ( [firstFrame.videoID isEqualToString:lastFrame.videoID] ) {
            [olderFramesArray removeObject:firstFrame];
        }
        
        // Add deduplicated frames from olderFramesArray to videoFrames 
        [self.videoFrames addObjectsFromArray:olderFramesArray];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            // Update variables
            NSUInteger numberOfVideosBeforeUpdate = [self.model numberOfVideos];
            self.model.numberOfVideos = [self.videoFrames count];
            
            // Update videoScrollView and videoListScrollView
            for ( NSUInteger i = numberOfVideosBeforeUpdate; i < self.model.numberOfVideos; ++i ) {
                
                // videoScrollView
                NSManagedObjectContext *context = [self.appDelegate context];
                NSManagedObjectID *objectID = [(self.videoFrames)[i] objectID];
                Frame *videoFrame = (Frame*)[context existingObjectWithID:objectID error:nil];
                
                CGRect viewframe = self.videoScrollView.frame;
                viewframe.origin.x = viewframe.size.width * i;
                viewframe.origin.y = 0.0f;
                SPVideoPlayer *player = [[SPVideoPlayer alloc] initWithBounds:viewframe withVideoFrame:videoFrame];
                
                // videoListScrollView
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"SPVideoItemView" owner:self options:nil];
                SPVideoItemView *itemView = nib[0];
                
                CGFloat itemViewWidth = [SPVideoItemView width];
                CGRect itemFrame = itemView.frame;
                itemFrame.origin.x = itemViewWidth * i;
                itemFrame.origin.y = 20.0f;
                [itemView setFrame:itemFrame];
                [itemView setTag:i];
                
                UIImageView *videoListThumbnailPlaceholderView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"videoListThumbnail"]];
                [AsynchronousFreeloader loadImageFromLink:videoFrame.video.thumbnailURL
                                             forImageView:itemView.thumbnailImageView
                                      withPlaceholderView:videoListThumbnailPlaceholderView
                                           andContentMode:UIViewContentModeCenter];
                
                // Update UI on Main Thread
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.videoScrollView.contentSize = CGSizeMake(1024.0f*i, 768.0f);
                    [self.videoPlayers addObject:player];
                    [self.videoScrollView addSubview:player.view];
                    [self.videoScrollView setNeedsDisplay];
                    
                    itemView.backgroundColor = [UIColor clearColor];
                    itemView.videoTitleLabel.textColor = kColorBlack;
                    [itemView.videoTitleLabel setText:videoFrame.video.title];
                    self.overlayView.videoListScrollView.contentSize = CGSizeMake(itemViewWidth*i, 217.0f);
                    [self.itemViews addObject:itemView];
                    [self.overlayView.videoListScrollView addSubview:itemView];
                    [self.overlayView.videoListScrollView setNeedsDisplay];
                    
                    [self setFetchingOlderVideos:NO];
                    [self setLoadingOlderVideos:NO];
                });
            }
        });
    }
}

#pragma mark - Public Action Methods
- (IBAction)homeButtonAction:(id)sender
{
    
    if ( ![self isBeingDismissed] ) {
    
        // Stop residual audio playback (this shouldn't be happening to begin with)

        [self dismissViewControllerAnimated:YES completion:^{
            
            [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarStyleBlackTranslucent];
            
            [self.videoPlayers makeObjectsPerformSelector:@selector(pause)];
            [[self.videoScrollView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
            [self.model teardown];
            
        }];
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
    SPVideoItemView *itemView = (SPVideoItemView*)[sender superview];
    NSUInteger position = itemView.tag;
    
    // Force scroll videoScrollView
    CGFloat videoX = 1024 * position;
    CGFloat videoY = self.videoScrollView.contentOffset.y;
    
    if ( position < self.model.numberOfVideos ) {
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
	self.model.scrubberTimeObserver = nil;
}

- (IBAction)scrub:(id)sender
{
    CMTime playerDuration = [self.model.currentVideoPlayer elapsedDuration];
    if (CMTIME_IS_INVALID(playerDuration)) {
        return;
    }
    
    double duration = CMTimeGetSeconds(playerDuration);
    if (isfinite(duration)) {
        
        float minValue = [self.overlayView.scrubber minimumValue];
        float maxValue = [self.overlayView.scrubber maximumValue];
        float value = [self.overlayView.scrubber value];
        double time = duration * (value - minValue) / (maxValue - minValue);
        [self.model.currentVideoPlayer.player seekToTime:CMTimeMakeWithSeconds(time, NSEC_PER_SEC)];
    }
}

- (IBAction)endScrubbing:(id)sender
{
    
	if ( ![self.model scrubberTimeObserver] ) {
		
        CMTime playerDuration = [self.model.currentVideoPlayer elapsedDuration];
		if (CMTIME_IS_INVALID(playerDuration)) {
			return;
		}
		
		double duration = CMTimeGetSeconds(playerDuration);
        
		if (isfinite(duration)) {
			CGFloat width = CGRectGetWidth([self.overlayView.scrubber bounds]);
			double tolerance = 0.5f * duration / width;
			self.model.scrubberTimeObserver = [self.model.videoScrubberDelegate.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(tolerance, NSEC_PER_SEC)
                                                                                                                    queue:NULL
                                                                                                               usingBlock:^(CMTime time) {
                                                                                                 
                            // Sync the scrubber to the currentVideoPlayer
                            [self.model.videoScrubberDelegate syncScrubber];
                            
                            // If video was playing before scrubbing began, make sure it continues to play, otherwise, pause the video
                            ( self.model.videoScrubberDelegate.isPlaying ) ? [self.model.videoScrubberDelegate play] : [self.model.videoScrubberDelegate pause];
                                                                                                 
                              }];
        }
	}
}

#pragma mark - UIScrollViewDelegate Methods
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    
    if ( scrollView == self.videoScrollView ) {
        
        // Switch the indicator when more than 50% of the previous/next page is visible
        CGFloat pageWidth = scrollView.frame.size.width;
        CGFloat scrollAmount = (scrollView.contentOffset.x - pageWidth / 2) / pageWidth;
        NSUInteger page = floor(scrollAmount) + 1;
        
        // Toggle playback on old and new SPVideoPlayer objects
        if ( page != self.model.currentVideo ) {
            
            SPVideoPlayer *oldPlayer = (self.videoPlayers)[self.model.currentVideo];
            [oldPlayer pause];
            
        }
        
        [self currentVideoDidChangeToVideo:page];
        [self fetchOlderVideos:page];
    
    } else if ( scrollView == self.overlayView.videoListScrollView ) {
        
        // Switch the indicator when more than 50% of the previous/next page is visible
        CGFloat pageWidth = scrollView.frame.size.width;
        CGFloat scrollAmount = 2.85*(scrollView.contentOffset.x - pageWidth / 2) / pageWidth; // Multiply by ~3 since each visible section has ~3 videos.
        NSUInteger page = floor(scrollAmount) + 1;
        [self fetchOlderVideos:page];
        
    }
}

@end
