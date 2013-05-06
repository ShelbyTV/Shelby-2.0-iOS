//
//  SPVideoPlayer.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 11/1/12.
//  Copyright (c) 2012 Shelby TV. All rights reserved.
//

@protocol SPVideoPlayerDelegate <NSObject>

- (void)videoDidFinishPlaying;

@end

@interface SPVideoPlayer : GAITrackedViewController

@property (nonatomic) Frame *videoFrame;
@property (nonatomic) AVPlayer *player;
@property (assign, nonatomic) BOOL isPlayable;
@property (assign, nonatomic) BOOL isPlaying;
@property (assign, nonatomic) BOOL playbackFinished;
@property (assign, nonatomic) CMTime playbackStartTime;
@property (assign, nonatomic) BOOL shouldAutoPlay;
@property (nonatomic, weak) id<SPVideoPlayerDelegate> videoPlayerDelegate;

// Initialization
- (id)initWithBounds:(CGRect)bounds withVideoFrame:(Frame *)videoFrame;
- (void)resetPlayer;

// Preloading
- (void)prepareForStreamingPlayback;
- (void)prepareForLocalPlayback;

// Playback Info
- (NSTimeInterval)availableDuration;
- (CMTime)elapsedTime;
- (CMTime)duration;

// Playback Control
//djs moved the following to prepareForLocalPlayback
//- (void)loadVideoFromDisk;
- (void)togglePlayback;
- (void)restartPlayback;
- (void)play;
- (void)pause;
- (void)share;
- (void)roll;
@end
