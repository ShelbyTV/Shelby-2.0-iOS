//
//  SPVideoReel.m
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 11/1/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

#import "SPVideoReel.h"
#import "SPCacheUtility.h"
#import "SPOverlayView.h"
#import "SPVideoExtractor.h"
#import "SPVideoItemView.h"
#import "SPVideoPlayer.h"
#import "MeViewController.h"

@interface SPVideoReel ()

@property (strong, nonatomic) AppDelegate *appDelegate;
@property (strong, nonatomic) NSMutableArray *videoFrames;
@property (strong, nonatomic) NSMutableArray *videoPlayers;
@property (strong, nonatomic) NSMutableArray *itemViews;
@property (assign, nonatomic) NSUInteger currentVideo;
@property (copy, nonatomic) NSString *categoryTitle;
@property (assign, nonatomic) BOOL fetchingOlderVideos;

/// Setup Methods
- (void)setupVariables;
- (void)setupObservers;
- (void)setupVideoScrollView;
- (void)setupVideoListScrollView;
- (void)setupOverlayView;
- (void)setupVideoPlayers;
- (void)fetchOlderVideos:(NSUInteger)position;
- (void)dataSourceDidUpdate:(NSNotification*)notification;

@end

@implementation SPVideoReel
@synthesize appDelegate = _appDelegate;
@synthesize toggleOverlayGesuture = _toggleOverlayGesuture;
@synthesize categoryType = _categoryType;
@synthesize videoFrames = _videoFrames;
@synthesize videoPlayers = _videoPlayers;
@synthesize itemViews = _itemViews;
@synthesize videoScrollView = _videoScrollView;
@synthesize overlayView = _overlayView;
@synthesize currentVideoPlayer = _currentVideoPlayer;
@synthesize currentVideo = _currentVideo;
@synthesize numberOfVideos = _numberOfVideos;
@synthesize categoryTitle = _categoryTitle;
@synthesize fetchingOlderVideos = _fetchingOlderVideos;

#pragma mark - Memory Management
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    // All video.extractedURL references are temporary (session-dependent), so they should be removed when the app shuts down.
    CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
    [dataUtility removeAllVideoExtractionURLReferences];
    
}

- (void)didReceiveMemoryWarning
{
    
    DLog(@"MEMORY WARNING - SPVideoReel");

    [super didReceiveMemoryWarning];
}

#pragma mark - Initialization
- (id)initWithCategoryType:(CategoryType)categoryType categoryTitle:(NSString *)title andVideoFrames:(NSArray *)videoFrames
{
    
    if ( self = [super init] ) {
        
        self.categoryType = categoryType;
        self.categoryTitle = title;
        self.videoFrames = [[NSMutableArray alloc] initWithArray:videoFrames];
        
    }
    
    return self;
}

#pragma mark - View Lifecycle Methods
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.frame = CGRectMake(0.0f, 0.0f, 1024.0f, 768.0f);
    self.view.backgroundColor = [UIColor blackColor];
    
    [self setupVariables];
    [self setupObservers];
    [self setupVideoScrollView];
    [self setupOverlayView];
    [self setupVideoPlayers];
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
    self.videoPlayers = [[NSMutableArray alloc] init];
    self.itemViews = [[NSMutableArray alloc] init];
    self.numberOfVideos = [self.videoFrames count];
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
    self.videoScrollView.contentSize = CGSizeMake(1024.0f*_numberOfVideos, 768.0f);
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
    self.overlayView = [nib objectAtIndex:0];
    [_overlayView.categoryTitleLabel setText:self.categoryTitle];
    [self.view addSubview:_overlayView];
    
    self.toggleOverlayGesuture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleOverlay)];
    [self.toggleOverlayGesuture setNumberOfTapsRequired:1];
    [self.view addGestureRecognizer:_toggleOverlayGesuture];
    
    UIPinchGestureRecognizer *pinchOverlayGesuture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(homeButtonAction:)];
    [self.view addGestureRecognizer:pinchOverlayGesuture];
}

- (void)setupVideoPlayers
{
    
    for ( NSUInteger i = 0; i < _numberOfVideos; i++ ) {
        
        Frame *videoFrame = [self.videoFrames objectAtIndex:i];

        CGRect viewframe = self.videoScrollView.frame;
        viewframe.origin.x = viewframe.size.width * i;
        viewframe.origin.y = 0.0f;
        SPVideoPlayer *player = [[SPVideoPlayer alloc] initWithBounds:viewframe
                                                        forVideoFrame:videoFrame
                                                      withOverlayView:_overlayView
                                                          inVideoReel:self];
        
        [self.videoPlayers addObject:player];
        [self.videoScrollView addSubview:player.view];
        [self.videoScrollView setNeedsDisplay];

        
    }

    // If not stream, play video in zeroeth position
    if ( self.categoryType != CategoryType_Stream ) {
        
        self.currentVideo = 0;
        self.currentVideoPlayer = [self.videoPlayers objectAtIndex:_currentVideo];
        [self currentVideoDidChangeToVideo:_currentVideo];
        
        
    } else {
        
        self.currentVideo = 0;
        self.currentVideoPlayer = [self.videoPlayers objectAtIndex:_currentVideo];
        
        for ( NSUInteger i = 0; i < _numberOfVideos; i++ ) {
            
            Frame *videoFrame = [self.videoFrames objectAtIndex:i];
            NSString *storedStreamID = [[NSUserDefaults standardUserDefaults] objectForKey:kSPCurrentVideoStreamID];
            
            if ( [videoFrame.frameID isEqualToString:storedStreamID] ) {
             
                self.currentVideo = i;
                self.currentVideoPlayer = [self.videoPlayers objectAtIndex:_currentVideo];
                
            }
        }
        
        [self currentVideoDidChangeToVideo:_currentVideo];
        
    }
}

- (void)setupVideoListScrollView
{

    CGFloat itemViewWidth = [SPVideoItemView width];
    self.overlayView.videoListScrollView.contentSize = CGSizeMake(itemViewWidth*_numberOfVideos, 217.0f);
    self.overlayView.videoListScrollView.delegate = self;
    
    for ( NSUInteger i = 0; i < _numberOfVideos; i++ ) {
        
        
        CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
        NSManagedObjectContext *context = [dataUtility context];
        Frame *videoFrame = (Frame*)[context existingObjectWithID:[[self.videoFrames objectAtIndex:i] objectID] error:nil];

        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"SPVideoItemView" owner:self options:nil];
        SPVideoItemView *itemView = [nib objectAtIndex:0];
            
        CGRect itemFrame = itemView.frame;
        itemFrame.origin.x = itemViewWidth * i;
        itemFrame.origin.y = 20.0f;
        [itemView setFrame:itemFrame];
        
        [itemView.videoTitleLabel setText:videoFrame.video.title];
        UIImageView *videoListThumbnailPlaceholderView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"videoListThumbnail"]];
        [AsynchronousFreeloader loadImageFromLink:videoFrame.video.thumbnailURL forImageView:itemView.thumbnailImageView withPlaceholderView:videoListThumbnailPlaceholderView];
        [itemView setTag:i];
        
        [self.itemViews addObject:itemView];
        [self.overlayView.videoListScrollView addSubview:itemView];
        [self.overlayView.videoListScrollView setNeedsDisplay];
        
    }

    
    // Add visual selected state (e.g., blue background, white text) to currentVideo
    SPVideoItemView *itemView = [self.itemViews objectAtIndex:_currentVideo];
    itemView.backgroundColor = kColorBlue;
    itemView.videoTitleLabel.textColor = [UIColor whiteColor];

    // Scroll To currentVideo if self.currentVideo != 0
    if ( 0 != _currentVideo) {
        
        CGFloat x = self.videoScrollView.frame.size.width * _currentVideo;
        CGFloat y = self.videoScrollView.contentOffset.y;
        [self.videoScrollView setContentOffset:CGPointMake(x, y) animated:YES];
        
        CGFloat itemViewX = itemView.frame.size.width * (_currentVideo-1);
        CGFloat itemViewY = self.overlayView.videoListScrollView.contentOffset.y;
        [self.overlayView.videoListScrollView setContentOffset:CGPointMake(itemViewX, itemViewY) animated:YES];
        
    }

}

#pragma mark - UI and DataSource Manipulation
- (void)extractVideoForVideoPlayer:(NSUInteger)position;
{
    SPVideoPlayer *player = [self.videoPlayers objectAtIndex:position];
    
    if ( (position >= _numberOfVideos) ) {
        return;
    } else {
       [player queueVideo];
    }

}

- (void)dataSourceDidUpdate:(NSNotification*)notification
{
    
    DLog(@"Received More Data!");
    
    CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
    NSManagedObjectContext *context = [dataUtility context];
    
    
    if ( [[self.videoFrames lastObject] objectID] ) { // Occasionally, this is nil, for reasons I cannot figure out, hence the condition.
        
        Frame *frame = (Frame*)[context existingObjectWithID:[[self.videoFrames lastObject] objectID] error:nil];
        NSDate *date = frame.timestamp;
        
        switch ( _categoryType ) {
                
            case CategoryType_Stream:
                [self.videoFrames addObjectsFromArray:[dataUtility fetchMoreStreamEntriesAfterDate:date]];
                break;
                
            case CategoryType_QueueRoll:
                [self.videoFrames addObjectsFromArray:[dataUtility fetchMoreStreamEntriesAfterDate:date]];
                break;
                
            case CategoryType_PersonalRoll:
                [self.videoFrames addObjectsFromArray:[dataUtility fetchMoreStreamEntriesAfterDate:date]];
                break;
                
            default:
                break;
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            // Update variables
            NSUInteger numberOfVideosBeforeUpdate = _numberOfVideos;
            [self setNumberOfVideos:[self.videoFrames count]];
            
            // Update videoScrollView and videoListScrollView
            for ( NSUInteger i = numberOfVideosBeforeUpdate; i < _numberOfVideos; i++ ) {
                
                // videoScrollView
                CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
                NSManagedObjectContext *context = [dataUtility context];
                Frame *videoFrame = (Frame*)[context existingObjectWithID:[[self.videoFrames objectAtIndex:i] objectID] error:nil];
                
                CGRect viewframe = self.videoScrollView.frame;
                viewframe.origin.x = viewframe.size.width * i;
                viewframe.origin.y = 0.0f;
                SPVideoPlayer *player = [[SPVideoPlayer alloc] initWithBounds:viewframe
                                                                forVideoFrame:videoFrame
                                                              withOverlayView:_overlayView
                                                                  inVideoReel:self];
                
                // videoListScrollView
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"SPVideoItemView" owner:self options:nil];
                SPVideoItemView *itemView = [nib objectAtIndex:0];
                
                CGFloat itemViewWidth = [SPVideoItemView width];
                CGRect itemFrame = itemView.frame;
                itemFrame.origin.x = itemViewWidth * i;
                itemFrame.origin.y = 20.0f;
                [itemView setFrame:itemFrame];
                [itemView setTag:i];
                
                UIImageView *videoListThumbnailPlaceholderView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"videoListThumbnail"]];
                [AsynchronousFreeloader loadImageFromLink:videoFrame.video.thumbnailURL forImageView:itemView.thumbnailImageView withPlaceholderView:videoListThumbnailPlaceholderView];
                
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
                });
                
            }
            
        });
        
    }
    
}

- (void)currentVideoDidChangeToVideo:(NSUInteger)position
{
    
    // Disable timer
    [self.currentVideoPlayer.overlayTimer invalidate];
    
    // Pause current videoPlayer
    if ( self.currentVideoPlayer.isPlayable )
        [self.currentVideoPlayer pause];
    
    // Reset currentVideoPlayer reference after scrolling has finished
    self.currentVideo = position;
    self.currentVideoPlayer = [self.videoPlayers objectAtIndex:position];
    
    // If videoReel is instance of Stream, store currentVideoID
    if ( self.categoryType == CategoryType_Stream ) {
        
        CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
        NSManagedObjectContext *context = [dataUtility context];
        NSManagedObjectID *videoFrameObjectID = [[self.videoFrames objectAtIndex:_currentVideo] objectID];
        Frame *videoFrame = (Frame*)[context existingObjectWithID:videoFrameObjectID error:nil];
     
        [[NSUserDefaults standardUserDefaults] setObject:videoFrame.frameID forKey:kSPCurrentVideoStreamID];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
    }
    
    // Deal with playback of current and previous video
    if ( [self.currentVideoPlayer isPlayable] ) { // If video is loaded and playable
        
        [self.currentVideoPlayer play];
        [self.currentVideoPlayer syncScrubber];
        
        if ( [self.currentVideoPlayer playbackFinished] ) { // If loaded video finished playing
            
            [self.overlayView.restartPlaybackButton setHidden:NO];
            [self.overlayView.playButton setEnabled:NO];
            [self.overlayView.airPlayButton setEnabled:NO];
            [self.overlayView.scrubber setEnabled:NO];
            [self showOverlay];
            
        } else { // If loaded video didn't finish playing
            
            [self.overlayView.restartPlaybackButton setHidden:YES];
            [self.overlayView.playButton setEnabled:YES];
            [self.overlayView.airPlayButton setEnabled:YES];
            [self.overlayView.scrubber setEnabled:YES];
            
        }
        
    } else { // Video is queued but not loaded
        
        [self.overlayView.restartPlaybackButton setHidden:YES];
        [self.overlayView.playButton setEnabled:NO];
        [self.overlayView.airPlayButton setEnabled:NO];
        [self.overlayView.scrubber setEnabled:NO];
        
    }
    
    // Clear old values on infoCard
    [self.overlayView.videoTitleLabel setText:nil];
    [self.overlayView.videoCaptionLabel setText:nil];
    [self.overlayView.nicknameLabel setText:nil];
    [self.overlayView.userImageView setImage:nil];
    
    // Reference NSManageObjectContext
    CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
    NSManagedObjectContext *context = [dataUtility context];
    NSManagedObjectID *videoFrameObjectID = [[self.videoFrames objectAtIndex:_currentVideo] objectID];
    Frame *videoFrame = (Frame*)[context existingObjectWithID:videoFrameObjectID error:nil];
    
    // Set new values on infoPanel
    self.overlayView.videoTitleLabel.text = videoFrame.video.title;
    self.overlayView.videoCaptionLabel.text = videoFrame.video.caption;
    self.overlayView.nicknameLabel.text = [NSString stringWithFormat:@"shared by %@", videoFrame.creator.nickname];
    UIImageView *infoPanelIconPlaceholderView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"infoPanelIconPlaceholder"]];
    [AsynchronousFreeloader loadImageFromLink:videoFrame.creator.userImage
                                 forImageView:self.overlayView.userImageView
                          withPlaceholderView:infoPanelIconPlaceholderView];
    
    
    // Add downloadButton if user is admin
    User *user = [dataUtility fetchUser];
    if ( YES == [user.admin boolValue] ) {
        [self.currentVideoPlayer setupDownloadButton];
    }
    
    // Update videoListScrollView (if _itemViews is initialized)
    if ( 0 < [self.itemViews count] ) {
        
        // Remove selected state color from all SPVideoItemView objects
        for (SPVideoItemView *itemView in self.itemViews) {
            itemView.backgroundColor = [UIColor clearColor];
            itemView.videoTitleLabel.textColor = kColorBlack;
        }
        
        // Reference SPVideoItemView from position in videoListScrollView object
        SPVideoItemView *itemView = [self.itemViews objectAtIndex:position];
        
        // Change itemView Color to show selected state
        itemView.backgroundColor = kColorBlue;
        itemView.videoTitleLabel.textColor = kColorWhite;
        
        // Force scrollView and video changes
        if ( position < self.numberOfVideos ) {
            
            // Force scroll videoScrollView
            CGFloat itemX = itemView.frame.size.width * position;
            CGFloat itemY = 0.0f;
            
            [self.overlayView.videoListScrollView setContentOffset:CGPointMake(itemX, itemY) animated:YES];
        }
        
    }
    
    if ( self.categoryType == CategoryType_Cached ) {
        
        [self.currentVideoPlayer performSelectorOnMainThread:@selector(loadFromCache) withObject:nil waitUntilDone:YES];
        
    } else {
        
        // Load current and next 3 videos
        if ( 0 < [self.videoPlayers count] ) {
            [[SPVideoExtractor sharedInstance] emptyQueue];
            [self extractVideoForVideoPlayer:position]; // Load video for current visible view
            if ( position + 1 < self.numberOfVideos ) [self extractVideoForVideoPlayer:position+1];
            if ( position + 2 < self.numberOfVideos ) [self extractVideoForVideoPlayer:position+2];
            if ( position + 3 < self.numberOfVideos ) [self extractVideoForVideoPlayer:position+3];
        }
        
    }
    
}

- (void)fetchOlderVideos:(NSUInteger)position
{
    if ( position >= self.numberOfVideos - 7 && ![self fetchingOlderVideos] ) {
        
        self.fetchingOlderVideos = YES;
        
        CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
        
        switch ( _categoryType ) {
                
            case CategoryType_Unknown:{
                
            } break;
                
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
                
            default:
                break;
        }
    }
}

- (void)toggleOverlay
{
    if ( self.overlayView.alpha < 1.0f ) {
        
        [self showOverlay];
        
    } else {
        
        [self hideOverlay];
    }
}

- (void)showOverlay
{
    [UIView animateWithDuration:0.5f animations:^{
        [self.overlayView setAlpha:1.0f];
    }];
}

- (void)hideOverlay
{
    [UIView animateWithDuration:0.5f animations:^{
        [self.overlayView setAlpha:0.0f];
    }];
}

#pragma mark - Action Methods
- (IBAction)homeButtonAction:(id)sender
{
    
    CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
    User *user = [dataUtility fetchUser];
    
    if ( YES == [user.admin boolValue] ) {
        
        for ( SPVideoPlayer *player in _videoPlayers ) {
            
            // Check if videos are being downloaded
            if ( YES == player.isDownloading ) {
                
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                    message:@"You are downloading at least one video, so it wouldn't be wise to dismiss this instance of SPVideoReel."
                                                                   delegate:self
                                                          cancelButtonTitle:@"Dismiss"
                                                          otherButtonTitles:nil, nil];
                
                [alertView show];
                
                return;
                
            } else {
                
                // Pause and stop residual video playback
                [player pause];
                
            }
            
        }
        
    } else {
        
        for ( SPVideoPlayer *player in _videoPlayers ) {
            
            // Pause and stop residual video playback
            [player pause];
        
        }
        
    }
    

    [[SPVideoExtractor sharedInstance] cancelRemainingExtractions];
    [self.videoPlayers removeAllObjects];
    [self.videoFrames removeAllObjects];
    [self setNumberOfVideos:0];
    
    MeViewController *meViewController = (MeViewController*)self.presentingViewController;
    [meViewController dismissVideoReel:self];

}

- (IBAction)playButtonAction:(id)sender
{
    [self.currentVideoPlayer togglePlayback];
}

- (IBAction)airplayButtonAction:(id)sender
{
    [self.currentVideoPlayer airPlay];
}

- (IBAction)shareButtonAction:(id)sender
{
    [self.currentVideoPlayer share];
}

- (IBAction)itemButtonAction:(id)sender
{

    // Pause currentVideo Player
    [self.currentVideoPlayer pause];

    // Reference SPVideoItemView from position in videoListScrollView object
    SPVideoItemView *itemView = (SPVideoItemView*)[sender superview];
    NSUInteger position = itemView.tag;
    
    // Force scroll videoScrollView
    CGFloat videoX = 1024 * position;
    CGFloat videoY = self.videoScrollView.contentOffset.y;
    
    if ( position < self.numberOfVideos ) {
        [self.videoScrollView setContentOffset:CGPointMake(videoX, videoY) animated:YES];
    }
    
    // Perform actions on videoChange
    [self currentVideoDidChangeToVideo:position];

}

- (void)restartPlaybackButtonAction:(id)sender
{
    [self.currentVideoPlayer restartPlayback];
}

- (IBAction)beginScrubbing:(id)sender
{
	_scrubberTimeObserver = nil;
}

- (IBAction)scrub:(id)sender
{
    CMTime playerDuration = [self.currentVideoPlayer elapsedDuration];
    if (CMTIME_IS_INVALID(playerDuration)) {
        return;
    }
    
    double duration = CMTimeGetSeconds(playerDuration);
    if (isfinite(duration)) {
        
        float minValue = [self.overlayView.scrubber minimumValue];
        float maxValue = [self.overlayView.scrubber maximumValue];
        float value = [self.overlayView.scrubber value];
        double time = duration * (value - minValue) / (maxValue - minValue);
        [self.currentVideoPlayer.player seekToTime:CMTimeMakeWithSeconds(time, NSEC_PER_SEC)];
    }
}

- (IBAction)endScrubbing:(id)sender
{
    
	if ( !_scrubberTimeObserver ) {
		
        CMTime playerDuration = [self.currentVideoPlayer elapsedDuration];
		if (CMTIME_IS_INVALID(playerDuration)) {
			return;
		}
		
		double duration = CMTimeGetSeconds(playerDuration);
        
		if (isfinite(duration)) {
			CGFloat width = CGRectGetWidth([self.overlayView.scrubber bounds]);
			double tolerance = 0.5f * duration / width;
            __block SPVideoReel *blockSelf = self;
			_scrubberTimeObserver = [self.currentVideoPlayer.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(tolerance, NSEC_PER_SEC)
                                                                                                  queue:NULL
                                                                                             usingBlock:^(CMTime time) {
                            
                            // Sync the scrubber to the currentVideoPlayer
                            [blockSelf.currentVideoPlayer syncScrubber];
                            
                            // If video was playing before scrubbing began, make sure it continues to play, otherwise, pause the video
                            ( self.currentVideoPlayer.isPlaying ) ? [self.currentVideoPlayer play] : [self.currentVideoPlayer pause];
                                                                                                 
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
        NSInteger page = (NSInteger)floor(scrollAmount) + 1;
        
        // Toggle playback on old and new SPVideoPlayer objects
        if ( page != self.currentVideo ) {
            
            SPVideoPlayer *oldPlayer = [self.videoPlayers objectAtIndex:_currentVideo];
            [oldPlayer pause];
            
        }
        
        [self currentVideoDidChangeToVideo:page];
        [self fetchOlderVideos:page];
    
    } else if ( scrollView == self.overlayView.videoListScrollView ) {
        
        // Switch the indicator when more than 50% of the previous/next page is visible
        CGFloat pageWidth = scrollView.frame.size.width;
        CGFloat scrollAmount = 2.85*(scrollView.contentOffset.x - pageWidth / 2) / pageWidth; // Multiply by ~3 since each visible section has ~3 videos.
        NSUInteger page = (NSUInteger)floor(scrollAmount) + 1;
        [self fetchOlderVideos:page];
        
    }
}

@end