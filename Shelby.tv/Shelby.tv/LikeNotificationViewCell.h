//
//  LikeNotificationViewCell.h
//  Shelby.tv
//
//  Created by Keren on 12/16/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FollowNotificationViewCell.h"

@class LikeNotificationViewCell;

@protocol LikeNotificationDelegate <FollowNotificationDelegate>
- (void)viewVideoWasTappedForNotificationCell:(LikeNotificationViewCell *)cell;
@end

@interface LikeNotificationViewCell : FollowNotificationViewCell
@property (nonatomic, weak) IBOutlet UIImageView *thumbnail;
@property (nonatomic, weak) id<LikeNotificationDelegate>delegate;
@property (nonatomic, strong) NSString *dashboardID;

- (IBAction)viewVideo:(id)sender;
@end
