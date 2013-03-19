//
//  SPVideoPlayer.m
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 11/1/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

#import "SPVideoPlayer.h"

// Models
#import "SPModel.h"

// Views
#import "SPOverlayView.h"

// Controllers
#import "SPShareLikeActivity.h"
#import "SPShareRollActivity.h"
#import "SPShareController.h"
#import "SPVideoExtractor.h"
#import "SPVideoDownloader.h"
#import "SPVideoScrubber.h"

// View Controllers
#import "SPVideoReel.h"

@interface SPVideoPlayer ()

@property (weak, nonatomic) AppDelegate *appDelegate;
@property (weak, nonatomic) SPModel *model;
@property (weak, nonatomic) SPOverlayView *overlayView;
@property (weak, nonatomic) SPVideoReel *videoReel;
@property (assign, nonatomic) CGRect viewBounds;
@property (nonatomic) SPShareController *shareController;
@property (nonatomic) AVPlayerLayer *playerLayer;
@property (nonatomic) UIActivityIndicatorView *indicator;
@property (nonatomic) NSMutableDictionary *videoInformation;

/// Setup Methods
- (void)setupReferences;
- (void)setupInitialConditions;
- (void)setupIndicator;
- (void)setupPlayerForURL:(NSURL *)playerURL;

/// Video Storage Methods
- (void)storeVideoForLater;

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
    self = [super init];
    if (self) {
        _viewBounds = bounds;
        _videoFrame = videoFrame;
    }
    
    return self;
}

#pragma mark - View Lifecycle Methods
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.view setFrame:self.viewBounds];
    [self setupReferences];
    [self setupInitialConditions];

}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // Initialize UIActivityIndicatorView if video has previously been downloaded
    NSManagedObjectContext *context = [self.appDelegate context];
    Frame *frame = (Frame *)[context existingObjectWithID:[_videoFrame objectID] error:nil];
    if ( ![frame.video.offlineURL length] ) {
        [self setupIndicator];
    }

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

- (void)setupPlayerForURL:(NSURL *)playerURL
{
    
    // TODO - Uncomment for AppStore
//    [[Panhandler sharedInstance] recordEvent];
    
    // Load AVPlayerAsset and AVPlayerItem with mp4 URL
    AVURLAsset *playerAsset = [AVURLAsset URLAssetWithURL:playerURL options:nil];
    AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithAsset:playerAsset];
    
    // Observer keypaths for buffer states on AVPlayerItem
    [playerItem addObserver:self forKeyPath:kShelbySPVideoBufferEmpty options:NSKeyValueObservingOptionNew context:nil];
    [playerItem addObserver:self forKeyPath:kShelbySPVideoBufferLikelyToKeepUp options:NSKeyValueObservingOptionNew context:nil];
    
    // Instantiate AVPlayer
    self.player = [[AVPlayer alloc] initWithPlayerItem:playerItem];
    
    // Redraw AVPlayer object for placement in UIScrollView on SPVideoReel
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
    CGRect modifiedFrame = CGRectMake(0.0f, 0.0f, self.view.frame.size.width, self.view.frame.size.height);
    self.playerLayer.frame = modifiedFrame;
    self.playerLayer.bounds = modifiedFrame;
    [self.view.layer addSublayer:_playerLayer];
    

    /*
     
     If video was previously extracted, 
     BUT dropped from memory,
     AND the stream token expired (e.g., 300 seconds elapsed),
     then videoInformation dictionary should exist from previous video storage,
     so reference previous video elapsedTime and reinstantiate player at last played position.
     
     */
     if ( [self.videoInformation valueForKey:kShelbySPVideoPlayerElapsedTime] ) {
    
        CMTime elapsedTime = [[self.videoInformation valueForKey:kShelbySPVideoPlayerElapsedTime] CMTimeValue];
        if ( CMTIME_IS_VALID(elapsedTime) ) {
            [self.player seekToTime:elapsedTime];
        }
        
         // Remove dictionary playback start position is set
        [self.videoInformation removeAllObjects];
    }
    
    // Set isPlayable Flag
    [self setIsPlayable:YES];
    
    if ( self == _model.currentVideoPlayer ) {
        
        [self.overlayView.restartPlaybackButton setHidden:YES];
        [self.overlayView.playButton setEnabled:YES];
        [self.overlayView.scrubber setEnabled:YES];
        [self.overlayView.shareButton setEnabled:YES];
        
    }
    
    // Add Gesture Recognizer
    UITapGestureRecognizer *togglePlaybackGesuture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(togglePlayback:)];
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
//    if ( [self.indicator isAnimating] ) {
//        [self.indicator stopAnimating];
//        [self.indicator removeFromSuperview];
//    }
//    
}

#pragma mark - Video Storage Methods (Public)
- (CMTime)elapsedTime
{
    if ( [self.player currentItem].status == AVPlayerItemStatusReadyToPlay ) {
        
		return [self.player.currentItem currentTime];
        
    }
	
	return kCMTimeInvalid;
}

- (CMTime)duration
{
    if ( [self.player currentItem].status == AVPlayerItemStatusReadyToPlay ) {
        
		return [self.player.currentItem duration];
        
    }
	
	return kCMTimeInvalid;
}

#pragma mark - Video Fetching Methods (Public)
- (void)queueVideo
{
    ///* This method is only entered if the video isn't stored offline. *///
    
    NSManagedObjectContext *context = [self.appDelegate context];
    NSManagedObjectID *objectID = [self.videoFrame objectID];
    self.videoFrame = (Frame *)[context existingObjectWithID:objectID error:nil];
    
    if ( [self.videoInformation valueForKey:kShelbySPVideoPlayerExtractedURL] ) { // If video has already been extracted, but dropped due to memory contraints, load it again.
        
        NSDate *storedDate = [self.videoInformation valueForKey:kShelbySPVideoPlayerStoredDate];
        NSTimeInterval interval = fabs([storedDate timeIntervalSinceNow]);
        
        if ( interval < 300 ) { // If video stream was last accessed within 300 seconds of being stored, re-instantiate SPVideoPlayer with existing mp4 URL
            
            // Referenced stored extracted MP4 url
            NSString *extractedURL = [self.videoInformation valueForKey:kShelbySPVideoPlayerExtractedURL];
            
            // Instantiate AVPlayer object with extractedURL
            [self setupPlayerForURL:[NSURL URLWithString:extractedURL]];
            
            // Set time of AVPlayer
            CMTime elapsedTime = [[self.videoInformation valueForKey:kShelbySPVideoPlayerElapsedTime] CMTimeValue];
            if ( CMTIME_IS_VALID(elapsedTime) ) {
                [self.player seekToTime:elapsedTime];
            }
            
            // Empty videoInformation dictionary
            [self.videoInformation removeAllObjects];
            
        } else { // If video has been stored for longer than 300 seconds, re-extract it.
            
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(loadVideo:)
                                                         name:kShelbySPVideoExtracted
                                                       object:nil];
            
            [[SPVideoExtractor sharedInstance] queueVideo:[_videoFrame video]];
            
        }
        
        
    } else { // If video hasn't been extracted, send it to the extractor
        
        if ( ![self isPlayable] ) {
            
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(loadVideo:)
                                                         name:kShelbySPVideoExtracted
                                                       object:nil];
            
            [[SPVideoExtractor sharedInstance] queueVideo:[_videoFrame video]];
            
        }
    }
}

#pragma mark - Video Playback Methods (Public)
- (void)togglePlayback:(id)sender
{
    
    // Send event to Google Analytics
    id defaultTracker = [GAI sharedInstance].defaultTracker;
    if ( [sender isMemberOfClass:[UITapGestureRecognizer class]] ) {
        
        [defaultTracker sendEventWithCategory:kGAICategoryVideoPlayer
                                   withAction:@"Playback toggled via double tap gesture"
                                    withLabel:[[SPModel sharedInstance].videoReel groupTitle]
                                    withValue:nil];
        
    } else if ( [sender isMemberOfClass:[SPVideoReel class]] ) {
        
        
        if ( [self isPlaying] ) {

            [defaultTracker sendEventWithCategory:kGAICategoryVideoPlayer
                                       withAction:@"Playback toggled via pause button"
                                        withLabel:[[SPModel sharedInstance].videoReel groupTitle]
                                        withValue:nil];
            
        } else {
            
            [defaultTracker sendEventWithCategory:kGAICategoryVideoPlayer
                                       withAction:@"Playback toggled via play button"
                                        withLabel:[[SPModel sharedInstance].videoReel groupTitle]
                                        withValue:nil];
            
        }
        
    } else {
        // Do nothing
    }
    
    // Toggle Playback
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
    
    // Set Playback Start
    [self setPlaybackStartTime:[self elapsedTime]];
    
    // Set Flag
    [self setIsPlaying:YES];
    
}

- (void)pause
{
    // Pause video
    [self.player pause];
        
    // Invalide Timer
    if ( self == _model.currentVideoPlayer ) {
        [self.model.overlayTimer invalidate];
    }
    
    // Store CMTime
    if ( [self isPlaying] ) {
        
        NSManagedObjectContext *context = [self.appDelegate context];
        NSManagedObjectID *objectID = [self.videoFrame objectID];
        Frame *videoFrame = (Frame *)[context existingObjectWithID:objectID error:nil];
        NSDictionary *elapsedTimeDictionary = (__bridge NSDictionary *)(CMTimeCopyAsDictionary([self elapsedTime], kCFAllocatorDefault));
        [videoFrame.video setElapsedTime:elapsedTimeDictionary];
        CFRelease((__bridge CFDictionaryRef)elapsedTimeDictionary);
        CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_ActionUpdate];
        [dataUtility saveContext:context];
        
    }
    
    // Set Flag
    [self setIsPlaying:NO];
    
}

- (void)share
{

    // TODO - Uncomment for AppStore
//    [[Panhandler sharedInstance] recordEvent];
    
    // Disable overlayTimer
    [self.model.overlayView showOverlayView];
    [self.model.overlayTimer invalidate];
 
    // shareController is an iVar because it contains an iVar reference of UIPopOverViewController which must be retianed
    self.shareController = [[SPShareController alloc] initWithVideoPlayer:self];
    [self.shareController share];
    
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
        NSString *extractedURL = [self.videoFrame.video extractedURL];
       
        // Download video for offline viewing
        if ( [[NSUserDefaults standardUserDefaults] boolForKey:kShelbyDefaultUserIsAdmin] && [[NSUserDefaults standardUserDefaults] boolForKey:kShelbyDefaultOfflineModeEnabled]  ) {
            
            [self.appDelegate downloadVideo:video];
            
        }
        
        // Load Player
        [self setupPlayerForURL:[NSURL URLWithString:extractedURL]];
        
    }
}

#pragma mark - Video Storage Methods (Private)
- (void)resetPlayer
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        [self storeVideoForLater];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [[NSNotificationCenter defaultCenter] removeObserver:self name:kShelbySPVideoExtracted object:nil];
            [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
            
            [self.player pause];
            
            [self.playerLayer removeFromSuperlayer];
            [self setPlayerLayer:nil];
            [self setPlayer:nil];
            
            [self setupInitialConditions];
            
        });
    });
}

#pragma mark - Video Storage Methods (Private)
- (void)storeVideoForLater
{
    
    // Get value for kShelbySPVideoPlayerStoredDate key
    NSManagedObjectContext *context = [self.appDelegate context];
    NSManagedObjectID *objectID = [self.videoFrame objectID];
    self.videoFrame = (Frame *)[context existingObjectWithID:objectID error:nil];
    NSDate *storedDate = [NSDate date];

    // Get value for kShelbySPVideoPlayerElapsedTime key
    CMTime elapsedTime = [self elapsedTime];
    CMTime duration = [self duration];
    CGFloat elapsedSeconds = elapsedTime.value / elapsedTime.timescale;
    CGFloat durationSeconds = duration.value / duration.timescale;
    CGFloat timeDifference = fabs(durationSeconds-elapsedSeconds);
    NSValue *storedElapsedTimeValue = ( timeDifference > 5.0f ) ? [NSValue valueWithCMTime:elapsedTime] : [NSValue valueWithCMTime:kCMTimeZero];
    
    if ( _videoFrame.video.extractedURL.length ) {
        
        NSDictionary *dictionary = @{ kShelbySPVideoPlayerStoredDate : storedDate, kShelbySPVideoPlayerElapsedTime : storedElapsedTimeValue, kShelbySPVideoPlayerExtractedURL : _videoFrame.video.extractedURL };
        self.videoInformation = [dictionary mutableCopy];
    }
    
}

#pragma mark - Observer Methods (Private)
- (void)loadVideoFromDisk
{
    
    if ( [self.videoInformation valueForKey:kShelbySPVideoPlayerExtractedURL] && ![self isPlayable] ) { // If video has already been extracted, but dropped due to memory contraints, load it again.
        
        // Instantiate AVPlayer object with extractedURL
        NSString *extractedURL = [self.videoInformation valueForKey:kShelbySPVideoPlayerExtractedURL];
        
        // Reload player
        [self setupPlayerForURL:[NSURL fileURLWithPath:extractedURL]];
        
        // Set Time
        CMTime elapsedTime = [[self.videoInformation valueForKey:kShelbySPVideoPlayerElapsedTime] CMTimeValue];
        if ( CMTIME_IS_VALID(elapsedTime) ) {
            [self.player seekToTime:elapsedTime];
        }
        
    } else if ( ![self isPlayable] ) { // If video hasn't been loaded from disk, load it
        
        NSManagedObjectContext *context = [self.appDelegate context];
        NSManagedObjectID *objectID = [self.videoFrame objectID];
        Frame *videoFrame = (Frame *)[context existingObjectWithID:objectID error:nil];
        
        // Set extractedURL equal to offlineURL for quick video player reloading during used in caching
        videoFrame.video.extractedURL = [videoFrame.video offlineURL];
        
        // Save change in Core Data store
        CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_ActionUpdate];
        [dataUtility saveContext:context];
        
        // Load Player
        NSString *extractedURL = [videoFrame.video extractedURL];
        [self setupPlayerForURL:[NSURL fileURLWithPath:extractedURL]];

    } else { // Video previosuly loaded from disk and still in memory
        
        // Do nothing
        
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

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ( ![self player] ) {
    
        return;
    
    } else if ( object == _player.currentItem && [keyPath isEqualToString:kShelbySPVideoBufferEmpty] ) {
   
        if ( [self.player currentItem].playbackBufferEmpty) { // Buffer is Empty
        
            [self setupIndicator];
    
        }
   
    } else if (object == _player.currentItem && [keyPath isEqualToString:kShelbySPVideoBufferLikelyToKeepUp]) {
        
        if ( [self.player currentItem].playbackLikelyToKeepUp ) { // Playback will resume
        
            // Stop animating indicator
            if ( [self.indicator isAnimating] ) {
                [self.indicator stopAnimating];
                [self.indicator removeFromSuperview];
            }
        }
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
