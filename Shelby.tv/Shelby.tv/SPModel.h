//
//  SPModel.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 1/23/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

#import "SPVideoExtractor.h"
#import "SPVideoPlayer.h"
#import "SPOverlayView.h"

@class SPVideoReel;

@interface SPModel : NSObject

@property (nonatomic) NSTimer *overlayTimer;
@property (assign, nonatomic) NSUInteger numberOfVideos;
@property (assign, nonatomic) NSUInteger currentVideo;
@property (weak, nonatomic) SPOverlayView *overlayView;
@property (weak, nonatomic) SPVideoReel *videoReel;
@property (weak, nonatomic) SPVideoPlayer *currentVideoPlayer;

/// Singleton Methods
+ (SPModel*)sharedInstance;

- (void)destroyModel;

/// UI Methods
- (void)rescheduleOverlayTimer;

@end
