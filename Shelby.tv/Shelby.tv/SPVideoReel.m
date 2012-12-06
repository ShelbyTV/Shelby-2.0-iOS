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

@interface SPVideoReel ()

@property (strong, nonatomic) AppDelegate *appDelegate;
@property (strong, nonatomic) NSMutableArray *videoFrames;
@property (strong, nonatomic) NSMutableArray *videoPlayers;
@property (strong, nonatomic) SPOverlayView *overlayView;
@property (strong, nonatomic) SPVideoPlayer *currentVideoPlayer;
@property (assign, nonatomic) NSUInteger currentVideo;
@property (copy, nonatomic) NSString *categoryTitle;

- (void)setupVariables;
- (void)setupVideoScrollView;
- (void)setupOverlayView;
- (void)setupVideoPlayers;
- (void)toggleOverlay;

@end

@implementation SPVideoReel
@synthesize appDelegate = _appDelegate;
@synthesize videoFrames = _videoFrames;
@synthesize videoPlayers = _videoPlayers;
@synthesize videoScrollView = _videoScrollView;
@synthesize overlayView = _overlayView;
@synthesize currentVideoPlayer = _currentVideoPlayer;
@synthesize currentVideo = _currentVideo;
@synthesize numberOfVideos = _numberOfVideos;
@synthesize categoryTitle = _categoryTitle;
@synthesize scrubberTimeObserver = _scrubberTimeObserver;

#pragma mark - Initialization
- (id)initWithVideoFrames:(NSArray *)videoFrames andCategoryTitle:(NSString *)title
{
    self = [super init];
    
    if ( self ) {
        
        self.videoFrames = [[NSMutableArray alloc] initWithArray:videoFrames];
        self.categoryTitle = title;
        
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
    [self setupVideoScrollView];
    [self setupOverlayView];
    [self setupVideoPlayers];
    
}

#pragma mark - Setup Methods
- (void)setupVariables
{
    self.appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    self.videoPlayers = [[NSMutableArray alloc] init];
    self.numberOfVideos = [self.videoFrames count];
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

#pragma mark - Misc. Methods
- (void)extractVideoForVideoPlayer:(NSUInteger)videoPlayerNumber;
{
    SPVideoPlayer *player = [self.videoPlayers objectAtIndex:videoPlayerNumber];
    
    if ( (videoPlayerNumber > _numberOfVideos) || [player videoQueued] ) {
        return;
    } else {
       [player queueVideo];
    }
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

- (void)currentVideoDidChangeToVideo:(NSUInteger)videoPosition
{
    
    // Reset currentVideoPlayer reference after scrolling has finished
    self.currentVideo = videoPosition;
    self.currentVideoPlayer = [self.videoPlayers objectAtIndex:videoPosition];
    
    if ( self.currentVideoPlayer.playbackFinished ) {
        [self.overlayView.restartPlaybackButton setHidden:NO];
    } else {
        [self.overlayView.restartPlaybackButton setHidden:YES];
    }
    
    // Clear old values
    [self.overlayView.videoTitleLabel setText:nil];
    [self.overlayView.captionLabel setText:nil];
    [self.overlayView.nicknameLabel setText:nil];
    [self.overlayView.userImageView setImage:nil];
    
    // Reference NSManageObjectContext
    CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_None];
    NSManagedObjectContext *context = [dataUtility context];
    Frame *frame = (Frame*)[context existingObjectWithID:[[self.videoFrames objectAtIndex:_currentVideo] objectID] error:nil];
    
    // Set new values
    self.overlayView.videoTitleLabel.text = frame.video.title;
    self.overlayView.captionLabel.text = frame.video.caption;
    self.overlayView.nicknameLabel.text = [NSString stringWithFormat:@"shared by %@", frame.creator.nickname];
    [AsynchronousFreeloader loadImageFromLink:frame.creator.userImage forImageView:self.overlayView.userImageView withPlaceholderView:nil];
    
    // Sync Scrubber
    [self.currentVideoPlayer syncScrubber];
    
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
        int page = floor(scrollAmount) + 1;
        
        // Toggle playback on old and new SPVideoPlayer objects
        if ( page != self.currentVideo ) {
            
            SPVideoPlayer *oldPlayer = [self.videoPlayers objectAtIndex:_currentVideo];
            [oldPlayer pause];
            
            SPVideoPlayer *newPlayer = [self.videoPlayers objectAtIndex:page];
            [newPlayer play];
            
        }
        
        [self currentVideoDidChangeToVideo:page];
        
        // Load videos
        [self extractVideoForVideoPlayer:page]; // Load video for current visible view
        if ( page+1 < _numberOfVideos-1 ) [self extractVideoForVideoPlayer:page+1]; // Load video positioned after current visible view
        if ( page > 0 ) [self extractVideoForVideoPlayer:page-1]; // Load video positioned beforecurrent visible view
    }
}

@end