//
//  SettingsViewController.h
//  Shelby.tv
//
//  Created by Keren on 4/24/13.
//  Copyright (c) 2013 Shelby TV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "User.h"

@protocol SettingsViewDelegate <NSObject>
- (void)logoutUser;
- (void)connectToFacebook;
- (void)connectToTwitter;
- (void)launchMyRoll;
- (void)launchMyLikes;
@end

@interface SettingsViewController : UIViewController <UIAlertViewDelegate>

@property (nonatomic, strong) User *user;
@property (nonatomic, weak) id<SettingsViewDelegate> delegate;

- (id)initWithUser:(User *)user;

@end
