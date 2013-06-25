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
#import "SPOverlayView.h"
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

@class SPVideoPlayer, SPOverlayView;

@interface SPVideoReel : ShelbyViewController <UIScrollViewDelegate, UIGestureRecognizerDelegate, SPVideoPlayerDelegate, SPOverlayViewDelegate, SPShareControllerDelegate>

@property (weak, nonatomic) id <SPVideoReelDelegate> delegate;
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

- (void)hideOverlayView;

@end
