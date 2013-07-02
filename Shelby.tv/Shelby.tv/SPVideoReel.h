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
#import "SPShareController.h"
#import "SPVideoPlayer.h"

typedef NS_ENUM(NSUInteger, SPTutorialMode)
{
    SPTutorialModeNone,
    SPTutorialModeShow,
    SPTutorialModeDoubleTap,
    SPTutorialModeSwipeLeft,
    SPTutorialModeSwipeUp,
    SPTutorialModePinch
};

@class SPVideoReel;

@protocol SPVideoReelDelegate <NSObject>
- (void)userDidSwitchChannelForDirectionUp:(BOOL)up;
- (void)userDidCloseChannelAtFrame:(Frame *)frame;
- (DisplayChannel *)displayChannelForDirection:(BOOL)up;
- (void)videoDidFinishPlaying;
- (SPTutorialMode)tutorialModeForCurrentPlayer;
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

@class SPVideoPlayer, SPOverlayView;

@interface SPVideoReel : ShelbyViewController <UIScrollViewDelegate, UIGestureRecognizerDelegate, SPVideoPlayerDelegate, SPShareControllerDelegate>

@property (nonatomic, weak) id<SPVideoReelDelegate> delegate;
@property (nonatomic, weak) id<VideoPlaybackDelegate> videoPlaybackDelegate;
@property (nonatomic, weak) UIView *airPlayView;
@property (nonatomic, strong) DisplayChannel *channel;
@property (nonatomic) UITapGestureRecognizer *toggleOverlayGesuture;
@property (nonatomic) UIButton *airPlayButton;
@property (assign, nonatomic) GroupType groupType;
@property (copy, nonatomic) NSString *groupTitle;

- (id)initWithChannel:(DisplayChannel *)channel
     andVideoEntities:(NSArray *)videoEntities
              atIndex:(NSUInteger)videoStartIndex;

- (void)setEntries:(NSArray *)entries;

- (void)shutdown;

- (void)videoDoubleTapped;

- (void)pauseCurrentPlayer;
- (void)playCurrentPlayer;

- (void)hideOverlayView;

// using this to keep view in sync, not change playback
- (void)scrollTo:(CGPoint)contentOffset;
// using this to change playback
- (void)endDecelerating;

@end
