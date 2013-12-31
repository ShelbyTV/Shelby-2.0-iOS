//
//  SettingsViewController.h
//  Shelby.tv
//
//  Created by Keren on 4/24/13.
//  Copyright (c) 2013 Shelby TV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "User.h"
#import <MessageUI/MessageUI.h>
#import "UserPreferencesCell.h"

@protocol SettingsViewDelegate <NSObject>
- (void)logoutUser;
- (void)connectToFacebook;
- (void)connectToTwitter;
- (void)enablePushNotifications:(BOOL)enable;
@optional
- (void)launchMyRoll;
@end

@interface SettingsViewController : UIViewController <UIAlertViewDelegate, UITableViewDataSource, UITableViewDelegate, MFMailComposeViewControllerDelegate, UserPreferencesCellDelegate>

@property (nonatomic, strong) User *user;
@property (nonatomic, weak) id<SettingsViewDelegate> delegate;

- (id)initWithUser:(User *)user;
- (id)initWithUser:(User *)user andNibName:(NSString *)nibName;

@end
