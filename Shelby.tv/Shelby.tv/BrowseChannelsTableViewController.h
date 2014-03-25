//
//  BrowseChannelsTableViewController.h
//  Shelby.tv
//
//  Created by Dan Spinosa on 1/20/14.
//  Copyright (c) 2014 Shelby TV, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ShelbyUserEducationViewController.h"

@protocol BrowseChannelsTableViewDelegate <NSObject>
- (void)userProfileWasTapped:(NSString *)userID;
@end

@interface BrowseChannelsTableViewController : UITableViewController
@property (strong, nonatomic) ShelbyUserEducationViewController *userEducationVC;
@property (nonatomic, assign) id<BrowseChannelsTableViewDelegate> delegate;
@end
