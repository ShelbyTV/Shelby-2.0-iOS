//
//  SPVideoReel.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 11/1/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

#import "SPModel.h"
#import "AuthorizationViewController.h"

@protocol SPVideoReelDelegate <NSObject>

- (void)userDidSwipeUpOnVideoReel:(UIGestureRecognizer *)gestureRecognizer;
- (void)userDidSwipeDownOnVideoReel:(UIGestureRecognizer *)gestureRecognizer;

@end

@class SPVideoPlayer, SPOverlayView;

@interface SPVideoReel : GAITrackedViewController <UIScrollViewDelegate, UIGestureRecognizerDelegate>

@property (weak, nonatomic) id <NSObject, SPVideoReelDelegate> delegate;
@property (nonatomic) UITapGestureRecognizer *toggleOverlayGesuture;
@property (nonatomic) UIButton *airPlayButton;
@property (assign, nonatomic) GroupType groupType;
@property (copy, nonatomic) NSString *groupTitle;

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

@end
