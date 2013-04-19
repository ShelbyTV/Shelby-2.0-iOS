//
//  SPVideoReel.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 11/1/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

#import "SPModel.h"
#import "SPCategoryDisplay.h"
#import "AuthorizationViewController.h"

@protocol SPVideoReelDelegate <NSObject>

- (void)userDidSwitchChannel:(SPVideoReel *)videoReel direction:(BOOL)up;
- (void)userDidCloseChannel:(SPVideoReel *)videoReel;
- (SPCategoryDisplay *)categoryDisplayForDirection:(BOOL)up;
@end

@class SPVideoPlayer, SPOverlayView;

@interface SPVideoReel : GAITrackedViewController <UIScrollViewDelegate, UIGestureRecognizerDelegate>

@property (weak, nonatomic) id <SPVideoReelDelegate> delegate;
@property (nonatomic) UITapGestureRecognizer *toggleOverlayGesuture;
@property (nonatomic) UIButton *airPlayButton;
@property (assign, nonatomic) GroupType groupType;
@property (copy, nonatomic) NSString *groupTitle;
@property (assign, nonatomic) BOOL tutorialMode;

- (id)initWithGroupType:(GroupType)groupType
             groupTitle:(NSString *)groupTitle
            videoFrames:(NSMutableArray *)videoFrames
     andVideoStartIndex:(NSUInteger)videoStartIndex;

- (id)initWithGroupType:(GroupType)groupType
             groupTitle:(NSString *)groupTitle
            videoFrames:(NSMutableArray *)videoFrames
        videoStartIndex:(NSUInteger)videoStartIndex
          andCategoryID:(NSString *)categoryID;

/// Update Methods
- (void)extractVideoForVideoPlayer:(NSUInteger)position;
- (void)currentVideoDidFinishPlayback;

/// Storage Methods
- (void)storeLoadedVideoPlayer:(SPVideoPlayer *)player;

/// Action Methods
- (IBAction)restartPlaybackButtonAction:(id)sender;

- (void)cleanup;
@end
