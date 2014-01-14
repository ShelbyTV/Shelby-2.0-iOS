//
//  ShelbyTopContainerViewController.h
//  Shelby.tv
//
//  Created by Keren on 1/8/14.
//  Copyright (c) 2014 Shelby TV, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DisplayChannel.h"
#import "ShelbyNavigationViewController.h"
#import "ShelbyUserInfoViewController.h"
#import "User.h"

@interface ShelbyTopContainerViewController : UIViewController
@property (nonatomic, strong) User *currentUser;

- (void)pushViewController:(UIViewController *)viewController;
- (void)pushUserProfileViewController:(ShelbyUserInfoViewController *)viewController;

@property (nonatomic, assign) id<ShelbyNavigationProtocol> topNavigationDelegate;
@end
