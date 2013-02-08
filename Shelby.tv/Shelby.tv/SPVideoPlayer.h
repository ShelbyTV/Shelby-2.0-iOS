//
//  SPVideoPlayer.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 11/1/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

@interface SPVideoPlayer : UIViewController

@property (nonatomic) Frame *videoFrame;
@property (nonatomic) AVPlayer *player;
@property (assign, nonatomic) BOOL isPlayable;
@property (assign, nonatomic) BOOL isPlaying;
@property (assign, nonatomic) BOOL playbackFinished;

/// Initialization Methods
- (id)initWithBounds:(CGRect)bounds withVideoFrame:(Frame*)videoFrame;
- (void)resetPlayer;

/// Video Fetching Methods
- (void)queueVideo;

/// Video Playback Methods
- (void)togglePlayback;
- (void)restartPlayback;
- (void)play;
- (void)pause;
- (void)share;

@end
