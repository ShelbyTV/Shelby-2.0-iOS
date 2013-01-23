//
//  SPVideoReel.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 11/1/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

@class SPVideoPlayer, SPOverlayView;

@interface SPVideoReel : UIViewController <UIScrollViewDelegate>

@property (assign, nonatomic) CategoryType categoryType;
@property (strong, nonatomic) UITapGestureRecognizer *toggleOverlayGesuture;
@property (strong, nonatomic) UIButton *airPlayButton;

/// Initialization
- (id)initWithCategoryType:(CategoryType)categoryType
             categoryTitle:(NSString*)title
            andVideoFrames:(NSArray*)videoFrames;

/// Extract new video
- (void)extractVideoForVideoPlayer:(NSUInteger)position;

/// Update Methods
- (void)currentVideoDidFinishPlayback;

/// Action Methods
- (IBAction)homeButtonAction:(id)sender;
- (IBAction)playButtonAction:(id)sender;
- (IBAction)shareButtonAction:(id)sender;
- (IBAction)itemButtonAction:(id)sender;
- (IBAction)restartPlaybackButtonAction:(id)sender;
- (IBAction)scrub:(id)sender;
- (IBAction)beginScrubbing:(id)sender;
- (IBAction)endScrubbing:(id)sender;

@end