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
#import "SPVideoScrubber.h"
#import "SPVideoReel.h"

@interface SPVideoPlayer ()

@property (weak, nonatomic) AppDelegate *appDelegate;
@property (weak, nonatomic) SPModel *model;
@property (weak, nonatomic) SPOverlayView *overlayView;
@property (weak, nonatomic) SPVideoReel *videoReel;
@property (nonatomic) AVPlayerLayer *playerLayer;
@property (nonatomic) UIActivityIndicatorView *indicator;
@property (nonatomic) UIPopoverController *sharePopOverController;
@property (nonatomic) NSMutableDictionary *videoInformation;

/// Setup Methods
- (void)setupReferences;
- (void)setupInitialConditions;
- (void)setupIndicator;
- (void)setupPlayerForURL:(NSURL *)extractedURL;

/// Storage Methods
- (void)storeVideoForLater;
- (CMTime)elapsedTime;

/// Observer Methods
- (void)loadVideo:(NSNotification *)notification;
- (void)itemDidFinishPlaying:(NSNotification *)notification;

@end

@implementation SPVideoPlayer

#pragma mark - Memory Management Methods
- (void)dealloc
{

    [[NSNotificationCenter defaultCenter] removeObserver:self name:kShelbySPVideoExtracted object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    
    DLog(@"SPVideoPlayer Deallocated");
    
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

#pragma mark - View Lifecycle Methods
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self setupIndicator];
}

#pragma mark - Setup Methods
- (void)setupReferences
{
    [self setAppDelegate:(AppDelegate *)[[UIApplication sharedApplication] delegate]];
    [self setModel:[SPModel sharedInstance]];
    [self setOverlayView:_model.overlayView];
    [self setVideoReel:_model.videoReel];
}

- (void)setupInitialConditions
{
    [self setPlaybackFinished:NO];
    [self setIsPlayable:NO];
    [self setIsPlaying:NO];
}

- (void)setupIndicator
{
    CGRect modifiedFrame = CGRectMake(0.0f, 0.0f, self.view.frame.size.width, self.view.frame.size.height);
    self.indicator = [[UIActivityIndicatorView alloc] initWithFrame:modifiedFrame];
    self.indicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
    self.indicator.hidesWhenStopped = YES;
    [self.indicator startAnimating];
    [self.view addSubview:_indicator];
}

- (void)setupPlayerForURL:(NSURL *)extractedURL
{
    
    AVAsset *playerAsset = [AVURLAsset URLAssetWithURL:extractedURL options:nil];
    AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithAsset:playerAsset];
    self.player = [[AVPlayer alloc] initWithPlayerItem:playerItem];
    
    // Redraw AVPlayer object for placement in UIScrollView on SPVideoReel
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
    CGRect modifiedFrame = CGRectMake(0.0f, 0.0f, self.view.frame.size.width, self.view.frame.size.height);
    self.playerLayer.frame = modifiedFrame;
    self.playerLayer.bounds = modifiedFrame;
    [self.view.layer addSublayer:_playerLayer];
    
    // Set isPlayable Flag
    [self setIsPlayable:YES];
    
    if ( self == _model.currentVideoPlayer ) {
        
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
    
    /*
     
     This line stores a video in an array that's used for lazy memory management queue.
     The array purges an older video instance when a limit is reached.
     
     */
    [self.videoReel storeLoadedVideoPlayer:self];
    
    // Toggle video playback
    if ( self == _model.currentVideoPlayer ) {
        
        [self play];
        [self.model rescheduleOverlayTimer];
        
    } else {
        
        [self pause];
        
    }
    
    // Stop animating indicator here (placing it here compensates for the extra ~ 1 second it takes to load the video into AVPlayer)
    if ( [_indicator isAnimating] ) {
        [self.indicator stopAnimating];
    }
    
}

#pragma mark - Video Storage Methods
- (void)resetPlayer
{
    [self storeVideoForLater];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kShelbySPVideoExtracted object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    
    [self.player pause];
    
    [self.playerLayer removeFromSuperlayer];
    [self setPlayerLayer:nil];
    [self setPlayer:nil];
    
    [self setupInitialConditions];
}

- (void)storeVideoForLater
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
       
        NSDate *storedDate = [NSDate date];
        NSValue *elapsedTime = [NSValue valueWithCMTime:[self elapsedTime]];
        NSManagedObjectContext *context = [self.appDelegate context];
        NSManagedObjectID *objectID = [self.videoFrame objectID];
        self.videoFrame = (Frame *)[context existingObjectWithID:objectID error:nil];
        
        if ( _videoFrame.video.extractedURL.length ) {
            
            NSDictionary *dictionary = @{ kShelbySPVideoPlayerStoredDate : storedDate, kShelbySPVideoPlayerElapsedTime : elapsedTime, kShelbySPVideoPlayerExtractedURL : _videoFrame.video.extractedURL };
            self.videoInformation = [dictionary mutableCopy];
        }
    });
}

- (CMTime)elapsedTime
{
    
    AVPlayerItem *playerItem = [self.player currentItem];
    
    if ( playerItem.status == AVPlayerItemStatusReadyToPlay ) {
    
		return [playerItem currentTime] ;
	}
	
	return kCMTimeInvalid;
}

#pragma mark - Video Fetching Methods
- (void)queueVideo
{
    
    if ( [self.videoInformation valueForKey:kShelbySPVideoPlayerExtractedURL] ) { // If video has already been extracted, but dropped due to memory contraints, load it again.
        
        // Instantiate AVPlayer object with extractedURL
        NSURL *extractedURL = [NSURL URLWithString:[self.videoInformation valueForKey:kShelbySPVideoPlayerExtractedURL]];
        
        // Reload player
        [self setupPlayerForURL:extractedURL];
        
        // Set Time
        CMTime elapsedTime = [[self.videoInformation valueForKey:kShelbySPVideoPlayerElapsedTime] CMTimeValue];
        if ( CMTIME_IS_VALID(elapsedTime) ) {
            [self.player seekToTime:elapsedTime];
        }
        
    } else { // If video hasn't been extracted, send it to the extractor
     
        if ( ![self isPlayable] ) {
            
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(loadVideo:)
                                                         name:kShelbySPVideoExtracted
                                                       object:nil];
            
            NSManagedObjectContext *context = [self.appDelegate context];
            NSManagedObjectID *objectID = [self.videoFrame objectID];
            self.videoFrame = (Frame *)[context existingObjectWithID:objectID error:nil];
            [[SPVideoExtractor sharedInstance] queueVideo:_videoFrame.video];
            
        }
        
    }
}

#pragma mark - Video Playback Methods
- (void)togglePlayback
{
    if ( 0.0 == _player.rate && _isPlayable ) { // Play
        
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
    [[SPVideoScrubber sharedInstance] syncScrubber];
    [self.player play];
}

- (void)play
{
    // Play video
    [self.player play];
    
    // Begin updating videoScrubber periodically 
    [[SPVideoScrubber sharedInstance] setupScrubber];
    
    // Reschedule Timer
    [self.model rescheduleOverlayTimer];
    
    // Set Flag
    [self setIsPlaying:YES];
}

- (void)pause
{
    // Pause video
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
    self.videoFrame = (Frame *)[context existingObjectWithID:objectID error:nil];
    
    NSString *shareLink = [NSString stringWithFormat:kShelbySPVideoShareLink, _videoFrame.video.providerName, _videoFrame.video.providerID, _videoFrame.frameID];
    NSString *shareMessage = [NSString stringWithFormat:@"Watch \"%@\" %@ /via @Shelby", _videoFrame.video.title, shareLink];
    UIActivityViewController *shareController = [[UIActivityViewController alloc] initWithActivityItems:@[shareMessage] applicationActivities:nil];
    self.sharePopOverController = [[UIPopoverController alloc] initWithContentViewController:shareController];
    [self.sharePopOverController presentPopoverFromRect:_overlayView.shareButton.frame
                                                 inView:_overlayView
                               permittedArrowDirections:UIPopoverArrowDirectionDown
                                               animated:YES];
}

- (void)loadVideo:(NSNotification *)notification
{

    NSManagedObjectContext *context = [self.appDelegate context];
    NSManagedObjectID *objectID = [self.videoFrame objectID];
    self.videoFrame = (Frame *)[context existingObjectWithID:objectID error:nil];
    
    Video *video = [notification.userInfo valueForKey:kShelbySPCurrentVideo];
    
    if ( [self.videoFrame.video.providerID isEqualToString:video.providerID] ) {
        
        // Clear notification
        [[NSNotificationCenter defaultCenter] removeObserver:self name:kShelbySPVideoExtracted object:nil];
        
        // Instantiate AVPlayer object with extractedURL
        NSURL *extractedURL = [NSURL URLWithString:_videoFrame.video.extractedURL];
       
        // Load Player
        [self setupPlayerForURL:extractedURL];
        
    }
}

- (void)itemDidFinishPlaying:(NSNotification *)notification
{

    if ( _player.currentItem == notification.object && ![self playbackFinished]) {
        
        // Show Restart Button
        [self setPlaybackFinished:YES];
        
        // Force scroll videoScrollView
        [self.videoReel currentVideoDidFinishPlayback];
        
    }    
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
