//
//  ShelbyNotificationCenterViewController.h
//  Shelby.tv
//
//  Created by Keren on 12/16/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyViewController.h"

@protocol ShelbyNotificationDelegate <NSObject>
- (void)userProfileWasTapped:(NSString *)userID;
- (void)videoWasTapped:(NSString *)videoID;
@end

@interface ShelbyNotificationCenterViewController : ShelbyViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, assign) id<ShelbyNotificationDelegate> delegate;

@end
