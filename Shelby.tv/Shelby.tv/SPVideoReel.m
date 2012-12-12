//
//  SPVideoReel.m
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 11/1/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

#import "SPVideoReel.h"
#import "SPVideoPlayer.h"
#import "SPOverlayView.h"
#import "SPVideoExtractor.h"
#import "SPVideoItemView.h"

@interface SPVideoReel ()

@property (strong, nonatomic) AppDelegate *appDelegate;
@property (assign, nonatomic) CategoryType categoryType;
@property (strong, nonatomic) NSMutableArray *videoFrames;
@property (strong, nonatomic) NSMutableArray *videoPlayers;
@property (strong, nonatomic) NSMutableArray *itemViews;
@property (strong, nonatomic) SPOverlayView *overlayView;
@property (strong, nonatomic) SPVideoPlayer *currentVideoPlayer;
@property (assign, nonatomic) NSUInteger currentVideo;
@property (copy, nonatomic) NSString *categoryTitle;

/// Setup Methods
- (void)setupVariables;
- (void)setupObservers;
- (void)setupVideoScrollView;
- (void)setupVideoListScrollView;
- (void)setupOverlayView;
- (void)setupVideoPlayers;

- (void)dataSourceDidUpdate:(NSNotification*)notification;
- (void)toggleOverlay;

@end

@implementation SPVideoReel
@synthesize appDelegate = _appDelegate;
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
@synthesize scrubberTimeObserver = _scrubberTimeObserver;

#pragma mark - Memory Management
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Initialization
- (id)initWithCategoryType:(CategoryType)categoryType categoryTitle:(NSString *)title andVideoFrames:(NSArray *)videoFrames
{
    self = [super init];
    
    if ( self ) {
        
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
                                             selector:@selector(videoDataSourceDidUpdate:)
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
    
    UITapGestureRecognizer *toggleOverlayGesuture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleOverlay)];
    [toggleOverlayGesuture setNumberOfTapsRequired:1];
    [self.view addGestureRecognizer:toggleOverlayGesuture];
    
    UIPinchGestureRecognizer *pinchOverlayGesuture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(homeButtonAction:)];
    [self.view addGestureRecognizer:pinchOverlayGesuture];
}

- (void)setupVideoPlayers
{
    for ( NSUInteger i = 0; i < _numberOfVideos; i++ ) {
        
        Frame *videoFrame = [self.videoFrames objectAtIndex:i];
        
        BOOL autoPlay;
        if ( 0 == i ) {
            autoPlay = YES;
            self.currentVideo = i;
        } else {
            autoPlay = NO;
        }
        
        CGRect viewframe = self.videoScrollView.frame;
        viewframe.origin.x = viewframe.size.width * i;
        viewframe.origin.y = 0.0f;
        SPVideoPlayer *player = [[SPVideoPlayer alloc] initWithBounds:viewframe
                                                        forVideoFrame:videoFrame
                                                      withOverlayView:_overlayView
                                                          inVideoReel:self
                                                    andShouldAutoPlay:autoPlay];
        
        [self.videoPlayers addObject:player];
        [self.videoScrollView addSubview:player.view];
        
        // Extracting video for the first two SPVideoPlayer objects
        if ( 0 == i ) {
            
            // Set first video to currentVideo
            [self extractVideoForVideoPlayer:0];
            self.currentVideoPlayer = [self.videoPlayers objectAtIndex:0];
            [self currentVideoDidChangeToVideo:0];
            
        } else if ( 1 == i ) {
            
            [self extractVideoForVideoPlayer:1];
            
        }
    }
    
}

- (void)setupVideoListScrollView
{

    self.overlayView.videoListScrollView.delegate = self;
    self.overlayView.videoListScrollView.contentSize = CGSizeMake(220.0f*_numberOfVideos, 197.0f);
    
    for ( NSUInteger i = 0; i < _numberOfVideos; i++ ) {
        
        CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
        NSManagedObjectContext *context = [dataUtility context];
        Frame *videoFrame = (Frame*)[context existingObjectWithID:[[self.videoFrames objectAtIndex:i] objectID] error:nil];
        
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"SPVideoItemView" owner:self options:nil];
        SPVideoItemView *itemView = [nib objectAtIndex:0];
            
        CGRect itemFrame = itemView.frame;
        itemFrame.origin.x = 220.0f * i;
        itemFrame.origin.y = 0.0f;
        [itemView setFrame:itemFrame];
        
        [itemView.videoTitleLabel setText:videoFrame.video.title];
        [AsynchronousFreeloader loadImageFromLink:videoFrame.video.thumbnailURL forImageView:itemView.thumbnailImageView withPlaceholderView:nil];
        [itemView setTag:i];
        
        if ( 0 == i ) {
            itemView.backgroundColor = kColorBlue;
            itemView.videoTitleLabel.textColor = [UIColor whiteColor];
        }
        
        [self.itemViews addObject:itemView];

        
        [self.overlayView.videoListScrollView addSubview:itemView];
    }
    
}

#pragma mark - DataSource Manipulation
- (void)extractVideoForVideoPlayer:(NSUInteger)position;
{
    SPVideoPlayer *player = [self.videoPlayers objectAtIndex:position];
    
    if ( (position >= _numberOfVideos) || [player videoQueued] ) {
        return;
    } else {
       [player queueVideo];
    }

}

- (void)dataSourceDidUpdate:(NSNotification*)notification
{
    DLog(@"Received More Datas!");
    
    //    CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
    
}

#pragma mark - UI Manipulation
- (void)currentVideoDidChangeToVideo:(NSUInteger)position
{
    // Pause current videoPlayer
    [self.currentVideoPlayer pause];
    
    // Reset currentVideoPlayer reference after scrolling has finished
    self.currentVideo = position;
    self.currentVideoPlayer = [self.videoPlayers objectAtIndex:position];
    
    // Pause and stop residual video playback
    if ( self.currentVideoPlayer.playbackFinished ) {
        [self.overlayView.restartPlaybackButton setHidden:NO];
        [self.overlayView.playButton setEnabled:NO];
        [self.overlayView.airPlayButton setEnabled:NO];
        [self.overlayView.scrubber setEnabled:NO];
    } else {
        [self.overlayView.restartPlaybackButton setHidden:YES];
        [self.overlayView.playButton setEnabled:YES];
        [self.overlayView.airPlayButton setEnabled:YES];
        [self.overlayView.scrubber setEnabled:YES];
    }
    
    // Clear old values on infoCard
    [self.overlayView.videoTitleLabel setText:nil];
    [self.overlayView.captionLabel setText:nil];
    [self.overlayView.nicknameLabel setText:nil];
    [self.overlayView.userImageView setImage:nil];
    
    // Reference NSManageObjectContext
    CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
    NSManagedObjectContext *context = [dataUtility context];
    NSManagedObjectID *videoFrameObjectID = [[self.videoFrames objectAtIndex:_currentVideo] objectID];
    Frame *videoFrame = (Frame*)[context existingObjectWithID:videoFrameObjectID error:nil];

    // Set new values on infoCard
    self.overlayView.videoTitleLabel.text = videoFrame.video.title;
    self.overlayView.captionLabel.text = videoFrame.video.caption;
    self.overlayView.nicknameLabel.text = [NSString stringWithFormat:@"shared by %@", videoFrame.creator.nickname];
    [AsynchronousFreeloader loadImageFromLink:videoFrame.creator.userImage forImageView:self.overlayView.userImageView withPlaceholderView:nil];

    // Update videoListScrollView (if _itemViews is initialized)
    if ( 0 < [self.itemViews count] ) {
        
        // Remove selected state color from all SPVideoItemView objects
        for (SPVideoItemView *itemView in self.itemViews) {
            itemView.backgroundColor = [UIColor clearColor];
            itemView.videoTitleLabel.textColor = [UIColor blackColor];
        }
        
        // Reference SPVideoItemView from position in videoListScrollView object
        SPVideoItemView *itemView = [self.itemViews objectAtIndex:position];
        
        // Change itemView Color to show selected state
        itemView.backgroundColor = kColorBlue;
        itemView.videoTitleLabel.textColor = [UIColor whiteColor];
        
        // Force scrollView and video changes
        if ( position <= self.numberOfVideos-1 ) {
            
            // Force scroll videoScrollView
            CGFloat itemX = itemView.frame.size.width * position;
            CGFloat itemY = 0.0f;
            
            [self.overlayView.videoListScrollView setContentOffset:CGPointMake(itemX, itemY) animated:YES];
        }
        
        // Load current and next 4 videos
        [[SPVideoExtractor sharedInstance] emptyQueue];
        [self extractVideoForVideoPlayer:position]; // Load video for current visible view
        if ( position + 1 <= self.numberOfVideos-1 ) [self extractVideoForVideoPlayer:position+1];
        if ( position + 2 <= self.numberOfVideos-1 ) [self extractVideoForVideoPlayer:position+2];
        if ( position + 3 <= self.numberOfVideos-1 ) [self extractVideoForVideoPlayer:position+3];
        
    }
    
    // Sync Scrubber
    [self.currentVideoPlayer syncScrubber];
}

- (void)toggleOverlay
{
    if ( self.overlayView.alpha < 1.0f ) {
        
        [UIView animateWithDuration:0.5f animations:^{
            [self.overlayView setAlpha:1.0f];
        }];
        
    } else {
        
        [UIView animateWithDuration:0.5f animations:^{
            [self.overlayView setAlpha:0.0f];
        }];
        
    }
}

#pragma mark - Action Methods
- (IBAction)homeButtonAction:(id)sender
{
    
    // Pause and stop residual video playback
    for ( SPVideoPlayer *player in _videoPlayers ) {
        
        [player pause];
        
    }
    
    [[SPVideoExtractor sharedInstance] cancelRemainingExtractions];
    [self.videoPlayers removeAllObjects];
    [self.videoFrames removeAllObjects];
    [self setNumberOfVideos:0];
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
    DLog(@"%@ Reel Dismissed", _categoryTitle);
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
    
    if ( position <= self.numberOfVideos-1 ) {
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

/* The user has released the movie thumb control to stop scrubbing through the movie. */
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
                                                                                             usingBlock: ^(CMTime time) {
                                  [blockSelf.currentVideoPlayer syncScrubber];
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
            
            SPVideoPlayer *newPlayer = [self.videoPlayers objectAtIndex:page];
            [newPlayer play];
            
        }
        
        [self currentVideoDidChangeToVideo:page];
    
    } else if ( scrollView == self.overlayView.videoListScrollView ) {
        
        // Switch the indicator when more than 50% of the previous/next page is visible
        CGFloat pageWidth = scrollView.frame.size.width;
        CGFloat scrollAmount = 2.85*(scrollView.contentOffset.x - pageWidth / 2) / pageWidth; // Multiply by ~3 since each visible section has ~3 videos.
        NSUInteger page = (NSUInteger)floor(scrollAmount) + 1;
        
        if ( page >= self.numberOfVideos - 6 ) {
            
            switch ( _categoryType ) {
                    
                case CategoryType_Unknown:{
                    
                } break;
                
                case CategoryType_Stream:{
                    
                    NSString *numberToString = [NSString stringWithFormat:@"%d", _numberOfVideos];
                    [ShelbyAPIClient getMoreFramesInStream:numberToString];
                
                } break;
                
                case CategoryType_QueueRoll:{
                
                    NSString *numberToString = [NSString stringWithFormat:@"%d", _numberOfVideos];
                    [ShelbyAPIClient getMoreFramesInQueueRoll:numberToString];
                    
                } break;
                
                case CategoryType_PersonalRoll:{
                
                    NSString *numberToString = [NSString stringWithFormat:@"%d", _numberOfVideos];
                    [ShelbyAPIClient getMoreFramesInPersonalRoll:numberToString];
                    
                } break;
                    
                default:
                    break;
            }
            
        }
        
    }
}

@end