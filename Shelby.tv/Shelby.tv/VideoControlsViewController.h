//
//  VideoControlsViewController.h
//  Shelby.tv
//
//  Created by Daniel Spinosa on 7/1/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyViewController.h"
#import <CoreMedia/CoreMedia.h>
#import "SPVideoReelCollectionViewController.h"

@class UIButton;

extern NSString * const kShelbyRequestFullscreenPlaybackNotification;
extern NSString * const kShelbyRequestSmallscreenPlaybackNotification;

typedef NS_ENUM(NSUInteger, VideoControlsDisplayMode)
{
    //nothing is shown
    VideoControlsDisplayDefault,
    
    //just the lower bar of action buttons is shown
    VideoControlsDisplayActionsOnly,
    
    //upper playback controls and lower action bar are shown
    VideoControlsDisplayActionsAndPlaybackControls,

    //VideoControlsDisplayActionsAndPlaybackControls + alterations for AirPlay
    VideoControlsDisplayForAirPlay
};

@class VideoControlsViewController;

@protocol VideoControlsDelegate <NSObject>
- (void)videoControlsPlayCurrentVideo:(VideoControlsViewController *)vcvc;
- (void)videoControlsPauseCurrentVideo:(VideoControlsViewController *)vcvc;
- (void)videoControls:(VideoControlsViewController *)vcvc scrubCurrentVideoTo:(CGFloat)pct;
- (void)videoControlsLikeCurrentVideo:(VideoControlsViewController *)vcvc;
- (void)videoControlsUnlikeCurrentVideo:(VideoControlsViewController *)vcvc;
- (void)videoControls:(VideoControlsViewController *)vcvc isScrubbing:(BOOL)isScrubbing;
@optional
- (void)videoControlsShareCurrentVideo:(VideoControlsViewController *)vcvc;
- (void)videoControlsRequestFullScreen:(VideoControlsViewController *)vcvc isExpanding:(BOOL)isExpanding;
- (void)videoControlsRevealAirplayPicker:(VideoControlsViewController *)vcvc airplayButton:(UIButton *)button;
@end

@interface VideoControlsViewController : ShelbyViewController<VideoPlaybackDelegate>

@property (nonatomic, weak) id<VideoControlsDelegate> delegate;

@property (nonatomic, strong) id<ShelbyVideoContainer>currentEntity;

@property (nonatomic, assign) VideoControlsDisplayMode displayMode;

//a placholder for the system airplay view
@property (nonatomic, readonly) UIView *airPlayView;

@property (nonatomic, assign) BOOL videoIsPlaying;
@property (nonatomic, assign) CMTimeRange bufferedRange;
@property (nonatomic, assign) CMTime currentTime;
@property (nonatomic, assign) CMTime duration;

// Same behavior as if the proper expand/contract button was tapped
// iPad only for now
- (void)requestToggleFullscreen;

@end
