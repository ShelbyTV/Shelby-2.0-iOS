//
//  SPVideoReelCollectionViewController.m
//  Shelby.tv
//
//  Created by Dan Spinosa on 3/6/14.
//  Copyright (c) 2014 Shelby TV, Inc. All rights reserved.
//

#import "SPVideoReelCollectionViewController.h"
#import "DeviceUtilities.h"
#import "ShelbyAlert.h"
#import "ShelbyVideoReelCollectionViewCell.h"
#import "SPVideoExtractor.h"
#import "SPVideoPlayer.h"
#import "UIScreen+Resolution.h"
#import "VideoReelBackdropView.h"

//only show the stalled alert view if it hasn't shown in this much time
NSInteger const kVideoStalledMinTimeBetweenAlerts = -60; //1m

typedef NS_ENUM(NSInteger, SPVideoReelCollectionPreloadStrategy) {
    SPVideoReelCollectionPreloadStrategyNotSet          = -1,
    SPVideoReelCollectionPreloadNone                    = 0,
    SPVideoReelCollectionPreloadNextOnly                = 1,
    SPVideoReelCollectionPreloadNextKeepPrevious        = 2,
    SPVideoReelCollectionPreloadNextTwoKeepPrevious     = 3,
};

static SPVideoReelCollectionPreloadStrategy preloadStrategy = SPVideoReelCollectionPreloadStrategyNotSet;

@interface SPVideoReelCollectionViewController ()
@property (nonatomic, strong) UICollectionViewFlowLayout *flowLayout;
@property (nonatomic, strong) NSMutableDictionary *players;
@property (nonatomic, weak) SPVideoPlayer *currentPlayer;
@property (nonatomic, strong) NSIndexPath *currentPlayersIndexPath;
@property (nonatomic, weak) NSTimer *playerManagementTimer;
//state
@property (nonatomic, strong) NSIndexPath *lastRequestedScrollToIndexPath;
@property (nonatomic, assign) BOOL shouldBePlaying;
@property (nonatomic, assign) BOOL isShutdown;
//alerts
@property (nonatomic, strong) ShelbyAlert *currentVideoAlertView;
@property (nonatomic, strong) NSDate *lastVideoStalledAlertTime;
@end

@implementation SPVideoReelCollectionViewController

- (id)init
{
    self = [super initWithCollectionViewLayout:[UICollectionViewFlowLayout new]];
    if (self) {
        _flowLayout = (UICollectionViewFlowLayout *)self.collectionViewLayout;
        _shouldBePlaying = NO;
        _isShutdown = NO;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupVideoPreloadStrategy];
    
    self.players = [NSMutableDictionary new];
    
    self.collectionView.pagingEnabled = YES;
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    self.collectionView.backgroundColor = [UIColor clearColor];
    
    [self.collectionView registerNib:[UINib nibWithNibName:@"ShelbyVideoReelCollectionViewCell" bundle:nil]
          forCellWithReuseIdentifier:kShelbyVideoReelCollectionViewCellReuseId];
    
    self.flowLayout.minimumLineSpacing = 0.f;
    self.flowLayout.minimumInteritemSpacing = 0.f;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    //TODO: this has to change when we rotate (does viewWillLayoutSubviews take care of that?)
    self.flowLayout.itemSize = self.collectionView.bounds.size;
}

- (void)viewWillLayoutSubviews
{
    [self.flowLayout invalidateLayout];
    self.flowLayout.itemSize = self.collectionView.bounds.size;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    [self degradeVideoPreloadStrategy];
    [self manageLoadedVideoPlayersForCurrentPlayer:self.currentPlayer];
}

#pragma mark - Setters & Getters

- (void)setDeduplicatedEntries:(NSArray *)deduplicatedEntries
{
    if (![_deduplicatedEntries isEqualToArray:deduplicatedEntries]) {
        _deduplicatedEntries = [deduplicatedEntries copy];
        
        //TODO: other smart stuff?  or does the currently displayed cell just sit there?
        [self.collectionView reloadData];
    }
}

- (void)setCurrentPlayersIndexPath:(NSIndexPath *)currentPlayersIndexPath
{
    if (_currentPlayersIndexPath != currentPlayersIndexPath) {
        _currentPlayersIndexPath = currentPlayersIndexPath;
        
        self.currentPlayer = [self playerForIndexPath:self.currentPlayersIndexPath];
    }
}

- (void)setCurrentPlayer:(SPVideoPlayer *)currentPlayer
{
    if (_currentPlayer != currentPlayer) {
        _currentPlayer = currentPlayer;
        
        id<ShelbyVideoContainer> entity = self.deduplicatedEntries[self.currentPlayersIndexPath.row];
        STVDebugAssert([Frame frameForEntity:entity] == self.currentPlayer.videoFrame);
        
        //configure current player
        _currentPlayer.shouldAutoplay = self.shouldBePlaying;
        if (!self.shouldBePlaying) {
            self.backdropView.showBackdropImage = YES;
            [_currentPlayer resetUI];
        }
        [_currentPlayer prepareForStreamingPlayback];
        
        //pre-cache future players and URLs
        [self manageLoadedVideoPlayersForCurrentPlayer:_currentPlayer];
        [self warmURLExtractionCache];
        
        //let the world know
        [[NSNotificationCenter defaultCenter] postNotificationName:kShelbyPlaybackEntityDidChangeNotification
                                                            object:self
                                                          userInfo:@{kShelbyPlaybackCurrentEntityKey : entity,
                                                                     kShelbyPlaybackCurrentChannelKey : self.channel}];
    }
}

#pragma mark - Primary API

- (void)scrollForPlaybackAtIndex:(NSUInteger)idx forcingPlayback:(BOOL)forcePlaybackEvenIfPaused animated:(BOOL)animatedScroll
{
    self.lastRequestedScrollToIndexPath = [NSIndexPath indexPathForRow:idx inSection:0];
    
    self.shouldBePlaying |= forcePlaybackEvenIfPaused;
    
    if ([self.currentPlayersIndexPath isEqual:self.lastRequestedScrollToIndexPath] && self.shouldBePlaying) {
        //asked to play the currently focused video, just play
        [self playCurrentPlayer];
        return;
    }
    
    //Cold Start?
    if (!self.currentPlayersIndexPath) {
        self.currentPlayersIndexPath = self.lastRequestedScrollToIndexPath;
        //above sets & sets up current player, sends notifications
    }
    
    [self.collectionView scrollToItemAtIndexPath:self.lastRequestedScrollToIndexPath
                                atScrollPosition:UICollectionViewScrollPositionCenteredVertically
                                        animated:animatedScroll];
}

- (void)playCurrentPlayer
{
    self.shouldBePlaying = YES;
    [self.currentPlayer play];
    // prevent display from sleeping while watching video
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
}

- (BOOL)isCurrentPlayerPlaying
{
    return [self.currentPlayer isPlaying];
}

- (void)pauseCurrentPlayer
{
    self.shouldBePlaying = NO;
    [self.currentPlayer pause];
    // allow display to sleep
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
}

- (void)beginScrubbing
{
    [self.currentPlayer beginScrubbing];
}

- (void)scrubCurrentPlayerTo:(CGFloat)pct
{
    [self.currentPlayer scrubToPct:pct];
}

- (void)endScrubbing
{
    [self.currentPlayer endScrubbing];
}

- (void)shutdown
{
    STVDebugAssert(!self.isShutdown, @"shoult not already be shutdown");
    self.shouldBePlaying = NO;
    self.isShutdown = YES;
    
    //UIScrollView seems to have a problem with its delegate...
    //given: delegate (self) is dealloc'd just after -setContentOffset:animated:YES
    //issue: -respondsToSelector: is sent to zombied delegate (self)
    //theory: the animation completion block has a dangling pointer
    //        (even if normal UIScrollView delegate is weak and thereby set to nil)
    //
    //at any rate, the following fixes the zombie crash we were seeing
    self.collectionView.delegate = nil;
    
    [[SPVideoExtractor sharedInstance] cancelAllExtractions];
    
    //remove any alert particular to current video
    [self.currentVideoAlertView performSelectorOnMainThread:@selector(dismiss) withObject:nil waitUntilDone:YES];
    
    //resetting all possibly playable players (including current player) will pause and free memory of AVPlayer
    //not entirely true: if the player has an extraction pending, that block holds a reference to the player
    //but resetPlayer: is respected by that block; it will do nothing if it's player has been reset.
    [[self.players allValues] makeObjectsPerformSelector:@selector(resetPlayer)];
}

#pragma mark - Utility API

- (void)addGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
{
    [self.view addGestureRecognizer:gestureRecognizer];
}

#pragma mark - iPhone API

- (id<ShelbyVideoContainer>)getCurrentPlaybackEntity
{
    return self.deduplicatedEntries[self.currentPlayersIndexPath.row];
}

- (void)scrollTo:(CGPoint)contentOffset
{
    [self.collectionView setContentOffset:contentOffset animated:NO];
}

- (void)endDecelerating
{
    [self scrollViewDidEndDecelerating:self.collectionView];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.deduplicatedEntries count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ShelbyVideoReelCollectionViewCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:kShelbyVideoReelCollectionViewCellReuseId
                                                                                             forIndexPath:indexPath];
    
    SPVideoPlayer *player = [self playerForIndexPath:indexPath];
    [cell addSubview:player.view];
    [cell addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[playerView]|"
                                                                 options:0
                                                                 metrics:nil
                                                                   views:@{@"playerView":player.view}]];
    [cell addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[playerView]|"
                                                                 options:0
                                                                 metrics:nil
                                                                   views:@{@"playerView":player.view}]];
    cell.player = player;
    
    return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    //since we're full screen, this indicates a transition from one player to the next
    ShelbyVideoReelCollectionViewCell *videoCell = (ShelbyVideoReelCollectionViewCell *)cell;
    SPVideoPlayer *previousPlayer = videoCell.player;
    
    //hibernate the previous player
    previousPlayer.shouldAutoplay = NO;
    [previousPlayer pause];
    [previousPlayer.view removeFromSuperview];
}

#pragma mark - UISCrollViewDelegate

//this is hit when user is manually scrolling
//it's NOT hit if we do a programatic scroll
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    STVAssert(scrollView == self.collectionView);
    
    //determine new player and get it going
    //setting currentPlayersIndexPath sets & sets up currentPlayer, sends notification
    self.currentPlayersIndexPath = [self.collectionView indexPathForItemAtPoint:CGPointMake(0, self.collectionView.contentOffset.y + (self.collectionView.bounds.size.height / 2.f))];
}

//this is hit if we do a programatic scroll (with animation)
//it's NOT hit when user is manually scrolling
- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    STVAssert(scrollView == self.collectionView);
    
    //determine new player and get it going
    //setting currentPlayersIndexPath sets & sets up currentPlayer, sends notification
    self.currentPlayersIndexPath = self.lastRequestedScrollToIndexPath;
}

#pragma mark - SPVideoPlayerDelegate

- (void)videoDidFinishPlayingForPlayer:(SPVideoPlayer *)player
{
    if (self.currentPlayer == player) {
        [ShelbyAnalyticsClient sendEventWithCategory:kAnalyticsCategoryPrimaryUX action:kAnalyticsUXVideoDidAutoadvance nicknameAsLabel:YES];
        [ShelbyAnalyticsClient sendLocalyticsEvent:kLocalyticsWatchVideo];
        [player scrubToPct:0.f];
        
        //autoadvance to next player
        [self scrollForPlaybackAtIndex:(self.currentPlayersIndexPath.row + 1) forcingPlayback:YES animated:YES];
    }
}

- (void)videoDidStallForPlayer:(SPVideoPlayer *)player
{
    if (self.currentPlayer == player) {
        [player pause];
        if (self.lastVideoStalledAlertTime == nil || [self.lastVideoStalledAlertTime timeIntervalSinceNow] < kVideoStalledMinTimeBetweenAlerts) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.currentVideoAlertView dismiss];
                self.lastVideoStalledAlertTime = [NSDate date];
                self.currentVideoAlertView = [[ShelbyAlert alloc] initWithTitle:NSLocalizedString(@"PLAYBACK_STALLED_TITLE", @"--Playback Stalled--")
                                                                        message:NSLocalizedString(@"PLAYBACK_STALLED_MESSAGE", nil)
                                                             dismissButtonTitle:NSLocalizedString(@"PLAYBACK_STALLED_BUTTON", nil)
                                                                 autodimissTime:6.0f
                                                                      onDismiss:^(BOOL didAutoDimiss) {
                                                                          self.currentVideoAlertView = nil;
                                                                      }];
                [self.currentVideoAlertView show];
            });
        }
    }
}

- (void)videoLoadingStatus:(BOOL)isLoading forPlayer:(SPVideoPlayer *)player
{
    //intentionally left blank
}

- (void)videoBufferedRange:(CMTimeRange)bufferedRange forPlayer:(SPVideoPlayer *)player
{
    if (self.currentPlayer == player) {
        [self.videoPlaybackDelegate setBufferedRange:bufferedRange];
    }
}

- (void)videoDuration:(CMTime)duration forPlayer:(SPVideoPlayer *)player
{
    if (self.currentPlayer == player) {
        [self.videoPlaybackDelegate setDuration:duration];
    }
}

- (void)videoCurrentTime:(CMTime)time forPlayer:(SPVideoPlayer *)player
{
    if (self.currentPlayer == player) {
        [self.videoPlaybackDelegate setCurrentTime:time];
    }
}

- (void)videoPlaybackStatus:(BOOL)isPlaying forPlayer:(SPVideoPlayer *)player
{
    if (self.currentPlayer == player) {
        [self.videoPlaybackDelegate setVideoIsPlaying:isPlaying];
        if (isPlaying) {
            //hide backdrop when we start playing
            self.backdropView.showBackdropImage = NO;
        }
    }
}

- (void)videoExtractionFailForAutoplayPlayer:(SPVideoPlayer *)player
{
    if (self.currentPlayer == player) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.currentVideoAlertView dismiss];
            self.currentVideoAlertView = [[ShelbyAlert alloc] initWithTitle:NSLocalizedString(@"EXTRACTION_FAIL_TITLE", @"--Extraction Fail--")
                                                                    message:NSLocalizedString(@"EXTRACTION_FAIL_MESSAGE", nil)
                                                         dismissButtonTitle:NSLocalizedString(@"EXTRACTION_FAIL_BUTTON", nil)
                                                             autodimissTime:3.0f onDismiss:^(BOOL didAutoDimiss) {
                                                                 if (self.currentPlayer == player) {
                                                                     //autoadvance to next player
                                                                     [self scrollForPlaybackAtIndex:(self.currentPlayersIndexPath.row + 1)
                                                                                    forcingPlayback:YES
                                                                                           animated:YES];
                                                                 }
                                                                 self.currentVideoAlertView = nil;
                                                             }];
            [self.currentVideoAlertView show];
        });
    }
}

- (void)videoThumbnailTappped:(SPVideoPlayer *)player
{
    [self.delegate userDidRequestPlayCurrentPlayer];
}

#pragma mark - Helpers

- (SPVideoPlayer *)playerForIndexPath:(NSIndexPath *)indexPath
{
    if (!((NSInteger)self.deduplicatedEntries.count > indexPath.row)) {
        return nil;
    }
    
    Frame *f = [Frame frameForEntity:self.deduplicatedEntries[indexPath.row]];
    SPVideoPlayer *player = self.players[f.frameID];
    if (![player isKindOfClass:[SPVideoPlayer class]]) {
        player = [[SPVideoPlayer alloc] initWithVideoFrame:f];
        self.players[f.frameID] = player;
        player.view.translatesAutoresizingMaskIntoConstraints = NO;
        player.videoPlayerDelegate = self;
    }
    
    return player;
}

- (void)manageLoadedVideoPlayersForCurrentPlayer:(SPVideoPlayer *)expectedCurrentPlayer
{
    //1) build an array of the players we want to keep warm
    NSMutableArray *playersToKeepWarm = [NSMutableArray new];
    SPVideoPlayer *additionalPlayer;
    switch (preloadStrategy) {
        case SPVideoReelCollectionPreloadNextTwoKeepPrevious:
            additionalPlayer = [self playerForIndexPath:[NSIndexPath indexPathForRow:self.currentPlayersIndexPath.row+2
                                                                           inSection:self.currentPlayersIndexPath.section]];
            if (additionalPlayer) {
                [playersToKeepWarm addObject:additionalPlayer];
            }
            //2 ahead, plus...
            
        case SPVideoReelCollectionPreloadNextKeepPrevious:
            if (self.currentPlayersIndexPath.row > 0) {
                additionalPlayer = [self playerForIndexPath:[NSIndexPath indexPathForRow:self.currentPlayersIndexPath.row-1
                                                                               inSection:self.currentPlayersIndexPath.section]];
                if (additionalPlayer) {
                    [playersToKeepWarm addObject:additionalPlayer];
                }
            }
            //1 behind, plus...
            
        case SPVideoReelCollectionPreloadNextOnly:
            additionalPlayer = [self playerForIndexPath:[NSIndexPath indexPathForRow:self.currentPlayersIndexPath.row+1
                                                                           inSection:self.currentPlayersIndexPath.section]];
            if (additionalPlayer) {
                [playersToKeepWarm addObject:additionalPlayer];
            }
            //1 ahead, plus...
            
        case SPVideoReelCollectionPreloadNone:
        case SPVideoReelCollectionPreloadStrategyNotSet:
        default:
            //the current player
            if (self.currentPlayer) {
                [playersToKeepWarm addObject:self.currentPlayer];
            }
            break;
    }
    
    //2) reset the players we dont want warm, freeing the AVPlayer
    //we still keep the SPVideoPlayer around b/c it maintains some state
    NSMutableArray *playersToReset = [[self.players allValues] mutableCopy];
    [playersToReset removeObjectsInArray:playersToKeepWarm];
    for (SPVideoPlayer *player in playersToReset) {
        [player resetPlayer];
    }
    
    //3) and make sure the players we want warm, are warm
    for (SPVideoPlayer *player in playersToKeepWarm) {
        [player prepareForStreamingPlayback];
    }
}

- (void)setupVideoPreloadStrategy
{
    if (preloadStrategy == SPVideoReelCollectionPreloadStrategyNotSet) {
        if (DEVICE_IPAD) {
            if ([[UIScreen mainScreen] isRetinaDisplay]) {
                preloadStrategy = SPVideoReelCollectionPreloadNextKeepPrevious;
                //DLog(@"iPad Retina Preload strategy: next + current + previous");
            } else if ([DeviceUtilities isIpadMini1]) {
                preloadStrategy = SPVideoReelCollectionPreloadNextOnly;
                //DLog(@"iPad mini Preload strategy: next only");
            } else {
                preloadStrategy = SPVideoReelCollectionPreloadNextOnly;
                //DLog(@"iPad 2,3 Preload strategy: next only");
            }
        } else {
            preloadStrategy = SPVideoReelCollectionPreloadNextKeepPrevious;
            //DLog(@"iPhone Preload strategy: next + current + previous");
        }
    }
}

- (void)degradeVideoPreloadStrategy
{
    if(preloadStrategy > SPVideoReelCollectionPreloadNone){
        preloadStrategy--;
    }
}

- (void)warmURLExtractionCache
{
    //pre fetch the extraction for the next few vids
    NSUInteger startIdx = self.currentPlayersIndexPath.row;
    NSUInteger endIdx = MIN(startIdx + 6, [self.deduplicatedEntries count]);
    for (NSUInteger i = startIdx; i < endIdx; i++) {
        Frame *f = [Frame frameForEntity:self.deduplicatedEntries[i]];
        [[SPVideoExtractor sharedInstance] warmCacheForVideo:f.video];
    }
}

@end
