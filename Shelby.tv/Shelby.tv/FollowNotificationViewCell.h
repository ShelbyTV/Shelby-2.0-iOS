//
//  FollowNotificationViewCell.h
//  Shelby.tv
//
//  Created by Keren on 12/16/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
@class FollowNotificationViewCell;

@protocol FollowNotificationDelegate <NSObject>
- (void)viewUserWasTappedForNotificationCell:(FollowNotificationViewCell *)cell;
@end

@interface FollowNotificationViewCell : UITableViewCell
@property (nonatomic, weak) IBOutlet UIImageView *avatar;
@property (nonatomic, weak) IBOutlet UILabel *notificationText;
@property (nonatomic, weak) id<FollowNotificationDelegate>delegate;
@property (nonatomic, strong) NSString *userID;
@property (nonatomic, strong) NSString *userNickname;

- (IBAction)viewUser:(id)sender;
@end
