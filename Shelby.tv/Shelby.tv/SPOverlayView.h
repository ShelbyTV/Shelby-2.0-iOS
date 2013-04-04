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
@property (weak, nonatomic) IBOutlet UILabel *elapsedTimelabel;
@property (weak, nonatomic) IBOutlet UILabel *totalDurationlabel;
@property (weak, nonatomic) IBOutlet UIView *scrubberContainerView;

/// Toggle UI
- (void)toggleOverlay;
- (void)showOverlayView;
- (void)hideOverlayView;
- (BOOL)isOverlayHidden;
- (void)showLikeNotificationView;
- (void)hideLikeNotificationView;
- (void)showVideoList;
- (void)hideVideoList;

- (void)rescheduleOverlayTimer;

@end
