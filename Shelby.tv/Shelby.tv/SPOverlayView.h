//
//  SPOverlayView.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 11/28/12.
//  Copyright (c) 2012 Shelby TV. All rights reserved.
//

#import <CoreMedia/CoreMedia.h>

@protocol SPOverlayViewDelegate <NSObject>

- (void)scrubToPercent:(CGFloat)scrubPct;

@end

@interface SPOverlayView : UIView

@property (weak, nonatomic) IBOutlet UIView *airPlayView; // KP KP: TODO: add this button to nib!
@property (weak, nonatomic) IBOutlet UITapGestureRecognizer *scrubberGesture;

@property (strong, nonatomic) id<SPOverlayViewDelegate>delegate;

/// Toggle UI
//djs TODO: haven't worked on these methods yet
- (void)toggleOverlay;
- (void)showOverlayView;
- (void)hideOverlayView;
- (BOOL)isOverlayHidden;
- (void)showVideoInfo;
- (void)hideVideoInfo;

- (void)updateBufferedRange:(CMTimeRange)bufferedRange;
- (void)updateCurrentTime:(CMTime)time;
- (void)setDuration:(CMTime)duration;

- (void)setFrameOrDashboardEntry:(id)entity;
- (void)setAccentColor:(UIColor *)accent;
- (void)setRollEnabled:(BOOL)rollEnabled;
- (void)didLikeCurrentEntry:(BOOL)like;

@end
