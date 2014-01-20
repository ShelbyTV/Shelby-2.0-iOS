//
//  BrowseChannelCell.h
//  Shelby.tv
//
//  Created by Dan Spinosa on 1/20/14.
//  Copyright (c) 2014 Shelby TV, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Roll.h"
#import "User+Helper.h"

@interface BrowseChannelCell : UITableViewCell

@property (strong, nonatomic) User *user;
@property (strong, nonatomic) Roll *roll;

- (void)updateFollowStatus;

@end
