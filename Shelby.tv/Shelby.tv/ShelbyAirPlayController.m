//
//  ShelbyAirPlayController.m
//  Shelby.tv
//
//  Created by Daniel Spinosa on 8/21/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyAirPlayController.h"
#import "ShelbyAlert.h"
#import "ShelbyAnalyticsClient.h"
#import "SPVideoPlayer.h"

@interface ShelbyAirPlayController()
//set via "airplay active" notification
@property (nonatomic, strong) SPVideoPlayer *videoPlayer;
//allows us to dismiss alert view if video changes or we exit
@property (nonatomic, strong) ShelbyAlert *currentVideoAlertView;
@property (nonatomic, strong) NSDate *lastVideoStalledAlertTime;
@end

//only show the stalled alert view if it hasn't shown in this much time
//TODO DRY
#define VIDEO_STALLED_MIN_TIME_BETWEEN_ALERTS -60 // 1m

@implementation ShelbyAirPlayController

- (id)init
{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(airplayDidBegin:) name:kShelbySPVideoAirplayDidBegin object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(airplayDidEnd:) name:kShelbySPVideoAirplayDidEnd object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)airplayDidBegin:(NSNotification *)note
{
    STVAssert(note.object && [note.object isKindOfClass:[SPVideoPlayer class]], @"notification object should be SPVideoPlayer, was %@", note.object);
    self.videoPlayer = note.object;
    self.videoPlayer.videoPlayerDelegate = self;
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    [self.delegate airPlayControllerDidBeginAirPlay:self];
}

- (void)airplayDidEnd:(NSNotification *)note
{
    [self.videoPlayer resetPlayer];
    self.videoPlayer = nil;
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    [self.delegate airPlayControllerDidEndAirPlay:self];
}

- (BOOL)isAirPlayActive
{
    return self.videoPlayer != nil;
}

- (void)playEntity:(id<ShelbyVideoContainer>)entity
{
    if (self.videoPlayer) {
        //tell current player to change video
        self.videoPlayer.videoFrame = [Frame frameForEntity:entity];
        self.videoPlayer.shouldAutoplay = YES;
        [self.videoPlayer prepareForStreamingPlayback];

    } else {
        //create a new player, playing at selected entity
        //NB: we don't need to set the frame b/c the underlying AVPlayer uses external playback mode
        self.videoPlayer = [[SPVideoPlayer alloc] initWithVideoFrame:[Frame frameForEntity:entity]];
        self.videoPlayer.videoPlayerDelegate = self;
        self.videoPlayer.shouldAutoplay = YES;
        [self.videoPlayer prepareForStreamingPlayback];
    }
}

- (void)pauseCurrentPlayer
{
    [self.videoPlayer pause];
}

- (void)beginScrubbing
{
    [self.videoPlayer beginScrubbing];
}

- (void)scrubCurrentPlayerTo:(CGFloat)percent
{
    [self.videoPlayer scrubToPct:percent];
}

- (void)endScrubbing
{
    [self.videoPlayer endScrubbing];
}

- (void)autoadvanceVideoInForwardDirection
{
    //TODO: tell home VC we need to autoadvance
}

#pragma mark - SPVideoPlayerDelegate

- (void)videoDidFinishPlayingForPlayer:(SPVideoPlayer *)player
{
    [self autoadvanceVideoInForwardDirection];
    [ShelbyAnalyticsClient sendEventWithCategory:kAnalyticsCategoryPrimaryUX action:kAnalyticsUXVideoDidAutoadvance nicknameAsLabel:YES];
}

- (void)videoDidStallForPlayer:(SPVideoPlayer *)player
{
    [self.videoPlayer pause];
    if (self.lastVideoStalledAlertTime == nil || [self.lastVideoStalledAlertTime timeIntervalSinceNow] < VIDEO_STALLED_MIN_TIME_BETWEEN_ALERTS) {
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
    }
}

- (void)videoLoadingStatus:(BOOL)isLoading forPlayer:(SPVideoPlayer *)player
{
    //do nothing
}

- (void)videoBufferedRange:(CMTimeRange)bufferedRange forPlayer:(SPVideoPlayer *)player
{
    [self.videoControlsVC setBufferedRange:bufferedRange];
}

- (void)videoDuration:(CMTime)duration forPlayer:(SPVideoPlayer *)player
{
    [self.videoControlsVC setDuration:duration];
}

- (void)videoCurrentTime:(CMTime)time forPlayer:(SPVideoPlayer *)player
{
    [self.videoControlsVC setCurrentTime:time];
}

- (void)videoPlaybackStatus:(BOOL)isPlaying forPlayer:(SPVideoPlayer *)player
{
    [self.videoControlsVC setVideoIsPlaying:isPlaying];
}

- (void)videoExtractionFailForAutoplayPlayer:(SPVideoPlayer *)player
{
    [self.currentVideoAlertView dismiss];
    self.currentVideoAlertView = [[ShelbyAlert alloc] initWithTitle:NSLocalizedString(@"EXTRACTION_FAIL_TITLE", @"--Extraction Fail--")
                                                            message:NSLocalizedString(@"EXTRACTION_FAIL_MESSAGE", nil)
                                                 dismissButtonTitle:NSLocalizedString(@"EXTRACTION_FAIL_BUTTON", nil)
                                                     autodimissTime:3.0f
                                                          onDismiss:^(BOOL didAutoDimiss) {
                                                              [self autoadvanceVideoInForwardDirection];
                                                              self.currentVideoAlertView = nil;
                                                          }];
    [self.currentVideoAlertView show];
}

@end
