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

@property (assign, nonatomic) BOOL autoPlay;
@property (strong, nonatomic) AVPlayerLayer *playerLayer;
@property (strong, nonatomic) UIActivityIndicatorView *indicator;
@property (strong, nonatomic) SPOverlayView *overlayView;
@property (strong, nonatomic) SPVideoReel *videoReel;
@property (strong, nonatomic) UIPopoverController *sharePopOverController;

- (void)loadVideo:(NSNotification*)notification;
- (void)itemDidFinishPlaying:(NSNotification*)notification;

@end

@implementation SPVideoPlayer
@synthesize videoFrame = _videoFrame;
@synthesize autoPlay = _autoPlay;
@synthesize player = _player;
@synthesize playerLayer = _playerLayer;
@synthesize indicator = _indicator;
@synthesize overlayView = _overlayView;
@synthesize videoReel = _videoReel;
@synthesize sharePopOverController = _sharePopOverController;
@synthesize videoQueued = _videoQueued;
@synthesize playbackFinished = _playbackFinished;

#pragma mark - Memory Management
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kSPVideoExtracted object:nil];
}

#pragma mark - Initialization Methods
- (id)initWithBounds:(CGRect)bounds
       forVideoFrame:(Frame *)videoFrame
     withOverlayView:(SPOverlayView *)overlayView
         inVideoReel:(id)videoReel
   andShouldAutoPlay:(BOOL)autoPlay
{
    if ( self = [super init] ) {
        
        [self.view setFrame:bounds];
        [self setVideoFrame:videoFrame];
        [self setAutoPlay:autoPlay];
        [self setOverlayView:overlayView];
        [self setVideoReel:videoReel];
        [self setVideoQueued:NO];
        [self setPlaybackFinished:NO];
        
    }
    
    return self;
}

#pragma mark - Public Methods
- (void)queueVideo
{

    [self setVideoQueued:YES];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(loadVideo:)
                                                 name:kSPVideoExtracted
                                               object:nil];
    
    CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
    NSManagedObjectContext *context = [dataUtility context];
    Frame *tempFrame = (Frame*)[context existingObjectWithID:[_videoFrame objectID] error:nil];
    [[SPVideoExtractor sharedInstance] queueVideo:tempFrame.video];

}

#pragma mark - View Lifecycle Methods
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // Add indicator
    CGRect modifiedFrame = CGRectMake(0.0f, 0.0f,self.view.frame.size.width, self.view.frame.size.height);
    self.indicator = [[UIActivityIndicatorView alloc] initWithFrame:modifiedFrame];
    self.indicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
    self.indicator.hidesWhenStopped = YES;
    [self.indicator startAnimating];
    [self.view addSubview:self.indicator];
    
}

#pragma mark - Player Controls
- (void)togglePlayback
{
    if ( 0.0 == self.player.rate && _videoQueued ) { // Play
        
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
    [self.player play];
    [self.overlayView.playButton setTitle:@"Pause" forState:UIControlStateNormal];
    [self setupScrubber];
    
}

- (void)pause
{
    [self.player pause];
    [self.overlayView.playButton setTitle:@"Play" forState:UIControlStateNormal];
}

- (void)airPlay
{

}

- (void)share
{
    CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
    NSManagedObjectContext *context = [dataUtility context];
    Frame *videoFrame = (Frame*)[context existingObjectWithID:[self.videoFrame objectID] error:nil];
    
    NSString *shareLink = [NSString stringWithFormat:kSPVideoShareLink, videoFrame.rollID, videoFrame.frameID];
    NSString *shareMessage = [NSString stringWithFormat:@"Watch \"%@\" %@ /via @Shelby", videoFrame.video.title, shareLink];
    UIActivityViewController *shareController = [[UIActivityViewController alloc] initWithActivityItems:@[shareMessage] applicationActivities:nil];
    self.sharePopOverController = [[UIPopoverController alloc] initWithContentViewController:shareController];
    [self.sharePopOverController presentPopoverFromRect:self.overlayView.shareButton.frame
                                                 inView:self.overlayView
                               permittedArrowDirections:UIPopoverArrowDirectionDown
                                               animated:YES];
}

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
		self.overlayView.scrubber.minimumValue = 0.0;
		return;
	}
    
	double duration = CMTimeGetSeconds(playerDuration);
	if ( isfinite(duration) ) {
		float minValue = [self.overlayView.scrubber minimumValue];
		float maxValue = [self.overlayView.scrubber maximumValue];
		double time = CMTimeGetSeconds([self.player currentTime]);
		
		[self.overlayView.scrubber setValue:(maxValue - minValue) * time / duration + minValue];
	}
}

#pragma mark - Video Loading Methods
- (void)loadVideo:(NSNotification*)notification
{

    CoreDataUtility *utility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
    NSManagedObjectContext *context = [utility context];
    self.videoFrame = (Frame*)[context existingObjectWithID:[self.videoFrame objectID] error:nil];
    
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
        
        // Add Observers
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(itemDidFinishPlaying:)
                                                     name:AVPlayerItemDidPlayToEndTimeNotification
                                                   object:playerItem];

        
        // Video begins in 'pause'-mode by default
        [self.player pause];
        
        if ( _autoPlay ) { // Start AVPlayer object in 'play' mode
            
            [self play];
            
            [UIView animateWithDuration:1.0f animations:^{
                [self.overlayView setAlpha:0.0f]; 
            }];
            
        } 
    }
}

- (void)itemDidFinishPlaying:(NSNotification*)notification
{
    DLog(@"%@", notification);
    
    if ( self.player.currentItem == notification.object && ![self playbackFinished]) {
        
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
        [self.videoReel playButtonAction:nil];
        
    }    
}

@end