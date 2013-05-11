//
//  SPVideoPlayer.m
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 11/1/12.
//  Copyright (c) 2012 Shelby TV. All rights reserved.
//

#import "SPVideoPlayer.h"
#import "SPVideoDownloader.h"
#import "SPVideoExtractor.h"
#import "SPVideoReel.h"

@interface SPVideoPlayer ()

@property (assign, nonatomic) CGRect viewBounds;
@property (nonatomic) AVPlayerLayer *playerLayer;
@property (nonatomic) UIActivityIndicatorView *videoLoadingIndicator;

@property (nonatomic) AVPlayer *player;
//on reset, this is set to NO which prevents from loading (is reset by -prepareFor...Playback)
@property (assign, atomic) BOOL canBecomePlayable;
@property (assign, nonatomic) BOOL isPlayable;
@property (assign, nonatomic) BOOL isPlaying;
@property (assign, nonatomic) CMTime lastPlayheadPosition;
@property (strong, nonatomic) id playerTimeObserver;

@end

@implementation SPVideoPlayer

#pragma mark - Memory Management Methods
- (void)dealloc
{
    _videoPlayerDelegate = nil;
    [self removeAllObservers];
}

- (void)didReceiveMemoryWarning
{
    //see SPVideoReel for memory warning handling
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(itemDidFinishPlaying:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:self.player.currentItem];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(itemPlaybackStalled:)
                                                 name:AVPlayerItemPlaybackStalledNotification
                                               object:self.player.currentItem];
    
    //the only way to observe current time changes
    __weak SPVideoPlayer *weakSelf = self;
    self.playerTimeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(0.25f, NSEC_PER_MSEC)
                                                                        queue:NULL
                                                                   usingBlock:^(CMTime time) {
                                                                       [weakSelf currentTimeUpdated:time];
                                                                   }];
}

- (void)removeAllObservers
{
    STVAssert(!self.isPlayable || self.player, @"SPVideoPlayer should not be playable w/o a player");
    [self.player.currentItem removeObserver:self forKeyPath:kShelbySPVideoBufferEmpty];
    [self.player.currentItem removeObserver:self forKeyPath:kShelbySPVideoBufferLikelyToKeepUp];
    [self.player.currentItem removeObserver:self forKeyPath:kShelbySPLoadedTimeRanges];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemPlaybackStalledNotification object:nil];
    
    [self.player removeTimeObserver:self.playerTimeObserver];
    self.playerTimeObserver = nil;
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
    if ( [self.player currentItem].status != AVPlayerItemStatusFailed ) {
		return [self.player.currentItem duration];
    }
	return kCMTimeInvalid;
}

- (void)warmVideoExtractionCache
{
    Video *video = self.videoFrame.video;
    [[SPVideoExtractor sharedInstance] warmCacheForVideo:video];
}

- (void)prepareForStreamingPlayback
{
    self.canBecomePlayable = YES;

    if(self.isPlayable){
        if (self.shouldAutoplay) {
            [self play];
        }
        return;
    }
    
    [self videoLoadingIndicatorShouldAnimate:YES];
    
    //no retain cycle b/c the block's owner (SPVideoExtractor) is not self
    [[SPVideoExtractor sharedInstance] URLForVideo:self.videoFrame.video usingBlock:^(NSString *videoURL, BOOL wasError) {
        if (!self.canBecomePlayable) {
            //Zombie discussion
            // This video player was reset (and observers removed) while we were waiting
            // This block has the only reference to self (the SPVideoPlayer)
            // If we were to setup player, we would register notifications - don't want to do that!
            // When this block exits, refcount = 0 and self is dealloc'd
            return;
        }
        
        if (videoURL) {
            [self setupPlayerForURL:[NSURL URLWithString:videoURL]];
            if (self.shouldAutoplay) {
                [self play];
            }

            if ( [[NSUserDefaults standardUserDefaults] boolForKey:kShelbyDefaultUserIsAdmin] && [[NSUserDefaults standardUserDefaults] boolForKey:kShelbyDefaultOfflineModeEnabled]  ) {
                //djs TODO: this shouldn't go thru app delegate... WTF... create a new fucking manager to handle this
                //[self.appDelegate downloadVideo:video];
            }
        } else if (wasError) {
            if(self.shouldAutoplay){
                [self.videoPlayerDelegate videoExtractionFailForAutoplayPlayer:self];
            } else {
                /* will try extraction again when we become the current player */
            }
        } else {
            /* extraction was cancelled, do nothing */
        }
    } highPriority:self.shouldAutoplay];
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
    // Keep these three lines first to prevent messages being sent to zombies
    self.canBecomePlayable = NO; //must be reset by -prepareFor...Playback methods
    self.shouldAutoplay = NO;
    [self removeAllObservers];
    
    [self pause];
    self.lastPlayheadPosition = [self elapsedTime];
    self.isPlayable = NO;
    
    [self.playerLayer removeFromSuperlayer];
    self.playerLayer = nil;
    self.player = nil;
}

#pragma mark - Video Playback Methods (Public)
- (void)togglePlayback
{
    if (self.isPlayable && 0.0 == self.player.rate) {
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
    
    [self.videoPlayerDelegate videoDuration:[self duration] forPlayer:self];
    [self.videoPlayerDelegate videoPlaybackStatus:YES forPlayer:self];
}

- (void)pause
{
    //djs TODO: should this all be done on the main thread???
    //b/c of how this gets called, it's not necessarily on main thread
    [self.player pause];
    self.isPlaying = NO;
    
    [self.videoPlayerDelegate videoPlaybackStatus:NO forPlayer:self];
}

- (void)scrubToPct:(CGFloat)scrubPct
{
    if (CMTIME_IS_VALID([self duration])) {
        [self.player seekToTime:CMTimeMultiplyByFloat64([self duration], MAX(0.0,MIN(scrubPct,1.0)))];
    }
}

- (void)itemDidFinishPlaying:(NSNotification *)notification
{
    if ( _player.currentItem == notification.object) {
        [self.videoPlayerDelegate videoDidFinishPlayingForPlayer:self];
    }
}

- (void)itemPlaybackStalled:(NSNotification *)notification
{
    if ( _player.currentItem == notification.object) {
        [self pause];
        //djs TODO: take advantage of this notification, we can make the UX really nice
        DLog(@"PLAYBACK STALLED");
    }
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
        NSArray *loadedTimeRanges = [self.player.currentItem loadedTimeRanges];
        CMTimeRange timeRange = [[loadedTimeRanges objectAtIndex:0] CMTimeRangeValue];
        [self.videoPlayerDelegate videoBufferedRange:timeRange forPlayer:self];
        
    }
}

- (void)currentTimeUpdated:(CMTime)time
{
    [self.videoPlayerDelegate videoCurrentTime:time forPlayer:self];
}

- (void)videoLoadingIndicatorShouldAnimate:(BOOL)animate
{
    [self.videoPlayerDelegate videoLoadingStatus:animate forPlayer:self];
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
