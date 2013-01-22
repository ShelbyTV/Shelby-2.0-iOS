//
//  SPVideoPlayer.m
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 11/1/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

#import "SPVideoPlayer.h"
#import "SPVideoExtractor.h"
#import "SPOverlayView.h"
#import "SPVideoReel.h"

@interface SPVideoPlayer ()

@property (strong, nonatomic) AppDelegate *appDelegate;
@property (strong, nonatomic) AVPlayerLayer *playerLayer;
@property (strong, nonatomic) UIActivityIndicatorView *indicator;
@property (strong, nonatomic) SPOverlayView *overlayView;
@property (strong, nonatomic) SPVideoReel *videoReel;
@property (strong, nonatomic) UIPopoverController *sharePopOverController;

// Setup Methods
- (void)setupIndicator;
- (void)setupInitialConditions;
- (void)resheduleOverlayTimer;

// Notifications
- (void)loadVideo:(NSNotification*)notification;
- (void)itemDidFinishPlaying:(NSNotification*)notification;

// Convert CMTime to NSString
- (NSString*)convertElapsedTime:(double)currentTime andDuration:(double)duration;

@end

@implementation SPVideoPlayer
@synthesize appDelegate = _appDelegate;
@synthesize videoFrame = _videoFrame;
@synthesize player = _player;
@synthesize playerLayer = _playerLayer;
@synthesize indicator = _indicator;
@synthesize overlayView = _overlayView;
@synthesize videoReel = _videoReel;
@synthesize sharePopOverController = _sharePopOverController;
@synthesize playbackFinished = _playbackFinished;
@synthesize isPlayable = _isPlayable;
@synthesize isPlaying = _isPlaying;
@synthesize isDownloading = _isDownloading;
@synthesize overlayTimer = _overlayTimer;

#pragma mark - Memory Management Methods
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kSPVideoExtracted object:nil];
}

- (void)didReceiveMemoryWarning
{
    
    NSManagedObjectContext *context = [self.appDelegate context];
    NSManagedObjectID *objectID = [self.videoFrame objectID];
    self.videoFrame = (Frame*)[context existingObjectWithID:objectID error:nil];
    DLog(@"MEMORY WARNING %@", _videoFrame.video.title);
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kSPVideoExtracted object:nil];
    [self.playerLayer removeFromSuperlayer];
    [self.player pause];
    [self setPlayer:nil];
    
    [super didReceiveMemoryWarning];
}


#pragma mark - Initialization Methods
- (id)initWithBounds:(CGRect)bounds
       forVideoFrame:(Frame *)videoFrame
     withOverlayView:(SPOverlayView *)overlayView
         inVideoReel:(id)videoReel
{
    if ( self = [super init] ) {
        
        [self.view setFrame:bounds];
        [self setVideoFrame:videoFrame];
        [self setOverlayView:overlayView];
        [self setVideoReel:videoReel];
        [self setupInitialConditions];
        [self setAppDelegate:(AppDelegate*)[[UIApplication sharedApplication] delegate]];
        
    }
    
    return self;
}


#pragma mark - View Lifecycle Methods
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self setupIndicator];
}

#pragma mark - Setup Methods
- (void)setupInitialConditions
{
    [self setPlaybackFinished:NO];
    [self setIsPlayable:NO];
    [self setIsPlaying:NO];
    [self setIsDownloading:NO];
}

- (void)setupIndicator
{
        
    CGRect modifiedFrame = CGRectMake(0.0f, 0.0f,self.view.frame.size.width, self.view.frame.size.height);
    self.indicator = [[UIActivityIndicatorView alloc] initWithFrame:modifiedFrame];
    self.indicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
    self.indicator.hidesWhenStopped = YES;
    [self.indicator startAnimating];
    [self.view addSubview:self.indicator];
    
}

- (void)resheduleOverlayTimer
{
    
    if ( [self.overlayTimer isValid] )
        [self.overlayTimer invalidate];
    
    self.overlayTimer = [NSTimer scheduledTimerWithTimeInterval:5.0f target:self.videoReel selector:@selector(hideOverlay) userInfo:nil repeats:NO];

}

#pragma mark - Video Fetching Methods
- (void)queueVideo
{
    
    if ( ![self isPlayable] ) {
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(loadVideo:)
                                                     name:kSPVideoExtracted
                                                   object:nil];
        
        NSManagedObjectContext *context = [self.appDelegate context];
        NSManagedObjectID *objectID = [self.videoFrame objectID];
        self.videoFrame = (Frame*)[context existingObjectWithID:objectID error:nil];
        [[SPVideoExtractor sharedInstance] queueVideo:_videoFrame.video];
        
    }
}

#pragma mark - Video Playback Methods
- (void)togglePlayback
{
    if ( 0.0 == self.player.rate && _isPlayable ) { // Play
        
        [self play];
        
    } else { // Pause
            
        [self pause];
    }
}

- (void)restartPlayback
{
    [self setPlaybackFinished:NO];
    [self.overlayView.restartPlaybackButton setHidden:YES];
    
    [self.overlayView.playButton setEnabled:YES];
    [self.overlayView.airPlayButton setEnabled:YES];
    [self.overlayView.scrubber setEnabled:YES];
    
    [self.player seekToTime:CMTimeMakeWithSeconds(0.0f, NSEC_PER_SEC)];
    [self syncScrubber];
    [self.player play];
}

- (void)play
{
    // Play video and update UI
    [self.player play];
    [self.overlayView.playButton setTitle:@"Pause" forState:UIControlStateNormal];
    [self.overlayView.playButton setImage:[UIImage imageNamed:@"pauseButton"] forState:UIControlStateNormal];
    
    // Reschedule Timer
    [self resheduleOverlayTimer];
    
    // Set Flag
    [self setIsPlaying:YES];
}

- (void)pause
{
    // Pause video and update UI
    [self.player pause];
    [self.overlayView.playButton setTitle:@"Play" forState:UIControlStateNormal];
    [self.overlayView.playButton setImage:[UIImage imageNamed:@"playButton"] forState:UIControlStateNormal];

    // Invalide Timer
    [self.overlayTimer invalidate];
    
    // Set Flag
    [self setIsPlaying:NO];
}

- (void)airPlay
{
    
}

- (void)share
{

    NSManagedObjectContext *context = [self.appDelegate context];
    NSManagedObjectID *objectID = [self.videoFrame objectID];
    self.videoFrame = (Frame*)[context existingObjectWithID:objectID error:nil];
    
    NSString *shareLink = [NSString stringWithFormat:kSPVideoShareLink, _videoFrame.rollID, _videoFrame.frameID];
    NSString *shareMessage = [NSString stringWithFormat:@"Watch \"%@\" %@ /via @Shelby", _videoFrame.video.title, shareLink];
    UIActivityViewController *shareController = [[UIActivityViewController alloc] initWithActivityItems:@[shareMessage] applicationActivities:nil];
    self.sharePopOverController = [[UIPopoverController alloc] initWithContentViewController:shareController];
    [self.sharePopOverController presentPopoverFromRect:self.overlayView.shareButton.frame
                                                 inView:self.overlayView
                               permittedArrowDirections:UIPopoverArrowDirectionDown
                                               animated:YES];
}

#pragma mark - Video Scrubber Methods
- (CMTime)elapsedDuration
{
    AVPlayerItem *playerItem = [self.player currentItem];
	
    if (playerItem.status == AVPlayerItemStatusReadyToPlay) {
        
		return [playerItem duration] ;
	}
	
	return kCMTimeInvalid;
}

- (void)setupScrubber
{
	
    double interval = .1f;
	CMTime playerDuration = [self elapsedDuration];
    
	if (CMTIME_IS_INVALID(playerDuration)) {
        [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(setupScrubber) userInfo:nil repeats:NO];

        return;
	}
	
    double duration = CMTimeGetSeconds(playerDuration);
	if (isfinite(duration)) {
		CGFloat width = CGRectGetWidth([self.overlayView.scrubber bounds]);
		interval = 0.5f * duration / width;
	}
    
    __block SPVideoPlayer *blockSelf = self;
	self.videoReel.scrubberTimeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(interval, NSEC_PER_SEC)
                                                                      queue:NULL /* If you pass NULL, the main queue is used. */
                                                                 usingBlock:^(CMTime time) {
                                                                     
                                                                     [blockSelf syncScrubber];
                                                                     
                                                                 }];
}

- (void)syncScrubber
{
	CMTime playerDuration = [self elapsedDuration];
	if ( CMTIME_IS_INVALID(playerDuration) ) {

		return;
	}
    
	double duration = CMTimeGetSeconds(playerDuration);
    
	if ( isfinite(duration) ) {
        
		float minValue = [self.overlayView.scrubber minimumValue];
		float maxValue = [self.overlayView.scrubber maximumValue];
		double currentTime = CMTimeGetSeconds([self.videoReel.currentVideoPlayer.player currentTime]);
		double duration = CMTimeGetSeconds([self.videoReel.currentVideoPlayer.player.currentItem duration]);
        
		[self.overlayView.scrubber setValue:(maxValue - minValue) * currentTime / duration + minValue];
        [self.overlayView.scrubberTimeLabel setText:[self convertElapsedTime:currentTime andDuration:duration]];
        
	}
}

- (NSString *)convertElapsedTime:(double)currentTime andDuration:(double)duration
{
    
    NSString *convertedTime = nil;
    NSInteger currentTimeSeconds = 0;
    NSInteger currentTimeHours = 0;
    NSInteger currentTimeMinutes = 0;
    NSInteger durationSeconds = 0;
    NSInteger durationMinutes = 0;
    NSInteger durationHours = 0;
    
    // Current Time        
    currentTimeSeconds = ((NSInteger)currentTime % 60);
    currentTimeMinutes = (((NSInteger)currentTime / 60) % 60);
    currentTimeHours = ((NSInteger)currentTime / 3600);

    // Duration
    durationSeconds = ((NSInteger)duration % 60);
    durationMinutes = (((NSInteger)duration / 60) % 60);
    durationHours = ((NSInteger)duration / 3600);

    if ( durationHours > 0 ) {
        
        convertedTime = [NSString stringWithFormat:@"%.2d:%.2d:%.2d / %.2d:%.2d:%.2d", currentTimeHours, currentTimeMinutes, currentTimeSeconds, durationHours, durationMinutes, durationSeconds];
        
    } else if ( durationMinutes > 0 ) {
        
        convertedTime = [NSString stringWithFormat:@"%.2d:%.2d / %.2d:%.2d", currentTimeMinutes, currentTimeSeconds, durationMinutes, durationSeconds];
        
    } else {
        
        convertedTime = [NSString stringWithFormat:@"0:%.2d / 0:%.2d", currentTimeSeconds, durationSeconds];
    }
    
    return convertedTime;
}

- (void)loadVideo:(NSNotification*)notification
{

    NSManagedObjectContext *context = [self.appDelegate context];
    NSManagedObjectID *objectID = [self.videoFrame objectID];
    self.videoFrame = (Frame*)[context existingObjectWithID:objectID error:nil];
    
    Video *video = [notification.userInfo valueForKey:kSPCurrentVideo];
    
    if ( [self.videoFrame.video.providerID isEqualToString:video.providerID] ) {
        
        // Clear notification and indicator
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        [self.indicator stopAnimating];
        
        // Instantiate AVPlayer object with extractedURL
        AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithURL:[NSURL URLWithString:_videoFrame.video.extractedURL]];
        self.player = [[AVPlayer alloc] initWithPlayerItem:playerItem];
        
        // Redraw AVPlayer object for placement in UIScrollView on SPVideoReel
        self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
        CGRect modifiedFrame = CGRectMake(0.0f, 0.0f,self.view.frame.size.width, self.view.frame.size.height);
        self.playerLayer.frame = modifiedFrame;
        self.playerLayer.bounds = modifiedFrame;
        [self.view.layer addSublayer:self.playerLayer];
        
        // Make sure video can be played via AirPlay
        self.player.allowsExternalPlayback = YES;
        
        // Set isPlayable Flag
        [self setIsPlayable:YES];
        [self setupScrubber];
        
        if ( self == self.videoReel.currentVideoPlayer ) {
         
            [self.overlayView.restartPlaybackButton setHidden:YES];
            [self.overlayView.playButton setEnabled:YES];
            [self.overlayView.airPlayButton setEnabled:YES];
            [self.overlayView.scrubber setEnabled:YES];
            
        }
        
        // Add Gesture Recognizer
        UITapGestureRecognizer *togglePlaybackGesuture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(togglePlayback)];
        [togglePlaybackGesuture setNumberOfTapsRequired:2];
        [self.view addGestureRecognizer:togglePlaybackGesuture];
        
        [self.videoReel.toggleOverlayGesuture requireGestureRecognizerToFail:togglePlaybackGesuture];
        
        // Add Observers
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(itemDidFinishPlaying:)
                                                     name:AVPlayerItemDidPlayToEndTimeNotification
                                                   object:playerItem];
        
        // Toggle video playback
        if ( self == _videoReel.currentVideoPlayer ) {
            
            [self play];
            [self resheduleOverlayTimer];
            
        } else {
            
            [self pause];
            
        }
    }
}

- (void)itemDidFinishPlaying:(NSNotification*)notification
{

    if ( self.player.currentItem == notification.object && ![self playbackFinished]) {
        
        // Show Restart Button
        [self setPlaybackFinished:YES];
        [self.overlayView.restartPlaybackButton setHidden:NO];
        
        // Disable playback buttons
        [self.overlayView.playButton setEnabled:NO];
        [self.overlayView.airPlayButton setEnabled:NO];
        [self.overlayView.scrubber setEnabled:NO];
        
        // Force scroll videoScrollView
        CGFloat x = self.videoReel.videoScrollView.contentOffset.x + 1024.0f;
        CGFloat y = self.videoReel.videoScrollView.contentOffset.y;
        NSUInteger position = self.videoReel.videoScrollView.contentOffset.x/1024;
        if ( position+1 <= self.videoReel.numberOfVideos-1 )
            [self.videoReel.videoScrollView setContentOffset:CGPointMake(x, y) animated:YES];
        
        // Force methods to update
        if ( position+1 <= self.videoReel.numberOfVideos-1 )
            [self.videoReel currentVideoDidChangeToVideo:position+1];
        
        // Load videos
        if ( position+2 <= self.videoReel.numberOfVideos-1 )
            [self.videoReel extractVideoForVideoPlayer:position+2]; // Load video positioned after current visible view
        
        // Force next video to begin playing (video should already be loaded)
        [self.videoReel.currentVideoPlayer play];
        
    }    
}

#pragma mark - UIResponder Methods
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.overlayTimer invalidate];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.overlayTimer invalidate];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self resheduleOverlayTimer];
}

@end