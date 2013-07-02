//
//  VideoControlsViewController.h
//  Shelby.tv
//
//  Created by Daniel Spinosa on 7/1/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyViewController.h"
#import <CoreMedia/CoreMedia.h>
#import "SPVideoReel.h"

@protocol VideoControlsDelegate <NSObject>

- (void)playVideoWithCurrentFocus;
- (void)pauseCurrentVideo;
- (void)scrubCurrentVideoTo:(CGFloat)pct;

@end

@interface VideoControlsViewController : ShelbyViewController<VideoPlaybackDelegate>

@property (nonatomic, weak) id<VideoControlsDelegate> delegate;

//a placholder for the system airplay view
@property (nonatomic, readonly) UIView *airPlayView;

@property (nonatomic, assign) BOOL videoIsPlaying;
@property (nonatomic, assign) BOOL currentEntryIsLiked;
@property (nonatomic, assign) CMTimeRange bufferedRange;
@property (nonatomic, assign) CMTime currentTime;
@property (nonatomic, assign) CMTime duration;

@end
