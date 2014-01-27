//
//  ShelbyUserInfoViewController.h
//  Shelby.tv
//
//  Created by Keren on 1/10/14.
//  Copyright (c) 2014 Shelby TV, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ShelbyStreamInfoViewController.h"
#import "ShelbyVideoContentBrowsingViewControllerProtocol.h"
#import "SignupHeaderView.h"

@class ShelbyUserFollowingViewController;

@interface ShelbyUserInfoViewController : UIViewController <ShelbyVideoContentBrowsingViewControllerProtocol, SignupHeaderDelegate>
@property (nonatomic, strong) ShelbyStreamInfoViewController *streamInfoVC;
@property (nonatomic, strong) ShelbyUserFollowingViewController *followingVC;
@property (nonatomic, strong) User *user;

- (void)setupStreamInfoDisplayChannel:(DisplayChannel *)displayChannel;
@end
