//
//  SPOverlayView.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 11/28/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

@interface SPOverlayView : UIView

@property (weak, nonatomic) IBOutlet UILabel *categoryTitleLabel;
@property (weak, nonatomic) IBOutlet UIScrollView *videoListScrollView;
@property (weak, nonatomic) IBOutlet UIView *airPlayView; // KP KP: TODO: add this button to nib!
@property (weak, nonatomic) IBOutlet UILabel *videoTitleLabel;
@property (weak, nonatomic) IBOutlet TopAlignedLabel *videoCaptionLabel;
@property (weak, nonatomic) IBOutlet UIImageView *userImageView;
@property (weak, nonatomic) IBOutlet UILabel *nicknameLabel;
@property (weak, nonatomic) IBOutlet UIButton *shareButton;
@property (weak, nonatomic) IBOutlet UIButton *restartPlaybackButton;
@property (weak, nonatomic) IBOutlet UIImageView *likeNotificationView;
@property (weak, nonatomic) IBOutlet UIProgressView *bufferProgressView;
@property (weak, nonatomic) IBOutlet UIProgressView *elapsedProgressView;
@property (weak, nonatomic) IBOutlet UILabel *elapsedTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *totalDurationLabel;
@property (weak, nonatomic) IBOutlet UIView *scrubberContainerView;
@property (weak, nonatomic) IBOutlet UIView *scrubberTouchView;
@property (weak, nonatomic) IBOutlet UIButton *versionButton;

@property (weak, nonatomic) IBOutlet UITapGestureRecognizer *scrubberGesture;

/// Toggle UI
- (void)toggleOverlay;
- (void)showOverlayView;
- (void)hideOverlayView;
- (BOOL)isOverlayHidden;
- (void)showLikeNotificationView;
- (void)hideLikeNotificationView;
- (void)showVideoAndChannelInfo;
- (void)hideVideoAndChannelInfo;
- (void)rescheduleOverlayTimer;
- (void)togglePlaylist:(UISwipeGestureRecognizer *)gesture;

@end
