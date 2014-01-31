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
#import "ShelbyUserEducationViewController.h"
#import "ShelbyVideoReelViewController.h"
#import "ShelbyVideoContentBrowsingViewControllerProtocol.h"

@protocol ShelbyStreamInfoProtocol <NSObject>
- (void)userProfileWasTapped:(NSString *)userID;
- (void)openLikersViewForVideo:(Video *)video withLikers:(NSMutableOrderedSet *)likers;
@end

@interface ShelbyStreamInfoViewController : UIViewController <ShelbyStreamEntryProtocol, UITableViewDataSource, UITableViewDelegate, ShelbyVideoContentBrowsingViewControllerProtocol>
@property (nonatomic, strong) DisplayChannel *displayChannel;
@property (nonatomic, assign) BOOL shouldShowFollowChannels;
@property (nonatomic, strong) NSArray *singleVideoEntry;
@property (nonatomic, strong) ShelbyVideoReelViewController *videoReelVC;
@property (nonatomic, assign) id<ShelbyStreamInfoProtocol> delegate;
@property (strong, nonatomic) ShelbyUserEducationViewController *userEducationVC;
@end
