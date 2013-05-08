//
//  SPVideoPlayer.m
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 11/1/12.
//  Copyright (c) 2012 Shelby TV. All rights reserved.
//

#import "SPVideoPlayer.h"

// Models
//djs
//#import "SPModel.h"

// Views
#import "SPOverlayView.h"

// Controllers
#import "SPShareController.h"
#import "SPVideoExtractor.h"
#import "SPVideoDownloader.h"
#import "SPVideoScrubber.h"

// View Controllers
#import "SPVideoReel.h"

// Data
#import "ShelbyDataMediator.h"

@interface SPVideoPlayer ()

//djs
//@property (weak, nonatomic) AppDelegate *appDelegate;
//djs
//@property (weak, nonatomic) SPModel *model;
//djs shouldn't care about these..
//@property (weak, nonatomic) SPOverlayView *overlayView;
//@property (weak, nonatomic) SPVideoReel *videoReel;
@property (assign, nonatomic) CGRect viewBounds;
@property (nonatomic) SPShareController *shareController;
@property (nonatomic) AVPlayerLayer *playerLayer;
@property (nonatomic) UIActivityIndicatorView *indicator;

//djs moved from public interface...
@property (nonatomic) AVPlayer *player;
@property (assign, nonatomic) BOOL playbackFinished;
//on reset, this is set to NO which prevents from loading (is reset by -prepareFor...Playback)
@property (assign, nonatomic) BOOL canBecomePlayable;

//djs we don't need this thing anymore
//@property (nonatomic) NSMutableDictionary *videoInformation;
//djs the one bit of it we do need
@property (assign, nonatomic) CMTime lastPlayheadPosition;

/// Setup Methods
- (void)setupInitialConditions;
- (void)setupIndicator;
- (void)setupPlayerForURL:(NSURL *)playerURL;

/// Observer Methods
- (void)itemDidFinishPlaying:(NSNotification *)notification;
- (void)updateBufferProgressView:(NSNumber *)buffered;

@end

@implementation SPVideoPlayer

#pragma mark - Memory Management Methods
- (void)dealloc
{
    [self removeAllObservers];
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
    [self setupInitialConditions];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    //djs not sure about this, haven't done offline stuff, haven't looked into setupIndicator
    if ( ![_videoFrame.video.offlineURL length] ) {
        [self setupIndicator];
    }
}

#pragma mark - Setup Methods

- (void)setupInitialConditions
{
    self.playbackFinished = NO;
    self.isPlayable = NO;
    self.isPlaying = NO;
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
    if(!self.canBecomePlayable){
        // we were reset and never asked to prepareFor...Playback, so don't load a player or do any of that
        return;
    }
    
    // TODO - Uncomment for AppStore ?
    //[[Panhandler sharedInstance] recordEvent];
    
    // Setup player and observers
    AVURLAsset *playerAsset = [AVURLAsset URLAssetWithURL:playerURL options:nil];
    AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithAsset:playerAsset];
    self.player = [[AVPlayer alloc] initWithPlayerItem:playerItem];
    [self addAllObservers];
    
    // Redraw AVPlayer object for placement in UIScrollView on SPVideoReel
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
    CGRect modifiedFrame = CGRectMake(0.0f, 0.0f, self.view.frame.size.width, self.view.frame.size.height);
    self.playerLayer.frame = modifiedFrame;
    self.playerLayer.bounds = modifiedFrame;
    [self.view.layer addSublayer:_playerLayer];
    
    if(CMTIME_IS_VALID(self.lastPlayheadPosition)){
        [self.player seekToTime:self.lastPlayheadPosition];
    }
    
    self.isPlayable = YES;
}

- (void)addAllObservers
{
    // Observe keypaths for buffer states on AVPlayerItem
    [self.player.currentItem addObserver:self forKeyPath:kShelbySPVideoBufferEmpty options:NSKeyValueObservingOptionNew context:nil];
    [self.player.currentItem addObserver:self forKeyPath:kShelbySPVideoBufferLikelyToKeepUp options:NSKeyValueObservingOptionNew context:nil];
    [self.player.currentItem addObserver:self forKeyPath:kShelbySPLoadedTimeRanges options:NSKeyValueObservingOptionNew context:nil];
    
    // Observe for video complete
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(itemDidFinishPlaying:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:self.player.currentItem];
}

- (void)removeAllObservers
{
    [self.player.currentItem removeObserver:self forKeyPath:kShelbySPVideoBufferEmpty];
    [self.player.currentItem removeObserver:self forKeyPath:kShelbySPVideoBufferLikelyToKeepUp];
    [self.player.currentItem removeObserver:self forKeyPath:kShelbySPLoadedTimeRanges];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
}

#pragma mark - Video Storage Methods (Public)
- (NSTimeInterval)availableDuration
{
    if ( [self.player currentItem] ) {
        NSArray *loadedTimeRanges = [self.player.currentItem loadedTimeRanges];
        CMTimeRange timeRange = [[loadedTimeRanges objectAtIndex:0] CMTimeRangeValue];
        CGFloat startSeconds = CMTimeGetSeconds(timeRange.start);
        CGFloat durationSeconds = CMTimeGetSeconds(timeRange.duration);
        NSTimeInterval result = startSeconds + durationSeconds;
        return result;
    }
    return 0.0f;
}

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

- (void)warmVideoExtractionCache
{
    Video *video = self.videoFrame.video;
    [[SPVideoExtractor sharedInstance] warmCacheForVideo:video];
}

- (void)prepareForStreamingPlayback
{
    self.canBecomePlayable = YES;
    
    //if we're already playable, just play
    if(self.isPlayable){
        if (self.shouldAutoplay) {
            [self play];
        }
        return;
    }
    
    //no retain cycle b/c the block's owner (SPVideoExtractor) is not self
    [[SPVideoExtractor sharedInstance] URLForVideo:self.videoFrame.video usingBlock:^(NSString *videoURL) {
        if(videoURL){
            [self setupPlayerForURL:[NSURL URLWithString:videoURL]];
            if (self.shouldAutoplay) {
                [self play];
            }

            if ( [[NSUserDefaults standardUserDefaults] boolForKey:kShelbyDefaultUserIsAdmin] && [[NSUserDefaults standardUserDefaults] boolForKey:kShelbyDefaultOfflineModeEnabled]  ) {
                //djs TODO: this shouldn't go thru app delegate... WTF... create a new fucking manager to handle this
                //[self.appDelegate downloadVideo:video];
            }
        } else {
            //djs TODO handle extraction fail
            // TODO: only scroll to next video if we should autoplay
        }
    } highPriority:YES];
}

- (void)prepareForLocalPlayback
{
    
    self.canBecomePlayable = YES;
    
    //if we're already playable, just play
    if(self.isPlayable){
        if (self.shouldAutoplay) {
            [self play];
        }
        return;
    }

    //djs TODO: ask the OfflineVideoManager for the on-disk URL of this video, use it
    NSString *diskURL = @"TODO";
    [self setupPlayerForURL:[NSURL fileURLWithPath:diskURL]];
}

- (void)resetPlayer
{
    [self pause];
    
    [self removeAllObservers];
    
    [self.playerLayer removeFromSuperlayer];
    self.playerLayer = nil;
    self.player = nil;
    
    self.lastPlayheadPosition = [self elapsedTime];
    self.shouldAutoplay = NO;
    self.isPlayable = NO;
    self.canBecomePlayable = NO; //must be reset by -prepareFor...Playback methods
}

#pragma mark - Video Playback Methods (Public)
- (void)togglePlayback
{
    
    // Send event to Google Analytics
//    id defaultTracker = [GAI sharedInstance].defaultTracker;
//    if ( [sender isMemberOfClass:[UITapGestureRecognizer class]] ) {

        //djs TODO: track this elsewhere
//        [defaultTracker sendEventWithCategory:kGAICategoryVideoPlayer
//                                   withAction:kGAIVideoPlayerActionDoubleTap
//                                    withLabel:[[SPModel sharedInstance].videoReel groupTitle]
//                                    withValue:nil];
        
//    } else if ( [sender isMemberOfClass:[SPVideoReel class]] ) {
    
        
        if ( [self isPlaying] ) {

            //djs TODO: track this elsewhere
//            [defaultTracker sendEventWithCategory:kGAICategoryVideoPlayer
//                                       withAction:kGAIVideoPlayerActionPauseButton
//                                        withLabel:[[SPModel sharedInstance].videoReel groupTitle]
//                                        withValue:nil];
            
        } else {

            //djs TODO: track this elsewhere
//            [defaultTracker sendEventWithCategory:kGAICategoryVideoPlayer
//                                       withAction:kGAIVideoPlayerActionPlayButton
//                                        withLabel:[[SPModel sharedInstance].videoReel groupTitle]
//                                        withValue:nil];
            
        }
        
//    } else {
//        // Do nothing
//    }
    
    // Toggle Playback
    if ( 0.0 == _player.rate && _isPlayable ) { // Play
        [self play];
    } else {
        [self pause];
    }
    
    //djs
//    [[SPModel sharedInstance].videoReel videoDoubleTapped];
}


- (void)play
{
    //djs TODO: should this all be done on the main thread???
    //b/c of how this gets called, it's not necessarily on main thread
    
    [self.player play];
    self.isPlaying = YES;
    
    // Begin updating videoScrubber periodically 
    [[SPVideoScrubber sharedInstance] setupScrubber];
}

- (void)pause
{
    //djs TODO: should this all be done on the main thread???
    //b/c of how this gets called, it's not necessarily on main thread
    
    [self.player pause];
    self.isPlaying = NO;

    //djs do we need this?
    [[SPVideoScrubber sharedInstance] syncScrubber];
}

- (void)share
{
    // TODO - Uncomment for AppStore
//    [[Panhandler sharedInstance] recordEvent];
    
    self.shareController = [[SPShareController alloc] initWithVideoPlayer:self];
    [self.shareController share];
}

- (void)roll
{
    // TODO - Uncomment for AppStore
//    [[Panhandler sharedInstance] recordEvent];
    
    self.shareController = [[SPShareController alloc] initWithVideoPlayer:self];
    [self.shareController showRollView];
}

- (void)itemDidFinishPlaying:(NSNotification *)notification
{
    if ( _player.currentItem == notification.object && ![self playbackFinished]) {
        // Show Restart Button
        [self setPlaybackFinished:YES];
        // Force scroll videoScrollView
        //djs TODO: we should tell the delegate itemDidFinishPlaying, not know about video reel directly
//        [self.videoReel currentVideoDidFinishPlayback];
    }
}

- (void)updateBufferProgressView:(NSNumber *)buffered
{
    //djs TODO: use a delegate
//    if ( buffered.doubleValue > [self.model.overlayView.bufferProgressView progress] ) {
//        [self.model.overlayView.bufferProgressView setProgress:buffered.doubleValue animated:YES];
//    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    //djs TODO: do we really need to know if we're the current player?
    // do we get notifications that we don't want?  It seems somebody thought we did...
    
    if ( ![self.player currentItem] ) {
    
        return;
    
    } else if ( object == _player.currentItem && [keyPath isEqualToString:kShelbySPVideoBufferEmpty] ) {
   
        if ( [self.player currentItem].playbackBufferEmpty) { // Buffer is Empty
        
            [self setupIndicator];
    
        }
   
    } else if ( object == _player.currentItem && [keyPath isEqualToString:kShelbySPVideoBufferLikelyToKeepUp]) {

        //djs
//        if ( [self.player currentItem].playbackLikelyToKeepUp && self == [self.model currentVideoPlayer] ) { // Playback will resume
//
//            // Stop animating indicator
//            if ( [self.indicator isAnimating] ) {
//                [self.indicator stopAnimating];
//                [self.indicator removeFromSuperview];
//                [self play];
//            }
//        }
        
    } else if ( object == _player.currentItem && [keyPath isEqualToString:kShelbySPLoadedTimeRanges] ) {

        //djs i should only observe when i'm current and playing
        
//        if ( self == [self.model currentVideoPlayer] ) {
//         
//            NSTimeInterval availableDuration = [self availableDuration];
//            NSTimeInterval duration = CMTimeGetSeconds([self duration]);
//            NSTimeInterval buffered = availableDuration/duration;
//            [self performSelectorOnMainThread:@selector(updateBufferProgressView:) withObject:[NSNumber numberWithDouble:buffered] waitUntilDone:NO];
//            
//        }
    }
}

#pragma mark - UIResponder Methods
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    //djs
//    [self.model.overlayTimer invalidate];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    //djs
//    [self.model.overlayTimer invalidate];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    //djs
//    [self.model rescheduleOverlayTimer];
}


@end
