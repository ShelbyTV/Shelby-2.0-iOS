//
//  SPVideoPlayer.m
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 11/1/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

#import "SPVideoPlayer.h"
#import "SPCacheUtility.h"
#import "SPVideoExtractor.h"
#import "SPOverlayView.h"
#import "SPVideoReel.h"

@interface SPVideoPlayer ()

@property (strong, nonatomic) AVPlayerLayer *playerLayer;
@property (strong, nonatomic) UIActivityIndicatorView *indicator;
@property (strong, nonatomic) SPOverlayView *overlayView;
@property (strong, nonatomic) SPVideoReel *videoReel;
@property (strong, nonatomic) UIPopoverController *sharePopOverController;

- (void)loadVideo:(NSNotification*)notification;
- (void)itemDidFinishPlaying:(NSNotification*)notification;
- (NSString*)convertElapsedTime:(double)currentTime andDuration:(double)duration;

@end

@implementation SPVideoPlayer
@synthesize videoFrame = _videoFrame;
@synthesize player = _player;
@synthesize playerLayer = _playerLayer;
@synthesize indicator = _indicator;
@synthesize overlayView = _overlayView;
@synthesize videoReel = _videoReel;
@synthesize sharePopOverController = _sharePopOverController;
@synthesize playbackFinished = _playbackFinished;
@synthesize isPlayable = _isPlayable;

#pragma mark - Memory Management Methods
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kSPVideoExtracted object:nil];
}

- (void)didReceiveMemoryWarning
{
    
    DLog(@"MEMORY WARNING %@", self.videoFrame.video.title);
    
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
        [self setPlaybackFinished:NO];
        [self setIsPlayable:NO];
        
    }
    
    return self;
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


#pragma mark - Video Fetching Methods
- (void)queueVideo
{
    
    if ( ![self isPlayable] ) {
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(loadVideo:)
                                                     name:kSPVideoExtracted
                                                   object:nil];
        
        CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
        NSManagedObjectContext *context = [dataUtility context];
        Frame *tempFrame = (Frame*)[context existingObjectWithID:[_videoFrame objectID] error:nil];
        [[SPVideoExtractor sharedInstance] queueVideo:tempFrame.video];
        
    }
}


- (void)addToCache
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
        NSManagedObjectContext *context = [dataUtility context];
        NSError *error = nil;
        Frame *videoFrame = (Frame*)[context existingObjectWithID:[self.videoFrame objectID] error:&error];
        
        DLog(@"Cache Add Error: %@", error);
        
        [[SPCacheUtility sharedInstance] addVideoFrame:videoFrame inOverlay:_overlayView];
   
    });

}

- (void)removeFromCache
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
        NSManagedObjectContext *context = [dataUtility context];
        NSError *error = nil;
        Frame *videoFrame = (Frame*)[context existingObjectWithID:[self.videoFrame objectID] error:&error];
        
        DLog(@"Cache Remove Error: %@", error);
        [[SPCacheUtility sharedInstance] removeVideoFrame:videoFrame inOverlay:_overlayView];
   
    });
    
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
    [self.player play];
    [self.overlayView.playButton setTitle:@"Pause" forState:UIControlStateNormal];
    [self.overlayView.playButton setImage:[UIImage imageNamed:@"pauseButton"] forState:UIControlStateNormal];
}

- (void)pause
{
    [self.player pause];
    [self.overlayView.playButton setTitle:@"Play" forState:UIControlStateNormal];
    [self.overlayView.playButton setImage:[UIImage imageNamed:@"playButton"] forState:UIControlStateNormal];
}

- (void)airPlay
{

}

- (void)share
{
    CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
    NSManagedObjectContext *context = [dataUtility context];
    self.videoFrame = (Frame*)[context existingObjectWithID:[self.videoFrame objectID] error:nil];
    
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

    convertedTime= [NSString stringWithFormat:@"%.2d:%.2d:%.2d / %.2d:%.2d:%.2d", currentTimeHours, currentTimeMinutes, currentTimeSeconds, durationHours, durationMinutes, durationSeconds];
    
    return convertedTime;
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
        
        // Set isPlayable Flag
        [self setIsPlayable:YES];
        [self.overlayView.restartPlaybackButton setHidden:YES];
        [self.overlayView.playButton setEnabled:YES];
        [self.overlayView.airPlayButton setEnabled:YES];
        [self.overlayView.scrubber setEnabled:YES];
        [self setupScrubber];
        
        // Add Observers
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(itemDidFinishPlaying:)
                                                     name:AVPlayerItemDidPlayToEndTimeNotification
                                                   object:playerItem];

        // Configure downloadButton
        [self.overlayView.downloadButton setHidden:NO];
        [self.overlayView.downloadButton setEnabled:YES];
        
        if ( _videoFrame.isCached ) { // Cached
            
            [self.overlayView.downloadButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
            [self.overlayView.downloadButton addTarget:self action:@selector(removeFromCache) forControlEvents:UIControlEventTouchUpInside];
            [self.overlayView.downloadButton setTitle:@"Remove" forState:UIControlStateNormal];
            
        } else { // Not Cached
            
            [self.overlayView.downloadButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
            [self.overlayView.downloadButton addTarget:self action:@selector(addToCache) forControlEvents:UIControlEventTouchUpInside];
            [self.overlayView.downloadButton setTitle:@"Download" forState:UIControlStateNormal];
            
        }
        
        // Toggle video playback
        if ( self == _videoReel.currentVideoPlayer ) { // Start AVPlayer object in 'play' mode
            
            [self play];
            
        } else {

            [self.player pause];
        
        }
    
    }
}

- (void)itemDidFinishPlaying:(NSNotification*)notification
{

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
        [self.videoReel.currentVideoPlayer play];
        
    }    
}

@end