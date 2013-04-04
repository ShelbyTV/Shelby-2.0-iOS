//
//  SPVideoReel.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 11/1/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

#import "SPModel.h"
#import "AuthorizationViewController.h"

@class SPVideoPlayer, SPOverlayView;

@interface SPVideoReel : GAITrackedViewController <UIScrollViewDelegate, UIAlertViewDelegate, AuthorizationDelegate, UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic) UITapGestureRecognizer *toggleOverlayGesuture;
@property (nonatomic) UIButton *airPlayButton;
@property (assign, nonatomic) GroupType groupType;
@property (copy, nonatomic) NSString *groupTitle;

- (void)loadWithGroupType:(GroupType)groupType
               groupTitle:(NSString *)title
           andVideoFrames:(NSMutableArray *)videoFrames;

- (void)loadWithGroupType:(GroupType)groupType
               groupTitle:(NSString *)title
              videoFrames:(NSMutableArray *)videoFrames
            andCategoryID:(NSString *)categoryID;

/// Update Methods
- (void)extractVideoForVideoPlayer:(NSUInteger)position;
- (void)currentVideoDidFinishPlayback;

/// Storage Methods
- (void)storeLoadedVideoPlayer:(SPVideoPlayer *)player;

- (IBAction)itemButtonAction:(id)sender;
- (IBAction)restartPlaybackButtonAction:(id)sender;
- (IBAction)scrub:(id)sender;
- (IBAction)beginScrubbing:(id)sender;
- (IBAction)endScrubbing:(id)sender;

@end
