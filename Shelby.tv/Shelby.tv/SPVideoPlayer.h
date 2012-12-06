//
//  SPVideoPlayer.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 11/1/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

@class SPOverlayView;

@interface SPVideoPlayer : UIViewController

@property (strong, nonatomic) Frame *videoFrame;
@property (strong, nonatomic) AVPlayer *player;
@property (assign, nonatomic) BOOL videoQueued;

- (id)initWithBounds:(CGRect)bounds
       forVideoFrame:(Frame*)videoFrame
       inOverlayView:(SPOverlayView*)overlayView
   andShouldAutoPlay:(BOOL)autoPlay;

- (void)queueVideo;
- (void)togglePlayback;
- (void)play;
- (void)pause;
- (void)airPlay;
- (void)share;
- (CMTime)elapsedDuration;

@end