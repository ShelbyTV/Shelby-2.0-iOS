//
//  ShelbyAirPlayController.m
//  Shelby.tv
//
//  Created by Daniel Spinosa on 8/21/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyAirPlayController.h"
#import "SPVideoPlayer.h"

@interface ShelbyAirPlayController()
//set via "airplay active" notification
@property (nonatomic, strong) SPVideoPlayer *videoPlayer;
@end

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
        self.videoPlayer.shouldAutoplay = YES;
        [self.videoPlayer prepareForStreamingPlayback];
    }
}

@end
