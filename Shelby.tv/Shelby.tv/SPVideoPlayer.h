//
//  SPVideoPlayer.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 11/1/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

@class SPOverlayView, SPVideoReel;

@interface SPVideoPlayer : UIViewController

@property (strong, nonatomic) Frame *videoFrame;
@property (strong, nonatomic) AVPlayer *player;
@property (assign, nonatomic) BOOL videoQueued;
@property (assign, nonatomic) BOOL videoPlayable;
@property (assign, nonatomic) BOOL playbackFinished;

- (id)initWithBounds:(CGRect)bounds
       forVideoFrame:(Frame*)videoFrame
     withOverlayView:(SPOverlayView*)overlayView
         inVideoReel:(SPVideoReel*)videoReel;

- (void)queueVideo;
- (void)togglePlayback;
- (void)restartPlayback;
- (void)play;
- (void)pause;
- (void)airPlay;
- (void)share;
- (CMTime)elapsedDuration;
- (void)setupScrubber;
- (void)syncScrubber;

@end