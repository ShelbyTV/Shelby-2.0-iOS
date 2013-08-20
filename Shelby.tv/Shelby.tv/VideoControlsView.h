//
//  VideoControlsView.h
//  Shelby.tv
//
//  Created by Daniel Spinosa on 7/1/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//
//  This view may be placed on top of other scrolling views without
//  interfering with their scrolling.  Only touches on actual subview
//  elements will considered.  Touches on background will effectively
//  be passed through. 

#import <UIKit/UIKit.h>

@interface VideoControlsView : UIView

//-- playback controls --
@property (weak, nonatomic) IBOutlet UIButton *playPauseButton;
//a 31x23 placholder
@property (weak, nonatomic) IBOutlet UIView *airPlayView;
@property (weak, nonatomic) IBOutlet UILabel *currentTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *durationLabel;
@property (weak, nonatomic) IBOutlet UIProgressView *bufferProgressView;
@property (weak, nonatomic) IBOutlet UIButton *scrubheadButton;

//-- actions --
@property (weak, nonatomic) IBOutlet UIButton *likeButton;
@property (weak, nonatomic) IBOutlet UIButton *unlikeButton;
@property (weak, nonatomic) IBOutlet UIButton *shareButton;


//---overlay
@property (weak, nonatomic) IBOutlet UIView *overlay;
@property (weak, nonatomic) IBOutlet UIView *separatorView;
// Adding a view? Be sure to update the controllers -viewDidLoad

- (void)positionScrubheadForPercent:(CGFloat)pct;
- (void)positionScrubheadForTouch:(UITouch *)touch;
- (CGFloat)playbackTargetPercentForTouch:(UITouch *)touch;

@end
