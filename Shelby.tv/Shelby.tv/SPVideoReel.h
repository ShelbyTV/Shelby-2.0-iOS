//
//  SPVideoReel.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 11/1/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

#import "SPModel.h"
#import "AuthorizationViewController.h"

@class SPVideoPlayer, SPOverlayView, GroupsMenuViewController;

@interface SPVideoReel : GAITrackedViewController <UIScrollViewDelegate, UIGestureRecognizerDelegate>

@property (nonatomic) UITapGestureRecognizer *toggleOverlayGesuture;
@property (nonatomic) UIButton *airPlayButton;
@property (assign, nonatomic) GroupType groupType;
@property (copy, nonatomic) NSString *groupTitle;
@property (nonatomic) GroupsMenuViewController *groupsMenuViewController;

- (id)initWithGroupType:(GroupType)groupType
             groupTitle:(NSString *)groupTitle
            videoFrames:(NSMutableArray *)videoFrames
     andVideoStartIndex:(NSUInteger)videoStartIndex;

- (id)initWithGroupType:(GroupType)groupType
             groupTitle:(NSString *)groupTitle
            videoFrames:(NSMutableArray *)videoFrames
        videoStartIndex:(NSUInteger)videoStartIndex
          andCategoryID:(NSString *)categoryID;

- (void)loadWithGroupType:(GroupType)groupType
               groupTitle:(NSString *)groupTitle
           andVideoFrames:(NSMutableArray *)videoFrames;

- (void)loadWithGroupType:(GroupType)groupType
               groupTitle:(NSString *)groupTitle
              videoFrames:(NSMutableArray *)videoFrames
            andCategoryID:(NSString *)categoryID;

/// Update Methods
- (void)extractVideoForVideoPlayer:(NSUInteger)position;
- (void)currentVideoDidFinishPlayback;

/// Storage Methods
- (void)storeLoadedVideoPlayer:(SPVideoPlayer *)player;

/// Action Methods
- (IBAction)restartPlaybackButtonAction:(id)sender;

@end
