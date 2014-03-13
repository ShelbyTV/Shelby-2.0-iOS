//
//  SPVideoReelCollectionViewController.h
//  Shelby.tv
//
//  Created by Dan Spinosa on 3/6/14.
//  Copyright (c) 2014 Shelby TV, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SPVideoPlayer.h"

@class DisplayChannel;
@class Frame;
@class VideoReelBackdropView;

@protocol SPVideoReelDelegate <NSObject>
- (void)videoDidAutoadvance;
- (void)loadMoreEntriesInChannel:(DisplayChannel *)channel sinceEntry:(NSManagedObject *)entry;
- (BOOL)canRoll;
- (void)userAskForFacebookPublishPermissions;
- (void)userAskForTwitterPublishPermissions;
@optional
- (void)userDidRequestPlayCurrentPlayer;
@end

@protocol VideoPlaybackDelegate <NSObject>
- (void)setVideoIsPlaying:(BOOL)videoIsPlaying;
- (void)setBufferedRange:(CMTimeRange)bufferedRange;
- (void)setCurrentTime:(CMTime)time;
- (void)setDuration:(CMTime)duration;
@end

@interface SPVideoReelCollectionViewController : UICollectionViewController <SPVideoPlayerDelegate>
//model
@property (nonatomic, strong) DisplayChannel *channel;
@property (nonatomic, strong) NSArray *deduplicatedEntries;
//delegates
@property (nonatomic, weak) id<SPVideoReelDelegate> delegate;
@property (nonatomic, weak) id<VideoPlaybackDelegate> videoPlaybackDelegate;
//primary API
- (void)scrollForPlaybackAtIndex:(NSUInteger)idx forcingPlayback:(BOOL)forcePlayback animated:(BOOL)animatedScroll;
- (void)playCurrentPlayer;
- (BOOL)isCurrentPlayerPlaying;
- (void)pauseCurrentPlayer;
- (void)beginScrubbing;
- (void)scrubCurrentPlayerTo:(CGFloat)pct;
- (void)endScrubbing;
- (void)shutdown;
//utility API
- (void)addGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer;
//iPhone API
- (id<ShelbyVideoContainer>)getCurrentPlaybackEntity;
- (void)scrollTo:(CGPoint)contentOffset;
- (void)endDecelerating;
@property (nonatomic, readonly) BOOL shouldBePlaying;
//visual API
//set on iPad only (we adjust state of showing yes/no)
@property (nonatomic, strong) VideoReelBackdropView *backdropView;
@end
