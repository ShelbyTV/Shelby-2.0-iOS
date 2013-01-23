//
//  SPModel.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 1/23/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SPVideoPlayer, SPVideoReel, SPOverlayView;

@protocol SPVideoScrubberDelegate <NSObject>

- (CMTime)elapsedDuration;
- (void)setupScrubber;
- (void)syncScrubber;

@end

@interface SPModel : NSObject <SPVideoScrubberDelegate>
{
    id _scrubberTimeObserver;
}

@property (strong, nonatomic) id scrubberTimeObserver;
@property (assign, nonatomic) NSUInteger numberOfVideos;
@property (assign, nonatomic) NSUInteger currentVideo;
@property (strong, nonatomic) SPVideoPlayer *currentVideoPlayer;
@property (strong, nonatomic) SPVideoReel *videoReel;
@property (strong, nonatomic) SPOverlayView *overlayView;
@property (strong, nonatomic) NSTimer *overlayTimer;
@property (assign, nonatomic) BOOL isAirPlayConnected;
@property (weak, nonatomic, readonly) SPVideoPlayer <SPVideoScrubberDelegate> *videoScrubberDelegate;

/// Singleton Methods
+ (SPModel*)sharedInstance;

/// Cleanup Methods
- (void)cleanup;

/// UI Methods
- (void)rescheduleOverlayTimer;
- (void)toggleOverlay;
- (void)showOverlay;
- (void)hideOverlay;

@end