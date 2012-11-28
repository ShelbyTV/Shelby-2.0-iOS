//
//  SPVideoPlayer.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 11/1/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

@interface SPVideoPlayer : UIViewController

- (id)initWithBounds:(CGRect)bounds forVideo:(Video*)video andAutoPlay:(BOOL)autoPlay;

- (void)play;
- (void)pause;
- (void)airPlay;

@end