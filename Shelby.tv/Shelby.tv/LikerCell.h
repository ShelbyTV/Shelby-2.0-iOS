//
//  LikerCell.h
//  Shelby.tv
//
//  Created by Keren on 12/3/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "User.h"

@protocol LikerCellDelegate
- (void)toggleFollowForUser:(User *)user;
@end

@interface LikerCell : UITableViewCell
@property (nonatomic, weak) id<LikerCellDelegate> delegate;

- (void)setupCellForLiker:(User *)user;
@end
