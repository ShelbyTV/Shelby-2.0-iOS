//
//  SPOverlayView.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 11/28/12.
//  Copyright (c) 2012 Shelby TV. All rights reserved.
//

@interface SPOverlayView : UIView

@property (weak, nonatomic) IBOutlet UIView *airPlayView; // KP KP: TODO: add this button to nib!
@property (weak, nonatomic) IBOutlet UITapGestureRecognizer *scrubberGesture;

/// Toggle UI
//djs TODO: haven't worked on these methods yet
- (void)toggleOverlay;
- (void)showOverlayView;
- (void)hideOverlayView;
- (BOOL)isOverlayHidden;
- (void)showLikeNotificationView;
- (void)hideLikeNotificationView;
- (void)showVideoInfo;
- (void)hideVideoInfo;
- (void)rescheduleOverlayTimer;

- (void)updateBufferedRange:(CMTimeRange)bufferedRange;
- (void)updateCurrentTime:(CMTime)time;
- (void)setDuration:(CMTime)duration;

- (void)setFrameOrDashboardEntry:(id)entity;
- (void)setAccentColor:(UIColor *)accent;

@end
