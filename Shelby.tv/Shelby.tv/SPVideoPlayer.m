//
//  SPVideoPlayer.m
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 11/1/12.
//  Copyright (c) 2012 Shelby TV. All rights reserved.
//

#import "SPVideoPlayer.h"

#import <AVFoundation/AVFoundation.h>
#import "ShelbyAPIClient.h"
#import "SPVideoDownloader.h"
#import "SPVideoExtractor.h"
#import "SPVideoReel.h"

#define PLAYBACK_API_UPDATE_INTERVAL 15.f

static Frame *currentPlayingVideoFrame;

NSString * const kShelbySPVideoExternalPlaybackActiveKey = @"externalPlaybackActive";
NSString * const kShelbySPVideoCurrentItemKey = @"currentItem";
NSString * const kShelbySPVideoAirplayDidBegin = @"spAirplayDidBegin";
NSString * const kShelbySPVideoAirplayDidEnd = @"spAirplayDidEnd";
NSString * const kShelbySPVideoPlayerCurrentPlayingVideoChanged = @"kShelbySPVideoPlayerCurrentPlayingVideoChanged";


@interface SPVideoPlayer () {
    CGFloat _rateBeforeScrubbing;
    CMTime _lastPlaybackUpdateIntervalEnd;
}

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
- (id)initWithVideoFrame:(Frame *)videoFrame
{
    self = [super init];
    if (self) {
        _lastPlaybackUpdateIntervalEnd = CMTimeMake(0, NSEC_PER_MSEC);
        _videoFrame = videoFrame;
        _rateBeforeScrubbing = 0.f;
    }
    
    return self;
}

+ (Video *)currentPlayingVideo
{
    return [currentPlayingVideoFrame video];
}

#pragma mark - View Lifecycle Methods
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.isPlayable = NO;
    self.isPlaying = NO;
    self.shouldAutoplay = NO;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskLandscape | UIInterfaceOrientationMaskPortrait;
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (void)viewDidLayoutSubviews
{
    //laying out subviews doesn't change bounds of sublayers...
    //so we need to update bounds & position of AVPlayerLayer
    self.playerLayer.bounds = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    self.playerLayer.position = CGPointMake(self.view.frame.size.width/2.f, self.view.frame.size.height/2.f);
}

- (void)setupPlayerForURL:(NSURL *)playerURL
{
    if(!self.canBecomePlayable){
        // we were reset and never asked to prepareFor...Playback, so don't load a player or do any of that
        return;
    }

    if (self.player) {
        //remove old player item observers before changing the player item (and observing the new player item)
        [self removePlayerItemObservers];
    }
    
    // Setup player and observers
    AVURLAsset *playerAsset = [AVURLAsset URLAssetWithURL:playerURL options:nil];
    AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithAsset:playerAsset];
    if (self.player) {
        STVDebugAssert(self.player.isExternalPlaybackActive, @"only expecting reuse w/ airplay");
        //reuse player
        self.lastPlayheadPosition = CMTimeMake(0, NSEC_PER_MSEC);
        [self.player replaceCurrentItemWithPlayerItem:playerItem];
        //replacement happens asynchronously.
        //we add observers via KVO on self.player.currentItem and autoplay then

    } else {
        //new player
        self.player = [[AVPlayer alloc] initWithPlayerItem:playerItem];
        [self addAllObservers];

        //to maintain connection as best as possible w/ AirPlay (mirroring or not)
        self.player.usesExternalPlaybackWhileExternalScreenIsActive = YES;
        self.player.actionAtItemEnd = AVPlayerActionAtItemEndPause;

        // Redraw AVPlayer object for placement in UIScrollView on SPVideoReel
        self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
        //NB default anchorPoint is (0.5, 0.5)
        self.playerLayer.bounds = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
        self.playerLayer.position = CGPointMake(self.view.frame.size.width/2.f, self.view.frame.size.height/2.f);

        [self.view.layer addSublayer:self.playerLayer];

        if(CMTIME_IS_VALID(self.lastPlayheadPosition)){
            [self.player seekToTime:self.lastPlayheadPosition];
        }
    }
    
    self.isPlayable = YES;
}

- (void)playerItemReplaced
{
    DLog(@"Player Item Replaced allows?%@  uses?%@ status?%ld", self.player.allowsExternalPlayback ? @"YES":@"NO", self.player.usesExternalPlaybackWhileExternalScreenIsActive ? @"YES":@"NO", (long)_player.status);
    [self addPlayerItemObservers];
    if (self.shouldAutoplay) {
        DLog(@"AUTOPLAYING, rate is: %f", self.player.rate);
        [self play];
        DLog(@"did autoplay, rate is: %f", self.player.rate);
    }
}

- (void)addAllObservers
{
    [self addPlayerItemObservers];

    //air play
    [self.player addObserver:self
                  forKeyPath:kShelbySPVideoExternalPlaybackActiveKey
                     options:NSKeyValueObservingOptionNew
                     context:nil];
    [self.player addObserver:self
                  forKeyPath:kShelbySPVideoCurrentItemKey
                     options:NSKeyValueObservingOptionNew
                     context:nil];
}

- (void)addPlayerItemObservers
{
    //the only way to observe current time changes
    //NB: important to change this when playerItem changes
    __weak SPVideoPlayer *weakSelf = self;
    self.playerTimeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(0.25f, NSEC_PER_MSEC)
                                                                        queue:NULL
                                                                   usingBlock:^(CMTime time) {
                                                                       [weakSelf currentTimeUpdated:time];
                                                                   }];


    // Observe keypaths for buffer states on AVPlayerItem
    [self.player.currentItem addObserver:self forKeyPath:kShelbySPVideoBufferEmpty options:NSKeyValueObservingOptionNew context:nil];
    [self.player.currentItem addObserver:self forKeyPath:kShelbySPVideoBufferLikelyToKeepUp options:NSKeyValueObservingOptionNew context:nil];
    [self.player.currentItem addObserver:self forKeyPath:kShelbySPLoadedTimeRanges options:NSKeyValueObservingOptionNew context:nil];
    [self.player.currentItem addObserver:self forKeyPath:kShelbySPAVPlayerDuration options:NSKeyValueObservingOptionNew context:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(itemDidFinishPlaying:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:self.player.currentItem];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(itemPlaybackStalled:)
                                                 name:AVPlayerItemPlaybackStalledNotification
                                               object:self.player.currentItem];
}

- (void)removeAllObservers
{
    STVDebugAssert(!self.isPlayable || self.player, @"SPVideoPlayer should not be playable w/o a player");

    [self removePlayerItemObservers];

    [self.player removeObserver:self forKeyPath:kShelbySPVideoExternalPlaybackActiveKey];
    [self.player removeObserver:self forKeyPath:kShelbySPVideoCurrentItemKey];
}

- (void)removePlayerItemObservers
{
    //NB: this is technically observing player, but needs to be in sync w/ playerItem
    [self.player removeTimeObserver:self.playerTimeObserver];
    self.playerTimeObserver = nil;

    if (self.player.currentItem) {
        [self.player.currentItem removeObserver:self forKeyPath:kShelbySPVideoBufferEmpty];
        [self.player.currentItem removeObserver:self forKeyPath:kShelbySPVideoBufferLikelyToKeepUp];
        [self.player.currentItem removeObserver:self forKeyPath:kShelbySPLoadedTimeRanges];
        [self.player.currentItem removeObserver:self forKeyPath:kShelbySPAVPlayerDuration];
    }

    [[NSNotificationCenter defaultCenter] removeObserver:self];
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

    //if we are in external playback mode, a single player gets reused
    //otherwise, we may have been warmed up and don't need to extract
    if(!self.player.isExternalPlaybackActive && self.isPlayable){
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
            BOOL hadExistingPlayer = (self.player != nil);
            [self setupPlayerForURL:[NSURL URLWithString:videoURL]];
            if (hadExistingPlayer) {
                //don't play until async item replacement happens, see -[playerItemReplaced]
            } else {
                if (self.shouldAutoplay) {
                    [self play];
                }
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
    if (!self.player.isExternalPlaybackActive) {
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

        _lastPlaybackUpdateIntervalEnd = CMTimeMake(0, NSEC_PER_MSEC);
    }
}

#pragma mark - Video Playback Methods (Public)

- (BOOL)shouldBePlaying
{
    return self.isPlayable && (self.isPlaying || self.shouldAutoplay);
}

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
    currentPlayingVideoFrame = self.videoFrame;
    [self.player play];
    self.isPlaying = YES;
    
    [self.videoPlayerDelegate videoDuration:[self duration] forPlayer:self];
    [self.videoPlayerDelegate videoPlaybackStatus:YES forPlayer:self];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kShelbySPVideoPlayerCurrentPlayingVideoChanged object:nil];
}

- (void)pause
{
    //djs TODO: should this all be done on the main thread???
    //b/c of how this gets called, it's not necessarily on main thread
    [self.player pause];
    self.isPlaying = NO;
    self.shouldAutoplay = NO;
    
    [self.videoPlayerDelegate videoPlaybackStatus:NO forPlayer:self];
}

- (void)beginScrubbing
{
    _rateBeforeScrubbing = self.player.rate;
    self.player.rate = 0.f;
}

- (void)endScrubbing
{
    self.player.rate = _rateBeforeScrubbing;
}

- (void)scrubToPct:(CGFloat)scrubPct
{
    if (CMTIME_IS_VALID([self duration])) {
        CMTime seekTo = CMTimeMultiplyByFloat64([self duration], MAX(0.0,MIN(scrubPct,1.0)));
        [self.player seekToTime:seekTo];
        _lastPlaybackUpdateIntervalEnd = seekTo;
    }
}

- (void)itemDidFinishPlaying:(NSNotification *)notification
{
    if (_player.currentItem != notification.object) {
        STVDebugAssert(_player.currentItem == notification.object, @"should only get notified for our player item");
        return;
    }

    if (self.isPlaying && self.player.currentItem.status == AVPlayerItemStatusReadyToPlay) {
        //actionAtItemEnd is set to "pause" when we create player.  track that:
        self.isPlaying = NO;
        [self sendWatchToAPIFrom:_lastPlaybackUpdateIntervalEnd to:self.duration complete:YES];
        [self.videoPlayerDelegate videoDidFinishPlayingForPlayer:self];
    }
}

- (void)itemPlaybackStalled:(NSNotification *)notification
{
    if ( _player.currentItem == notification.object) {
        [self.videoPlayerDelegate videoDidStallForPlayer:self];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (self.player == object) {
        if ([keyPath isEqualToString:kShelbySPVideoExternalPlaybackActiveKey]) {
            if (self.player.externalPlaybackActive) {
                [[NSNotificationCenter defaultCenter] postNotificationName:kShelbySPVideoAirplayDidBegin object:self];
            } else {
                [[NSNotificationCenter defaultCenter] postNotificationName:kShelbySPVideoAirplayDidEnd object:self];
            }
        } else if ([keyPath isEqualToString:kShelbySPVideoCurrentItemKey]) {
            //item replacement not guaranteed to be called on same thread that registered for KVO
            dispatch_async(dispatch_get_main_queue(), ^{
                [self playerItemReplaced];
            });
        }
        return;
    }

    // do we get notifications that we don't want?  It seems somebody thought we did...
    if (![self.player currentItem] || object != [_player currentItem]) {
        return;
        
    } else if ([keyPath isEqualToString:kShelbySPVideoBufferEmpty] && [self.player currentItem].playbackBufferEmpty) {
        [self videoLoadingIndicatorShouldAnimate:YES];
        
    } else if ([keyPath isEqualToString:kShelbySPVideoBufferLikelyToKeepUp] && [self.player currentItem].playbackLikelyToKeepUp) {
        [self videoLoadingIndicatorShouldAnimate:NO];
        
    } else if ([keyPath isEqualToString:kShelbySPLoadedTimeRanges]) {
        NSArray *loadedTimeRanges = [self.player.currentItem loadedTimeRanges];
        if (loadedTimeRanges && [loadedTimeRanges count]) {
            CMTimeRange timeRange = [loadedTimeRanges[0] CMTimeRangeValue];
            [self.videoPlayerDelegate videoBufferedRange:timeRange forPlayer:self];
        }
        
    } else if ([keyPath isEqualToString:kShelbySPAVPlayerDuration]) {
        [self.videoPlayerDelegate videoDuration:[self duration] forPlayer:self];

    }
}

- (void)currentTimeUpdated:(CMTime)time
{
    if(!self.isPlaying){
        // This will happen a few times immediatley after pause, but that's innocuous.
        // This is not a reliable way to detect/prevent issues like double-playback.
        // -djs
    }
    [self.videoPlayerDelegate videoCurrentTime:time forPlayer:self];

    if (CMTimeGetSeconds(CMTimeSubtract(time, _lastPlaybackUpdateIntervalEnd)) > PLAYBACK_API_UPDATE_INTERVAL) {
        [self sendWatchToAPIFrom:_lastPlaybackUpdateIntervalEnd to:time complete:NO];
    }
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

- (void)sendWatchToAPIFrom:(CMTime)fromTime to:(CMTime)toTime complete:(BOOL)complete
{
    NSInteger from = (NSInteger)CMTimeGetSeconds(fromTime);
    NSInteger to = (NSInteger)CMTimeGetSeconds(toTime);
    [ShelbyAPIClient postUserWatchedFrame:self.videoFrame.frameID
                               completely:complete
                                     from:[NSString stringWithFormat:@"%01d", from]
                                       to:[NSString stringWithFormat:@"%01d", to]];
    _lastPlaybackUpdateIntervalEnd = toTime;
}

@end
