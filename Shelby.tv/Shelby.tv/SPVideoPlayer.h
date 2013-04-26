//
//  SPVideoPlayer.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 11/1/12.
//  Copyright (c) 2012 Shelby TV. All rights reserved.
//

@interface SPVideoPlayer : GAITrackedViewController

@property (nonatomic) Frame *videoFrame;
@property (nonatomic) AVPlayer *player;
@property (assign, nonatomic) BOOL isPlayable;
@property (assign, nonatomic) BOOL isPlaying;
@property (assign, nonatomic) BOOL playbackFinished;
@property (assign, nonatomic) CMTime playbackStartTime;

/// Initialization Methods
- (id)initWithBounds:(CGRect)bounds withVideoFrame:(Frame *)videoFrame;
- (void)resetPlayer;

/// Video Storage Methods
- (NSTimeInterval)availableDuration;
- (CMTime)elapsedTime;
- (CMTime)duration;

/// Video Fetching Methods
- (void)queueVideo;

/// Video Playback Methods
- (void)loadVideoFromDisk;
- (void)togglePlayback:(id)sender;
- (void)restartPlayback;
- (void)play;
- (void)pause;
- (void)share;
- (void)roll;
@end
