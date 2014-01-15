//
//  ShelbyTopLevelNavigationViewController.h
//  Shelby.tv
//
//  Created by Keren on 1/9/14.
//  Copyright (c) 2014 Shelby TV, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SettingsViewController.h"
#import "User.h"

@interface ShelbyTopLevelNavigationViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, SettingsViewDelegate>
@property (nonatomic, strong) User *currentUser;
@end
