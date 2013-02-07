//
//  SPModel.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 1/23/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

#import "SPVideoExtractor.h"

@class SPOverlayView;
@class SPVideoPlayer;
@class SPVideoReel;

@protocol SPVideoScrubberDelegate <NSObject>

- (CMTime)elapsedDuration;
- (void)setupScrubber;
- (void)syncScrubber;
- (NSString*)convertElapsedTime:(double)currentTime andDuration:(double)duration;

@end

@interface SPModel : NSObject

@property (nonatomic) id scrubberTimeObserver;
@property (nonatomic) NSTimer *overlayTimer;
@property (weak, nonatomic) SPOverlayView *overlayView;
@property (weak, nonatomic) SPVideoReel *videoReel;
@property (nonatomic, readonly) SPVideoExtractor *videoExtractor;
@property (assign, nonatomic) NSUInteger numberOfVideos;
@property (assign, nonatomic) NSUInteger currentVideo;
@property (weak, nonatomic) SPVideoPlayer <SPVideoScrubberDelegate> *currentVideoPlayerDelegate;

/// Singleton Methods
+ (SPModel*)sharedInstance;

/// Destruction Methods
- (void)storeVideoPlayer:(SPVideoPlayer*)player;
- (void)teardown;

/// UI Methods
- (void)rescheduleOverlayTimer;

@end
