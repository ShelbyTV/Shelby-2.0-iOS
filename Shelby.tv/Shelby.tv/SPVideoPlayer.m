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

@interface SPVideoPlayer ()

//djs shouldn't care about these..
//@property (weak, nonatomic) SPOverlayView *overlayView;
@property (assign, nonatomic) CGRect viewBounds;
@property (nonatomic) SPShareController *shareController;
@property (nonatomic) AVPlayerLayer *playerLayer;
@property (nonatomic) UIActivityIndicatorView *videoLoadingIndicator;

@property (assign, nonatomic) BOOL isPlaying;
@property (assign, nonatomic) BOOL isPlayable;

@property (nonatomic) AVPlayer *player;
@property (assign, nonatomic) BOOL playbackFinished;
//on reset, this is set to NO which prevents from loading (is reset by -prepareFor...Playback)
@property (assign, nonatomic) BOOL canBecomePlayable;
@property (assign, nonatomic) CMTime lastPlayheadPosition;

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
    self.playbackFinished = NO;
    self.isPlayable = NO;
    self.isPlaying = NO;
    self.shouldAutoplay = NO;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
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
    
    [self videoLoadingIndicatorShouldAnimate:YES];
    
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
    if (0.0 == _player.rate && _isPlayable) {
        [self play];
    } else {
        [self pause];
    }
}


- (void)play
{
    //djs TODO: should this all be done on the main thread???
    //b/c of how this gets called, it's not necessarily on main thread
    
    [self.player play];
    self.isPlaying = YES;
    
    // Begin updating videoScrubber periodically
    //djs TODO: is this correct? need to do scrubber stuff...
    [[SPVideoScrubber sharedInstance] setupScrubber];
    
    //djs TODO: tell delegate about playback event
}

- (void)pause
{
    //djs TODO: should this all be done on the main thread???
    //b/c of how this gets called, it's not necessarily on main thread
    
    [self.player pause];
    self.isPlaying = NO;

    //djs do we need this? is this correct?
    [[SPVideoScrubber sharedInstance] syncScrubber];
    
    //djs TODO: tell delegate about playback event
}

// Now done from the SPVideoReel
- (void)share
{
    // TODO - Uncomment for AppStore
//    [[Panhandler sharedInstance] recordEvent];
    
//    self.shareController = [[SPShareController alloc] initWithVideoPlayer:self];
//    [self.shareController share];
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
        self.playbackFinished = YES;
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
    // do we get notifications that we don't want?  It seems somebody thought we did...
    if (![self.player currentItem] || object != [_player currentItem]) {
        return;
        
    } else if ([keyPath isEqualToString:kShelbySPVideoBufferEmpty] && [self.player currentItem].playbackBufferEmpty) {
        [self videoLoadingIndicatorShouldAnimate:YES];
        
    } else if ([keyPath isEqualToString:kShelbySPVideoBufferLikelyToKeepUp] && [self.player currentItem].playbackLikelyToKeepUp) {
        [self videoLoadingIndicatorShouldAnimate:NO];
        
    } else if ([keyPath isEqualToString:kShelbySPLoadedTimeRanges]) {
        //djs XXX: we used to check to make sure this player was the current player
        //is that b/c we were glitching when other players got switched in?
        //if so, SPVideoReel can maintain a isCurrentPlayer on us
        NSTimeInterval availableDuration = [self availableDuration];
        NSTimeInterval duration = CMTimeGetSeconds([self duration]);
        NSTimeInterval buffered = availableDuration/duration;
        [self performSelectorOnMainThread:@selector(updateBufferProgressView:) withObject:[NSNumber numberWithDouble:buffered] waitUntilDone:NO];
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

- (void)videoLoadingIndicatorShouldAnimate:(BOOL)animate
{
    if(!self.videoLoadingIndicator){
        CGRect modifiedFrame = CGRectMake(0.0f, 0.0f, self.view.frame.size.width, self.view.frame.size.height);
        self.videoLoadingIndicator = [[UIActivityIndicatorView alloc] initWithFrame:modifiedFrame];
        self.videoLoadingIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
        self.videoLoadingIndicator.hidesWhenStopped = YES;
        [self.view addSubview:self.videoLoadingIndicator];
    }
    if(animate){
        [self.videoLoadingIndicator startAnimating];
    } else {
        [self.videoLoadingIndicator stopAnimating];
    }
}

@end
