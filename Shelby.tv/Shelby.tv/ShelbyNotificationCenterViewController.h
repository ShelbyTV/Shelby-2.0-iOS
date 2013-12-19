//
//  ShelbyNotificationCenterViewController.h
//  Shelby.tv
//
//  Created by Keren on 12/16/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyViewController.h"
#import "FollowNotificationViewCell.h"
#import "LikeNotificationViewCell.h"


@protocol ShelbyNotificationDelegate <NSObject>
- (void)userProfileWasTapped:(NSString *)userID;
- (void)videoWasTapped:(NSString *)videoID;
- (void)unseenNotificationCountChanged;
@end

@interface ShelbyNotificationCenterViewController : ShelbyViewController <UITableViewDataSource, UITableViewDelegate, LikeNotificationDelegate, FollowNotificationDelegate>
@property (nonatomic, readonly, assign) NSInteger unseenNotifications;
@property (nonatomic, assign) id<ShelbyNotificationDelegate> delegate;

- (void)setNotificationEntries:(NSArray *)notificationEntries;
@end
