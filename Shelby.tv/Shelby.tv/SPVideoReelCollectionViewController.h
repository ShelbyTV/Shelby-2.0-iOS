//
//  SPVideoReelCollectionViewController.h
//  Shelby.tv
//
//  Created by Dan Spinosa on 3/6/14.
//  Copyright (c) 2014 Shelby TV, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DisplayChannel;
@class VideoReelBackdropView;

//TODO: all the delegate work
//XXX TODO: pull the delegates into here when we kill SPVideoReel
#import "SPVideoReel.h"

@interface SPVideoReelCollectionViewController : UICollectionViewController <SPVideoPlayerDelegate>
//model
@property (nonatomic, strong) DisplayChannel *channel;
@property (nonatomic, strong) NSArray *deduplicatedEntries;
//delegates
@property (nonatomic, weak) id<SPVideoReelDelegate> delegate;
@property (nonatomic, weak) id<VideoPlaybackDelegate> videoPlaybackDelegate;
//primary API
- (void)scrollForPlaybackAtIndex:(NSUInteger)idx forcingPlayback:(BOOL)forcePlayback;
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
