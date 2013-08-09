//
//  SPVideoReel.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 11/1/12.
//  Copyright (c) 2012 Shelby TV. All rights reserved.
//

#import "DisplayChannel+Helper.h"
#import "AuthorizationViewController.h"
#import "ShelbyViewController.h"
#import "SPVideoPlayer.h"

@class SPVideoReel;

@protocol SPVideoReelDelegate <NSObject>
- (void)userDidSwitchChannelForDirectionUp:(BOOL)up;
- (void)userDidCloseChannelAtFrame:(Frame *)frame;
- (DisplayChannel *)displayChannelForDirection:(BOOL)up;
- (void)videoDidAutoadvance;
- (void)loadMoreEntriesInChannel:(DisplayChannel *)channel sinceEntry:(NSManagedObject *)entry;
- (BOOL)canRoll;
- (void)userAskForFacebookPublishPermissions;
- (void)userAskForTwitterPublishPermissions;
- (void)didChangePlaybackToEntity:(id<ShelbyVideoContainer>)entity inChannel:(DisplayChannel *)channel;
@end

@protocol VideoPlaybackDelegate <NSObject>
- (void)setVideoIsPlaying:(BOOL)videoIsPlaying;
- (void)setBufferedRange:(CMTimeRange)bufferedRange;
- (void)setCurrentTime:(CMTime)time;
- (void)setDuration:(CMTime)duration;
@end

@class SPVideoPlayer;

@interface SPVideoReel : ShelbyViewController <UIScrollViewDelegate, UIGestureRecognizerDelegate, SPVideoPlayerDelegate>

@property (nonatomic, weak) id<SPVideoReelDelegate> delegate;
@property (nonatomic, weak) id<VideoPlaybackDelegate> videoPlaybackDelegate;
@property (nonatomic, weak) UIView *airPlayView;
@property (nonatomic, strong) DisplayChannel *channel;
@property (nonatomic) UIButton *airPlayButton;
@property (assign, nonatomic) GroupType groupType;
@property (copy, nonatomic) NSString *groupTitle;

- (id)initWithChannel:(DisplayChannel *)channel
     andVideoEntities:(NSArray *)videoEntities
              atIndex:(NSUInteger)videoStartIndex;

- (void)shutdown;

//New API for use by playback control elements
//current player is actually playing
- (BOOL)isCurrentPlayerPlaying;
//current player isPlaying or will be playing asap w/o any outside help
- (BOOL)shouldCurrentPlayerBePlaying;
- (void)pauseCurrentPlayer;
- (void)playCurrentPlayer;
- (void)beginScrubbing;
- (void)endScrubbing;
- (void)scrubCurrentPlayerTo:(CGFloat)percent;
- (id<ShelbyVideoContainer>)getCurrentPlaybackEntity;
//for adding new entities
- (void)setDeduplicatedEntries:(NSArray *)deduplicatedEntries;

// using this to keep view in sync, not change playback
- (void)scrollTo:(CGPoint)contentOffset;
// using this to change playback
- (void)endDecelerating;

@end
