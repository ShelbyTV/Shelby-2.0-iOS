//
//  ShelbyUserFollowingViewController.h
//  Shelby.tv
//
//  Created by Dan Spinosa on 1/23/14.
//  Copyright (c) 2014 Shelby TV, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "User.h"

//TODO: rename this protocol now that we're sharing it or refactor
@protocol ShelbyStreamInfoProtocol;

@interface ShelbyUserFollowingViewController : UITableViewController

@property (strong, nonatomic) User *user;

@property (nonatomic, assign) id<ShelbyStreamInfoProtocol> delegate;

@end
