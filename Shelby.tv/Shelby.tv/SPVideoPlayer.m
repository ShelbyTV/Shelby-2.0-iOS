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
#import "ShelbyErrorUtility.h"
#import "SPVideoDownloader.h"
#import "SPVideoExtractor.h"
#import "SPVideoReel.h"
#import "VideoPlayerThumbnailOverlayView.h"

#define PLAYBACK_API_UPDATE_INTERVAL 15.f

NSString * const kShelbySPVideoExternalPlaybackActiveKey = @"externalPlaybackActive";
NSString * const kShelbySPVideoCurrentItemKey = @"currentItem";
NSString * const kShelbySPVideoPlayerRate = @"rate";
NSString * const kShelbySPVideoAirplayDidBegin = @"spAirplayDidBegin";
NSString * const kShelbySPVideoAirplayDidEnd = @"spAirplayDidEnd";

@interface SPVideoPlayer () {
    CGFloat _rateBeforeScrubbing;
    CMTime _lastPlaybackUpdateIntervalEnd;
}

@property (nonatomic) AVPlayerLayer *playerLayer;
@property (nonatomic) UIActivityIndicatorView *videoLoadingIndicator;
@property (nonatomic, strong) VideoPlayerThumbnailOverlayView *thumbnailView;

@property (nonatomic) AVPlayer *player;
//on reset, this is set to NO which prevents from loading (is reset by -prepareFor...Playback)
@property (assign, atomic) BOOL canBecomePlayable;
@property (assign, nonatomic) BOOL isPlayable;
@property (assign, nonatomic) BOOL isPlaying;
@property (assign, nonatomic) BOOL isScrubbing;
@property (assign, nonatomic) CMTime lastPlayheadPosition;
@property (strong, nonatomic) id playerTimeObserver;

//constraints for re-positioning by parent
@property (nonatomic, strong) NSLayoutConstraint *constrainLeading;
@property (nonatomic, strong) NSLayoutConstraint *constrainTrailing;
@property (nonatomic, strong) NSLayoutConstraint *constrainTop;
@property (nonatomic, strong) NSLayoutConstraint *constrainBottom;
@property (nonatomic, strong) NSLayoutConstraint *constrainWidth;
@property (nonatomic, strong) NSLayoutConstraint *constrainHeight;

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

#pragma mark - View Lifecycle Methods
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.isPlayable = NO;
    self.isPlaying = NO;
    self.isScrubbing = NO;
    self.shouldAutoplay = NO;
    
    if (DEVICE_IPAD) {
        [self setupThumbnailOverlay];
    }
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

/* View could have been positioned with frame and allowed to translate autoresize mask into constraints.
 * But in practice, this is incredibly inefficient as the constraints are recalculated
 * in a naieve way.  By setting up constraints ourselves, we can be smarter.
 *
 * NB: Would be 100x better to have just used a CollectionView instead of doing all
 * this crap manually.
 */
- (void)setConstraintsForSuperviewWidthAndOtherwiseEquivalentToFrame:(CGRect)f
{
    //height is local to view (doesn't change when set)
    if (!self.constrainHeight) {
        self.constrainHeight = [NSLayoutConstraint constraintWithItem:self.view
                                                            attribute:NSLayoutAttributeHeight
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:nil attribute:NSLayoutAttributeNotAnAttribute
                                                           multiplier:1.0
                                                             constant:f.size.height];
        [self.view addConstraint:self.constrainHeight];
    }
    self.constrainHeight.constant = f.size.height;
    
    //width is relative to superview and constant (grows and shrinks on iPad)
    if (!self.constrainWidth) {
        self.constrainWidth = [NSLayoutConstraint constraintWithItem:self.view
                                                           attribute:NSLayoutAttributeWidth
                                                           relatedBy:NSLayoutRelationEqual
                                                              toItem:self.view.superview
                                                           attribute:NSLayoutAttributeWidth
                                                          multiplier:1.0
                                                            constant:0];
        [self.view.superview addConstraint:self.constrainWidth];
    }
    
    //position is relative to superview (has to tie to all four walls)
    if (!self.constrainLeading) {
        self.constrainLeading = [NSLayoutConstraint constraintWithItem:self.view
                                                             attribute:NSLayoutAttributeLeading
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:self.view.superview
                                                             attribute:NSLayoutAttributeLeading
                                                            multiplier:1.0
                                                              constant:f.origin.x];
        [self.view.superview addConstraint:self.constrainLeading];
    }
    self.constrainLeading.constant = f.origin.x;
    
    if (!self.constrainTop) {
        self.constrainTop = [NSLayoutConstraint constraintWithItem:self.view
                                                         attribute:NSLayoutAttributeTop
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self.view.superview
                                                         attribute:NSLayoutAttributeTop
                                                        multiplier:1.0
                                                          constant:f.origin.y];
        [self.view.superview addConstraint:self.constrainTop];
    }
    self.constrainTop.constant = f.origin.y;
}

- (void)setupPlayerForURL:(NSURL *)playerURL
{
    if(!self.canBecomePlayable){
        // we were reset and never asked to prepareFor...Playback, so don't load a player or do any of that
        return;
    }
    
    // Setup player and observers
    AVURLAsset *playerAsset = [AVURLAsset URLAssetWithURL:playerURL options:nil];
    AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithAsset:playerAsset];
    if (self.player) {
        if (!self.player.isExternalPlaybackActive) {
            //Timing edge cases can get us here, even when not in AirPlay mode
            //This is okay so long as we're setting the same URL as we already set in the player
            STVDebugAssert([((AVURLAsset *)self.player.currentItem.asset).URL isEqual:playerAsset.URL], @"expected same URL");
            return;
        }

        //reuse player
        self.lastPlayheadPosition = CMTimeMake(0, NSEC_PER_MSEC);
        [self.player replaceCurrentItemWithPlayerItem:playerItem];
        //replacement happens asynchronously.
        //we remove & add observers via KVO on self.player.currentItem and autoplay when adding if applicable

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
        if (DEVICE_IPAD) {
            self.playerLayer.hidden = YES;
        }

        if(CMTIME_IS_VALID(self.lastPlayheadPosition)){
            [self.player seekToTime:self.lastPlayheadPosition];
        }
    }
    
    self.isPlayable = YES;
    
    if (DEVICE_IPAD) {
        //iPad has a thumbnail overlay
        [self.view addSubview:self.thumbnailView];
        self.thumbnailView.video = self.videoFrame.video;
    }
}

- (void)playerItemReplaced:(NSDictionary *)change
{
    AVPlayerItem *oldPlayerItem = change[NSKeyValueChangeOldKey];
    if ((id)oldPlayerItem != [NSNull null]) {
        [self removePlayerItemObservers:oldPlayerItem];
    }

    AVPlayerItem *newPlayerItem = change[NSKeyValueChangeNewKey];
    if ((id)newPlayerItem != [NSNull null]) {
        [self addPlayerItemObservers];
        if (self.shouldAutoplay) {
            [self play];
        }
    } else {
        //This happens when an unplayable AVAsset is set on the player
        //it gets removed and replaced with NSNull
        self.isPlayable = NO;
        if (self.shouldAutoplay) {
            [self.videoPlayerDelegate videoExtractionFailForAutoplayPlayer:self];
        }
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
                     options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew)
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
    [self.player addObserver:self forKeyPath:kShelbySPVideoPlayerRate options:NSKeyValueObservingOptionNew context:nil];


    // Observe keypaths for buffer states on AVPlayerItem
    [self.player.currentItem addObserver:self forKeyPath:kShelbySPVideoBufferEmpty options:NSKeyValueObservingOptionNew context:nil];
    [self.player.currentItem addObserver:self forKeyPath:kShelbySPVideoBufferLikelyToKeepUp options:NSKeyValueObservingOptionNew context:nil];
    [self.player.currentItem addObserver:self forKeyPath:kShelbySPLoadedTimeRanges options:NSKeyValueObservingOptionNew context:nil];
    [self.player.currentItem addObserver:self forKeyPath:kShelbySPAVPlayerDuration options:NSKeyValueObservingOptionNew context:nil];
    [self.player.currentItem addObserver:self forKeyPath:kShelbySPAVPlayerStatus options:NSKeyValueObservingOptionNew context:nil];

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

    [self removePlayerItemObservers:self.player.currentItem];

    [self.player removeObserver:self forKeyPath:kShelbySPVideoExternalPlaybackActiveKey];
    [self.player removeObserver:self forKeyPath:kShelbySPVideoCurrentItemKey];
}

- (void)removePlayerItemObservers:(AVPlayerItem *)playerItem
{
    //NB: this is technically observing player, but needs to be in sync w/ playerItem
    if (self.playerTimeObserver) {
        [self.player removeTimeObserver:self.playerTimeObserver];
        self.playerTimeObserver = nil;
        [self.player removeObserver:self forKeyPath:kShelbySPVideoPlayerRate];
    }

    if (playerItem && (id)playerItem != [NSNull null]) {
        [playerItem removeObserver:self forKeyPath:kShelbySPVideoBufferEmpty];
        [playerItem removeObserver:self forKeyPath:kShelbySPVideoBufferLikelyToKeepUp];
        [playerItem removeObserver:self forKeyPath:kShelbySPLoadedTimeRanges];
        [playerItem removeObserver:self forKeyPath:kShelbySPAVPlayerDuration];
        [playerItem removeObserver:self forKeyPath:kShelbySPAVPlayerStatus];
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
    [[SPVideoExtractor sharedInstance] URLForVideo:self.videoFrame.video usingBlock:^(NSString *videoURL, NSError *error) {
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

        } else if (error) {
            if ([ShelbyErrorUtility isConnectionError:error]) {
                // Do nothing. No Internet Connection
            } else if(self.shouldAutoplay){
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
    STVDebugAssert([NSThread isMainThread], @"expecting to be called on main thread");
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
        
        [self resetUI];
    }
}

- (void)resetUI
{
    self.playerLayer.hidden = YES;
    self.thumbnailView.alpha = 1.f;
}

#pragma mark - Video Playback Methods (Public)

- (BOOL)shouldBePlaying
{
    return self.canBecomePlayable && (self.isPlaying || self.shouldAutoplay);
}

- (BOOL)isShowingPlayerLayer
{
    return self.playerLayer && !self.playerLayer.hidden;
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
    if (DEVICE_IPAD && self.player.status == AVPlayerItemStatusReadyToPlay) {
        [UIView animateWithDuration:0.25 animations:^{
            self.playerLayer.hidden = NO;
            self.thumbnailView.alpha = 0.f;
        }];
    }
    
    [self.player play];
    self.isPlaying = YES;
    
    [self.videoPlayerDelegate videoDuration:[self duration] forPlayer:self];
    [self.videoPlayerDelegate videoPlaybackStatus:YES forPlayer:self];
}

- (void)pause
{
    self.isPlaying = NO;
    self.shouldAutoplay = NO;
    [self.player pause];
    
    [self.videoPlayerDelegate videoPlaybackStatus:NO forPlayer:self];
}

- (void)beginScrubbing
{
    self.isScrubbing = YES;
    _rateBeforeScrubbing = self.player.rate;
    self.player.rate = 0.f;
}

- (void)endScrubbing
{
    self.isScrubbing = NO;
    self.player.rate = _rateBeforeScrubbing;
}

- (void)scrubToPct:(CGFloat)scrubPct
{
    if (CMTIME_IS_VALID([self duration])) {
        CMTime seekTo = CMTimeMultiplyByFloat64([self duration], MAX(0.0,MIN(scrubPct,1.0)));
        if (CMTIME_IS_VALID(seekTo) && !CMTIME_IS_INDEFINITE(seekTo)) {
            [self.player seekToTime:seekTo];
            _lastPlaybackUpdateIntervalEnd = seekTo;
        }
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
            if (change[NSKeyValueChangeNewKey] || change[NSKeyValueChangeOldKey]) {
                [self performSelectorOnMainThread:@selector(playerItemReplaced:)
                                       withObject:change
                                    waitUntilDone:YES];
            }
        } else if ([keyPath isEqualToString:kShelbySPVideoPlayerRate]) {
            if ([self shouldBePlaying] && !self.isScrubbing && self.player.rate == 0.f) {
                //we should be playing!
                [self play];
            }
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

    } else if ([keyPath isEqualToString:kShelbySPAVPlayerStatus]) {
        if ([change[NSKeyValueChangeNewKey] isEqual:@(AVPlayerItemStatusReadyToPlay)]) {
            if (self.shouldBePlaying) {
                [UIView animateWithDuration:0.25 animations:^{
                    self.playerLayer.hidden = NO;
                    self.thumbnailView.alpha = 0.f;
                }];
            }
            
        } else if ([change[NSKeyValueChangeNewKey] isEqual:@(AVPlayerItemStatusFailed)]) {
            //XXX so far this seems to be the correct thing to do
            //    (ie. haven't seen Fail unless you have no connection)
            [[NSNotificationCenter defaultCenter] postNotificationName:kShelbyNoInternetConnectionNotification object:nil];
        }
    }
}

- (void)currentTimeUpdated:(CMTime)time
{
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
        self.videoLoadingIndicator.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin |
                                                       UIViewAutoresizingFlexibleRightMargin |
                                                       UIViewAutoresizingFlexibleTopMargin |
                                                       UIViewAutoresizingFlexibleBottomMargin);
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

#pragma mark - Thumbnail Helpers

- (void)setupThumbnailOverlay
{
    STVDebugAssert(!self.thumbnailView);
    
    self.thumbnailView = [[[NSBundle mainBundle] loadNibNamed:@"VideoPlayerThumbnailOverlayView" owner:self options:nil] firstObject];
    [self.view addSubview:self.thumbnailView];
    self.thumbnailView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[thumb(500)]"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:@{@"thumb":self.thumbnailView}]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[thumb(250)]"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:@{@"thumb":self.thumbnailView}]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.thumbnailView
                                                          attribute:NSLayoutAttributeCenterX
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeCenterX
                                                         multiplier:1.0
                                                           constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.thumbnailView
                                                          attribute:NSLayoutAttributeCenterY
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeCenterY
                                                         multiplier:1.0
                                                           constant:0]];
    
    UITapGestureRecognizer *thumbnailTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(thumbnailTapped:)];
    [self.thumbnailView addGestureRecognizer:thumbnailTap];
}

- (void)thumbnailTapped:(UITapGestureRecognizer *)gestureRecognizer
{
    [ShelbyAnalyticsClient sendLocalyticsEvent:kLocalyticsTapVideoPlayerOverlayPlay];
    [self.videoPlayerDelegate videoThumbnailTappped:self];
}

@end
