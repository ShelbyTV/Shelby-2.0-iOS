//
//  SPVideoReel.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 11/1/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

@interface SPVideoReel : UIViewController <UIScrollViewDelegate>
{
    id _scrubberTimeObserver;
}

@property (assign, nonatomic) NSUInteger numberOfVideos;
@property (strong, nonatomic) id scrubberTimeObserver;
@property (strong, nonatomic) UIScrollView *videoScrollView;

- (id)initWithCategoryType:(CategoryType)categoryType categoryTitle:(NSString*)title andVideoFrames:(NSArray*)videoFrames;
- (void)currentVideoDidChangeToVideo:(NSUInteger)position;
- (void)extractVideoForVideoPlayer:(NSUInteger)position;

- (IBAction)homeButtonAction:(id)sender;
- (IBAction)playButtonAction:(id)sender;
- (IBAction)airplayButtonAction:(id)sender;
- (IBAction)shareButtonAction:(id)sender;
- (IBAction)itemButtonAction:(id)sender;
- (IBAction)restartPlaybackButtonAction:(id)sender;
- (IBAction)scrub:(id)sender;
- (IBAction)beginScrubbing:(id)sender;
- (IBAction)endScrubbing:(id)sender;

@end