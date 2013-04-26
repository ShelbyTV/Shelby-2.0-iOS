//
//  SPVideoReel.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 11/1/12.
//  Copyright (c) 2012 Shelby TV. All rights reserved.
//

#import "SPModel.h"
#import "SPChannelDisplay.h"
#import "AuthorizationViewController.h"

typedef NS_ENUM(NSUInteger, SPTutorialMode)
{
    SPTutorialModeNone,
    SPTutorialModeShow,
    SPTutorialModeDoubleTap,
    SPTutorialModeSwipeLeft,
    SPTutorialModeSwipeUp,
    SPTutorialModePinch
};

@protocol SPVideoReelDelegate <NSObject>

- (void)userDidSwitchChannel:(SPVideoReel *)videoReel direction:(BOOL)up;
- (void)userDidCloseChannel:(SPVideoReel *)videoReel;
- (SPChannelDisplay *)channelDisplayForDirection:(BOOL)up;
@end

@class SPVideoPlayer, SPOverlayView;

@interface SPVideoReel : GAITrackedViewController <UIScrollViewDelegate, UIGestureRecognizerDelegate>

@property (weak, nonatomic) id <SPVideoReelDelegate> delegate;
@property (nonatomic) UITapGestureRecognizer *toggleOverlayGesuture;
@property (nonatomic) UIButton *airPlayButton;
@property (assign, nonatomic) GroupType groupType;
@property (copy, nonatomic) NSString *groupTitle;
@property (assign, nonatomic) SPTutorialMode tutorialMode;

- (id)initWithGroupType:(GroupType)groupType
             groupTitle:(NSString *)groupTitle
            videoFrames:(NSMutableArray *)videoFrames
     andVideoStartIndex:(NSUInteger)videoStartIndex;

- (id)initWithGroupType:(GroupType)groupType
             groupTitle:(NSString *)groupTitle
            videoFrames:(NSMutableArray *)videoFrames
        videoStartIndex:(NSUInteger)videoStartIndex
           andChannelID:(NSString *)channelID;

/// Update Methods
- (void)extractVideoForVideoPlayer:(NSUInteger)position;
- (void)currentVideoDidFinishPlayback;

/// Storage Methods
- (void)storeLoadedVideoPlayer:(SPVideoPlayer *)player;

/// Action Methods
- (IBAction)restartPlaybackButtonAction:(id)sender;

- (void)cleanup;

/// Tutorial
- (void)videoDoubleTapped;
@end
