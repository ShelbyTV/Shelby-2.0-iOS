//
//  SPVideoReel.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 11/1/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

@class SPVideoPlayer, SPOverlayView;

@interface SPVideoReel : UIViewController <UIScrollViewDelegate>

@property (assign, nonatomic) NSUInteger numberOfVideos;
@property (strong, nonatomic) UIScrollView *videoScrollView;
@property (strong, nonatomic) UITapGestureRecognizer *toggleOverlayGesuture;
@property (assign, nonatomic) CategoryType categoryType;
@property (strong, nonatomic) UIButton *airPlayButton;

/// Initialization
- (id)initWithCategoryType:(CategoryType)categoryType
             categoryTitle:(NSString*)title
            andVideoFrames:(NSArray*)videoFrames;

/// Extract new video
- (void)extractVideoForVideoPlayer:(NSUInteger)position;

/// Update UI and perform new extractions when videoScrollView or _overlay.videoList ScrollView is scrolled
- (void)currentVideoDidChangeToVideo:(NSUInteger)position;

/// UI Actions
- (IBAction)homeButtonAction:(id)sender;
- (IBAction)playButtonAction:(id)sender;
- (IBAction)shareButtonAction:(id)sender;
- (IBAction)itemButtonAction:(id)sender;
- (IBAction)restartPlaybackButtonAction:(id)sender;

/// Video Scrubber Methods
- (IBAction)scrub:(id)sender;
- (IBAction)beginScrubbing:(id)sender;
- (IBAction)endScrubbing:(id)sender;

@end