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
@property (nonatomic) SPShareController *shareController;
@property (nonatomic) AVPlayerLayer *playerLayer;
@property (nonatomic) UIActivityIndicatorView *indicator;
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
    
    AVURLAsset *playerAsset = [AVURLAsset URLAssetWithURL:extractedURL options:nil];
    AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithAsset:playerAsset];
    self.player = [[AVPlayer alloc] initWithPlayerItem:playerItem];
    
    DLog(@"Loaded URL: %@", [[playerAsset URL] absoluteString]);
    
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
        [self.overlayView.shareButton setEnabled:YES];
        
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

- (void)storeVideoForLater
{
       
    NSDate *storedDate = [NSDate date];
    NSValue *elapsedTime = [NSValue valueWithCMTime:[self elapsedTime]];
    NSManagedObjectContext *context = [self.appDelegate context];
    NSManagedObjectID *objectID = [self.videoFrame objectID];
    self.videoFrame = (Frame *)[context existingObjectWithID:objectID error:nil];

    if ( _videoFrame.video.extractedURL.length ) {
        
        NSDictionary *dictionary = @{ kShelbySPVideoPlayerStoredDate : storedDate, kShelbySPVideoPlayerElapsedTime : elapsedTime, kShelbySPVideoPlayerExtractedURL : _videoFrame.video.extractedURL };
        self.videoInformation = [dictionary mutableCopy];
    }
    
}

- (CMTime)elapsedTime
{
    return [self.player.currentItem currentTime];
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
    
    NSManagedObjectContext *context = [_appDelegate context];
    Frame *videoFrame = (Frame *)[context existingObjectWithID:[_videoFrame objectID] error:nil];
    DLog(@"%@", videoFrame.video.title);
}

- (void)pause
{
    // Pause video
    [self.player pause];
        
    // Invalide Timer
    if ( self == _model.currentVideoPlayer ) {
        [self.model.overlayTimer invalidate];
    }
    
    // Set Flag
    [self setIsPlaying:NO];
}

- (void)share
{

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
        NSURL *extractedURL = [NSURL URLWithString:_videoFrame.video.extractedURL];
       
        // Download video for offline use if user is administrator
        if ( [[NSUserDefaults standardUserDefaults] boolForKey:kShelbyDefaultUserIsAdmin] ) {
            
            SPVideoDownloader *videoDownloader = [[SPVideoDownloader alloc] initWithVideo:video inPlayer:self];
            [videoDownloader downloadVideo];
      
        }
        
        // Load Player
        [self setupPlayerForURL:extractedURL];
        
    }
}

- (void)loadVideoFromDisk
{
    
    if ( [self.videoInformation valueForKey:kShelbySPVideoPlayerExtractedURL] && ![self isPlayable] ) { // If video has already been extracted, but dropped due to memory contraints, load it again.
        
        // Instantiate AVPlayer object with extractedURL
        NSURL *extractedURL = [NSURL URLWithString:[self.videoInformation valueForKey:kShelbySPVideoPlayerExtractedURL]];
        
        DLog(@"CHECK 1: %@", extractedURL);
        
        // Reload player
        [self setupPlayerForURL:extractedURL];
        
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
        
        NSURL *extractedURL = [NSURL URLWithString:videoFrame.video.extractedURL];
        
        DLog(@"CHECK 2: %@", extractedURL);
        
        // Load Player
        [self setupPlayerForURL:extractedURL];

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
