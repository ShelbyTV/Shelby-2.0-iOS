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
@property (assign, nonatomic) BOOL isPlayable;
@property (assign, nonatomic) BOOL isDownloading;
@property (assign, nonatomic) BOOL playbackFinished;
@property (assign, nonatomic) BOOL isPlaying;
@property (strong, nonatomic) NSTimer *overlayTimer;
@property (strong, nonatomic) NSNumber *positionInReel;

- (id)initWithBounds:(CGRect)bounds
       forVideoFrame:(Frame*)videoFrame
     withOverlayView:(SPOverlayView*)overlayView
         inVideoReel:(SPVideoReel*)videoReel
          atPosition:(NSUInteger)position;

- (void)recreate;

/// Video Fetching
- (void)queueVideo;
- (void)addToCache;
- (void)removeFromCache;
- (void)setupDownloadButton;

/// Video Playback
- (void)togglePlayback;
- (void)restartPlayback;
- (void)play;
- (void)pause;
- (void)airPlay;
- (void)share;
- (void)loadFromCache;

/// Video Scrubber
- (CMTime)elapsedDuration;
- (void)setupScrubber;
- (void)syncScrubber;

@end