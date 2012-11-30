//
//  SPVideoPlayer.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 11/1/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

@interface SPVideoPlayer : UIViewController

@property (assign, nonatomic) BOOL videoQueued;

- (id)initWithBounds:(CGRect)bounds forVideo:(Video*)video andAutoPlay:(BOOL)autoPlay;
- (void)queueVideo;
- (void)play;
- (void)pause;
- (void)airPlay;

@end