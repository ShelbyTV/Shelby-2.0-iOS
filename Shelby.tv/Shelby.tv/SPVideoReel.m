     
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
@property (assign, nonatomic) BOOL fetchingOlderVideos;
@property (assign, nonatomic) BOOL loadingOlderVideos;

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

@end

@implementation SPVideoReel 

#pragma mark - Memory Management
- (void)dealloc
{

    [[NSNotificationCenter defaultCenter] removeObserver:self name:kSPUserDidScrollToUpdate object:nil];
    
    // All video.extractedURL references are temporary (session-dependent), so they should be removed when the app shuts down.
    CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
    [dataUtility removeAllVideoExtractionURLReferences];

    DLog(@"SPVideoReel Deallocated");
    
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
- (void)setupVideoFrames:(NSArray *)videoFrames
{
    
    self.videoFrames = [@[] mutableCopy];
    
    if ( [videoFrames count] > 20 ) { // If there are more than 20 frames in videoFrames
        
        for ( NSUInteger i = 0; i<[videoFrames count]; i++ ) {
            
            if ( [videoFrames count] < 20) { // Load the first 20 videoFrames into _videoFrames
             
                [self.videoFrames addObject:videoFrames];
                
            } else { // Load the rest of the videoFrames into _moreVideoFrames
                
                [self.moreVideoFrames addObject:videoFrames];
                
            }
        }
        
    } else { // If there are <= 20 frames in videoFrames
        
        self.videoFrames = [videoFrames mutableCopy];
        
    }
}

- (void)setupVariables
{
    self.appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    self.model = [SPModel sharedInstance];
    self.model.videoReel = self;
    self.model.numberOfVideos = [self.videoFrames count];
    self.videoPlayers = [@[] mutableCopy];
    self.itemViews = [@[] mutableCopy];
}

- (void)setupObservers
{

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(dataSourceShouldUpdateFromWeb:)
                                                 name:kSPUserDidScrollToUpdate
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

    for ( NSUInteger i = 0; i < self.model.numberOfVideos; ++i ) {
        
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
        
        
    } else { // If  stream, play video stored for kSPCurrentVideoStreamID if it exists. Otherwise, default to video at zeroeth position

        for ( NSUInteger i = 0; i < _model.numberOfVideos; ++i ) {
            
            Frame *videoFrame = (self.videoFrames)[i];
            NSString *storedStreamID = [[NSUserDefaults standardUserDefaults] objectForKey:kSPCurrentVideoStreamID];
            
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
    self.overlayView.videoListScrollView.contentSize = CGSizeMake(itemViewWidth*_model.numberOfVideos, 217.0f);
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
                    itemView.backgroundColor = kColorGreen;
                    itemView.videoTitleLabel.textColor = kColorBlack;
                }
                
            });
        }
        
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
    NSUInteger maxVideosAllowed = ( [[UIScreen mainScreen] isRetinaDisplay] ) ? 4 : 2;
    
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
    
    if ( (position >= _model.numberOfVideos) ) {
        
        return;
    
    } else {
    
        [player queueVideo];
    
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
    
    if ( ![self isBeingDismissed] ) {
        
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
        
        [self dismissViewControllerAnimated:YES completion:nil];
    
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
    
    [[NSUserDefaults standardUserDefaults] setObject:videoFrame.frameID forKey:kSPCurrentVideoStreamID];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


#pragma mark -  Update Methods (Private)
- (void)currentVideoDidChangeToVideo:(NSUInteger)position
{
     
    // Disable timer
    [self.model.overlayTimer invalidate];
    
    // Show Overlay
    [self.overlayView showOverlay];
    
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
                    
                case CategoryType_Unknown:{
                    
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
                
            case CategoryType_Unknown:{
                
            }
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
        
    }
}

@end
