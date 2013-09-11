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
@property (nonatomic, strong) Frame *currentFrame;
//set via "airplay active" notification
@property (nonatomic, strong) SPVideoPlayer *videoPlayer;
//allows us to dismiss alert view if video changes or we exit
@property (nonatomic, strong) ShelbyAlert *currentVideoAlertView;
@property (nonatomic, strong) NSDate *lastVideoStalledAlertTime;

// External screen for mirroring
@property (nonatomic, strong) UIWindow *secondWindow;
@end

//only show the stalled alert view if it hasn't shown in this much time
//TODO DRY
#define VIDEO_STALLED_MIN_TIME_BETWEEN_ALERTS -60 // 1m

@implementation ShelbyAirPlayController

- (id)init
{
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setup
{
    // General AirPlay observers
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(airplayDidBegin:) name:kShelbySPVideoAirplayDidBegin object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(airplayDidEnd:) name:kShelbySPVideoAirplayDidEnd object:nil];
    
    // Mirroring setup.
    [self setUpScreenConnectionNotificationHandlers];
    [self checkForExistingScreenAndInitializeIfPresent];
}

- (void)initializeSecondScreen:(UIScreen *)screen
{
    if (!self.secondWindow) {
        self.secondWindow = [[UIWindow alloc] initWithFrame:screen.bounds];
        self.secondWindow.screen = screen;
        self.secondWindow.hidden = NO;
        
        UIView *externalView = [[UIView alloc] initWithFrame:screen.bounds];
        
        // Center Shelby Logo on External Screen
        UIImageView *logo = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo-tv.png"]];
        NSInteger logoHeight = logo.frame.size.height;
        NSInteger logoWidth = logo.frame.size.width;
        logo.frame = CGRectMake(screen.bounds.size.width/2 - logoWidth/2 , screen.bounds.size.height/2 - logoHeight/2, logoWidth, logoHeight);
        [externalView addSubview:logo];
        
        [self.secondWindow addSubview:externalView];
    }
}

- (void)checkForExistingScreenAndInitializeIfPresent
{
    if ([[UIScreen screens] count] > 1) {
        UIScreen *secondScreen = [[UIScreen screens] objectAtIndex:1];
        [self initializeSecondScreen:secondScreen];
    }
}

- (void)setUpScreenConnectionNotificationHandlers
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(handleScreenDidConnectNotification:)
                   name:UIScreenDidConnectNotification object:nil];
    [center addObserver:self selector:@selector(handleScreenDidDisconnectNotification:)
                   name:UIScreenDidDisconnectNotification object:nil];
}

- (void)handleScreenDidConnectNotification:(NSNotification*)aNotification
{
    UIScreen *newScreen = [aNotification object];
    [self initializeSecondScreen:newScreen];
}


- (void)handleScreenDidDisconnectNotification:(NSNotification*)aNotification
{
    self.secondWindow.hidden = YES;
    self.secondWindow = nil;
}

- (void)airplayDidBegin:(NSNotification *)note
{
    [ShelbyAnalyticsClient sendEventWithCategory:kAnalyticsCategoryPrimaryUX
                                          action:kAnalyticsUXTapAirplay
                                 nicknameAsLabel:YES];

    STVAssert(!self.videoPlayer, @"air play sets our player (or somebody else does, later)");
    SPVideoPlayer *notedPlayer = (SPVideoPlayer *)note.object;
    STVAssert(notedPlayer && [notedPlayer isKindOfClass:[SPVideoPlayer class]], @"notification object should be SPVideoPlayer, was %@", notedPlayer);

    if (notedPlayer.videoFrame != [Frame frameForEntity:self.videoControlsVC.currentEntity]) {
        // *why* do we get a notification from the wrong player?  no idea.  but we handle it...
        DLog(@"Wrong player on init of airplay, controls have:%@, player has:%@", [Frame frameForEntity:self.videoControlsVC.currentEntity].video.title, notedPlayer.videoFrame.video.title);
        self.videoPlayer = notedPlayer;
        [self playEntity:self.videoControlsVC.currentEntity];
    }

    self.videoPlayer = notedPlayer;
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    [self.delegate airPlayControllerDidBeginAirPlay:self];
    self.currentFrame = self.videoPlayer.videoFrame;

    [ShelbyAnalyticsClient sendEventWithCategory:kAnalyticsCategoryPrimaryUX
                                          action:kAnalyticsUXAirplayBegin
                                 nicknameAsLabel:YES];
}

- (void)airplayDidEnd:(NSNotification *)note
{
    [self.videoPlayer resetPlayer];
    self.videoPlayer = nil;
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    [self.delegate airPlayControllerDidEndAirPlay:self];

    [ShelbyAnalyticsClient sendEventWithCategory:kAnalyticsCategoryPrimaryUX
                                          action:kAnalyticsUXAirplayEnd
                                 nicknameAsLabel:YES];
}

- (BOOL)isAirPlayActive
{
    return self.videoPlayer != nil;
}

- (void)playEntity:(id<ShelbyVideoContainer>)entity
{
    Frame *newFrame = [Frame frameForEntity:entity];
    if (newFrame != self.currentFrame) {
        self.currentFrame = newFrame;

        if (self.videoPlayer) {
            //tell current player to change video
            self.videoPlayer.videoFrame = newFrame;
            self.videoPlayer.shouldAutoplay = YES;
            [self.videoPlayer prepareForStreamingPlayback];
            self.videoControlsVC.currentEntity = entity;

        } else {
            //create a new player, playing at selected entity
            //NB: we don't need to set the frame b/c the underlying AVPlayer uses external playback mode
            self.videoPlayer = [[SPVideoPlayer alloc] initWithVideoFrame:newFrame];
            self.videoPlayer.shouldAutoplay = YES;
            [self.videoPlayer prepareForStreamingPlayback];
        }
    }
}

- (void)setVideoPlayer:(SPVideoPlayer *)videoPlayer
{
    _videoPlayer = videoPlayer;
    _videoPlayer.videoPlayerDelegate = self;
}

- (void)pauseCurrentPlayer
{
    [self.videoPlayer pause];
}

- (void)playCurrentPlayer
{
    [self.videoPlayer play];
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
    [self.delegate airPlayControllerShouldAutoadvance:self];
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
