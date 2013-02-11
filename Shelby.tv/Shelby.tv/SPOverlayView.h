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
@property (weak, nonatomic) IBOutlet UIButton *shareButton;
@property (weak, nonatomic) IBOutlet BigButton *playButton;
@property (weak, nonatomic) IBOutlet UIView *airPlayView;
@property (weak, nonatomic) IBOutlet UISlider *scrubber;
@property (weak, nonatomic) IBOutlet UILabel *scrubberTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *videoTitleLabel;
@property (weak, nonatomic) IBOutlet TopAlignedLabel *videoCaptionLabel;
@property (weak, nonatomic) IBOutlet UIImageView *userImageView;
@property (weak, nonatomic) IBOutlet UILabel *nicknameLabel;
@property (weak, nonatomic) IBOutlet UIButton *restartPlaybackButton;

- (void)toggleOverlay;
- (void)showOverlay;
- (void)hideOverlay;

@end
