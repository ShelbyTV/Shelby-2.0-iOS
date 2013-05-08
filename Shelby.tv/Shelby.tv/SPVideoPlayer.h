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
@property (assign, nonatomic) BOOL isPlaying;
@property (assign, nonatomic) BOOL isPlayable;
@property (assign, nonatomic) BOOL shouldAutoplay;
@property (nonatomic, weak) id<SPVideoPlayerDelegate> videoPlayerDelegate;

// Initialization
- (id)initWithBounds:(CGRect)bounds withVideoFrame:(Frame *)videoFrame;

- (void)resetPlayer;

// Does not load video
- (void)warmVideoExtractionCache;
// Does preload video
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
- (void)play;
- (void)pause;
- (void)share;
- (void)roll;
@end
