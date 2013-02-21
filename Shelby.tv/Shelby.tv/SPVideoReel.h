//
//  SPVideoReel.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 11/1/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

#import "SPModel.h"

@class SPVideoPlayer, SPOverlayView;

@interface SPVideoReel : UIViewController <UIScrollViewDelegate>

@property (nonatomic) UITapGestureRecognizer *toggleOverlayGesuture;
@property (nonatomic) UIButton *airPlayButton;
@property (assign, nonatomic) CategoryType categoryType;

/// Initialization
- (id)initWithCategoryType:(CategoryType)categoryType
             categoryTitle:(NSString *)title
            andVideoFrames:(NSArray *)videoFrames;

- (id)initWithCategoryType:(CategoryType)categoryType
             categoryTitle:(NSString *)title
               videoFrames:(NSArray *)videoFrames
              andChannelID:(NSString *)channelID;

/// Update Methods
- (void)extractVideoForVideoPlayer:(NSUInteger)position;
- (void)currentVideoDidFinishPlayback;

/// Storage Methods
- (void)storeLoadedVideoPlayer:(SPVideoPlayer *)player;

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
