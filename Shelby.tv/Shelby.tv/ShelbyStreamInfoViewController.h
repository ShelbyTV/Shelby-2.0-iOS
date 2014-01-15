//
//  ShelbyStreamInfoViewController.h
//  Shelby.tv
//
//  Created by Keren on 1/8/14.
//  Copyright (c) 2014 Shelby TV, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DisplayChannel.h"
#import "ShelbyStreamEntryCell.h"
#import "ShelbyVideoReelViewController.h"

@protocol ShelbyStreamInfoProtocol <NSObject>
- (void)userProfileWasTapped:(NSString *)userID;
- (void)openLikersViewForVideo:(Video *)video withLikers:(NSMutableOrderedSet *)likers;
- (void)userLikedVideoFrame:(Frame *)videoFrame;
- (void)shareVideoFrame:(Frame *)videoFrame;
@end

@interface ShelbyStreamInfoViewController : UIViewController <ShelbyStreamEntryProtocol, UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) DisplayChannel *displayChannel;
@property (nonatomic, strong) ShelbyVideoReelViewController *videoReelVC;
@property (nonatomic, assign) id<ShelbyStreamInfoProtocol> delegate;

@end
