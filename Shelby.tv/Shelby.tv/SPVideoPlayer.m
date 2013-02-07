//
//  SPVideoPlayer.m
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 11/1/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

#import "SPVideoPlayer.h"
#import "SPModel.h"
#import "SPOverlayView.h"
#import "SPVideoExtractor.h"
#import "SPVideoReel.h"

@interface SPVideoPlayer ()

@property (nonatomic) AppDelegate *appDelegate;
@property (nonatomic) SPModel *model;
@property (weak, nonatomic) SPOverlayView *overlayView;
@property (weak, nonatomic) SPVideoReel *videoReel;
@property (nonatomic) AVPlayerLayer *playerLayer;
@property (nonatomic) UIActivityIndicatorView *indicator;
@property (nonatomic) UIPopoverController *sharePopOverController;

/// Setup Methods
- (void)setupReferences;
- (void)setupInitialConditions;
- (void)setupIndicator;

/// Observer Methods
- (void)loadVideo:(NSNotification*)notification;
- (void)itemDidFinishPlaying:(NSNotification*)notification;

@end

@implementation SPVideoPlayer

#pragma mark - Memory Management Methods
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kSPVideoExtracted object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    
    
    DLog(@"%@ | %@ | %d", self, self.playerLayer, self.player);
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];

}

#pragma mark - Initialization Methods
- (id)initWithBounds:(CGRect)bounds withVideoFrame:(Frame *)videoFrame
{
    if ( (self = [super init]) ) {
        
        [self.view setFrame:bounds];
        [self setVideoFrame:videoFrame];
        [self setupReferences];
        [self setupInitialConditions];
        
    }
    
    return self;
}

- (void)resetPlayer
{
    [self.player pause];
    [self.playerLayer removeFromSuperlayer];
    [self setPlayerLayer:nil];
    [self setPlayer:nil];
    [self setupInitialConditions];
    [self setupIndicator];
}

#pragma mark - View Lifecycle Methods
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self setupIndicator];
}

#pragma mark - Setup Methods
- (void)setupReferences
{
    [self setAppDelegate:(AppDelegate*)[[UIApplication sharedApplication] delegate]];
    [self setModel:[SPModel sharedInstance]];
    [self setOverlayView:self.model.overlayView];
    [self setVideoReel:self.model.videoReel];
}

- (void)setupInitialConditions
{
    [self setPlaybackFinished:NO];
    [self setIsPlayable:NO];
    [self setIsPlaying:NO];
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
        [[SPVideoExtractor sharedInstance] queueVideo:self.videoFrame.video];
        
    }
}

#pragma mark - Video Playback Methods
- (void)togglePlayback
{
    if ( 0.0 == self.player.rate && self.isPlayable ) { // Play
        
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
    [self.overlayView.scrubber setEnabled:YES];
    
    [self.player seekToTime:CMTimeMakeWithSeconds(0.0f, NSEC_PER_SEC)];
    [self syncScrubber];
    [self.player play];
}

- (void)play
{
    // Play video and update UI
    [self.player play];
    
    // Reschedule Timer
    [self.model rescheduleOverlayTimer];
    
    // Set Flag
    [self setIsPlaying:YES];
}

- (void)pause
{
    // Pause video and update UI
    [self.player pause];

    // Invalide Timer
    [self.model.overlayTimer invalidate];
    
    // Set Flag
    [self setIsPlaying:NO];
}

- (void)share
{

    NSManagedObjectContext *context = [self.appDelegate context];
    NSManagedObjectID *objectID = [self.videoFrame objectID];
    self.videoFrame = (Frame*)[context existingObjectWithID:objectID error:nil];
    
    NSString *shareLink = [NSString stringWithFormat:kSPVideoShareLink, self.videoFrame.video.providerName, self.videoFrame.video.providerID, self.videoFrame.frameID];
    NSString *shareMessage = [NSString stringWithFormat:@"Watch \"%@\" %@ /via @Shelby", self.videoFrame.video.title, shareLink];
    UIActivityViewController *shareController = [[UIActivityViewController alloc] initWithActivityItems:@[shareMessage] applicationActivities:nil];
    self.sharePopOverController = [[UIPopoverController alloc] initWithContentViewController:shareController];
    [self.sharePopOverController presentPopoverFromRect:self.overlayView.shareButton.frame
                                                 inView:self.overlayView
                               permittedArrowDirections:UIPopoverArrowDirectionDown
                                               animated:YES];
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
        NSURL *extractedURL = [NSURL URLWithString:self.videoFrame.video.extractedURL];
        AVAsset *playerAsset = [AVURLAsset URLAssetWithURL:extractedURL options:nil];
        AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithAsset:playerAsset];
        self.player = [[AVPlayer alloc] initWithPlayerItem:playerItem];
        
        // Redraw AVPlayer object for placement in UIScrollView on SPVideoReel
        self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
        CGRect modifiedFrame = CGRectMake(0.0f, 0.0f,self.view.frame.size.width, self.view.frame.size.height);
        self.playerLayer.frame = modifiedFrame;
        self.playerLayer.bounds = modifiedFrame;
        [self.view.layer addSublayer:self.playerLayer];
        
        // Make sure video can be played via AirPlay
        self.player.allowsExternalPlayback = YES;
        
        // Set isPlayable Flag
        [self setIsPlayable:YES];
        [self setupScrubber];
        
        if ( self == self.model.currentVideoPlayerDelegate ) {
         
            [self.overlayView.restartPlaybackButton setHidden:YES];
            [self.overlayView.playButton setEnabled:YES];
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
        
//        [self.model storeVideoPlayer:self];
        
        // Toggle video playback
        if ( self == self.model.currentVideoPlayerDelegate ) {
            
            [self play];
            [self.model rescheduleOverlayTimer];
            
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
        
        // Force scroll videoScrollView
        [self.videoReel currentVideoDidFinishPlayback];
        
    }    
}

#pragma mark - SPVideoScrubberDelegate Methods
- (CMTime)elapsedDuration
{
	
    AVPlayerItem *playerItem = [self.player currentItem];
    
    if ( playerItem.status == AVPlayerItemStatusReadyToPlay ) {
        
		return [playerItem duration] ;
	}
	
	return kCMTimeInvalid;
}

- (void)setupScrubber
{
	
    CGFloat interval = .1f;
	CMTime playerDuration = [self elapsedDuration];
    
	if (CMTIME_IS_INVALID(playerDuration)) {
        [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(setupScrubber) userInfo:nil repeats:NO];
        
        return;
	}
	
    CGFloat duration = CMTimeGetSeconds(playerDuration);
	if (isfinite(duration)) {
		CGFloat width = CGRectGetWidth([self.overlayView.scrubber bounds]);
		interval = 0.5f * duration / width;
	}
    
        __block SPVideoPlayer *blockSelf  = self;
        
        self.model.scrubberTimeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(interval, NSEC_PER_MSEC)
                                                                                                                     queue:NULL /* If you pass NULL, the main queue is used. */
                                                                                                                usingBlock:^(CMTime time) {
                                                                                                               
                                                                                                                    [blockSelf syncScrubber];
                                                                                                                
                                                                                                                }];
}

- (void)syncScrubber
{
	CMTime playerDuration = [self elapsedDuration];
	if ( CMTIME_IS_INVALID(playerDuration) ) {
        [self.overlayView.scrubber setValue:0.0f];
        [self.overlayView.playButton setImage:[UIImage imageNamed:@"playButton"] forState:UIControlStateNormal];
		return;
	}
    
	double duration = CMTimeGetSeconds(playerDuration);
    
	if ( isfinite(duration) && self.player == self.model.currentVideoPlayerDelegate.player ) {
        
        // Update value of scrubber (slider and label)
		CGFloat minValue = [self.overlayView.scrubber minimumValue];
		CGFloat maxValue = [self.overlayView.scrubber maximumValue];
        
        CGFloat currentTime = CMTimeGetSeconds([self.model.currentVideoPlayerDelegate.player currentTime]);
        CGFloat duration = CMTimeGetSeconds([self.model.currentVideoPlayerDelegate.player.currentItem duration]);

        
            [self.overlayView.scrubber setValue:(maxValue - minValue) * currentTime / duration + minValue];
            [self.overlayView.scrubberTimeLabel setText:[self convertElapsedTime:currentTime andDuration:duration]];

        // Update button state
        if ( 0.0 == self.player.rate && self.isPlayable && self.player == self.model.currentVideoPlayerDelegate.player ) {
        
            [self.overlayView.playButton setImage:[UIImage imageNamed:@"playButton"] forState:UIControlStateNormal];
            
        } else { 
            
            [self.overlayView.playButton setImage:[UIImage imageNamed:@"pauseButton"] forState:UIControlStateNormal];
        }
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

#pragma mark - UIResponder Methods
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.model.overlayTimer invalidate];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.model.overlayTimer invalidate];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.model rescheduleOverlayTimer];
}

@end
