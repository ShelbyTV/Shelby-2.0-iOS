//
//  SPVideoPlayer.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 11/1/12.
//  Copyright (c) 2012 Shelby TV. All rights reserved.
//

#import "Frame+Helper.h"

#import <CoreMedia/CoreMedia.h>
#import "ShelbyViewController.h"

@class SPVideoPlayer;

@protocol SPVideoPlayerDelegate <NSObject>

- (void)videoDidFinishPlayingForPlayer:(SPVideoPlayer *)player;
- (void)videoDidStallForPlayer:(SPVideoPlayer *)player;
- (void)videoLoadingStatus:(BOOL)isLoading forPlayer:(SPVideoPlayer *)player;
- (void)videoBufferedRange:(CMTimeRange)bufferedRange forPlayer:(SPVideoPlayer *)player;
- (void)videoDuration:(CMTime)duration forPlayer:(SPVideoPlayer *)player;
- (void)videoCurrentTime:(CMTime)time forPlayer:(SPVideoPlayer *)player;
- (void)videoPlaybackStatus:(BOOL)isPlaying forPlayer:(SPVideoPlayer *)player;
- (void)videoExtractionFailForAutoplayPlayer:(SPVideoPlayer *)player;

@end

@interface SPVideoPlayer : ShelbyViewController

@property (nonatomic) Frame *videoFrame;
@property (readonly) BOOL isPlaying;
@property (readonly) BOOL isPlayable;
@property (assign, atomic) BOOL shouldAutoplay;
@property (nonatomic, weak) id<SPVideoPlayerDelegate> videoPlayerDelegate;

// Initialization
- (id)initWithBounds:(CGRect)bounds withVideoFrame:(Frame *)videoFrame;

- (void)resetPlayer;

// Does not load video
- (void)warmVideoExtractionCache;
// Does preload video
- (void)prepareForStreamingPlayback;
- (void)prepareForLocalPlayback;

- (CMTime)duration;

// Playback Control
- (void)play;
- (void)pause;
- (void)togglePlayback;
- (void)scrubToPct:(CGFloat)scrubPct;

@end
