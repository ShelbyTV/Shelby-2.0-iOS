//
//  SPOverlayView.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 11/28/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

@interface SPOverlayView : UIView <UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet UIButton *homeButton;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIView *controlBarView;
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet UIView *currentVideoInfoView;
@property (weak, nonatomic) IBOutlet UIScrollView *videoListScrollView;
@property (weak, nonatomic) IBOutlet UIButton *shareButton;
@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet UIButton *airPlayButton;

@end