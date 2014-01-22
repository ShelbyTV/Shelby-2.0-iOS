//
//  ShelbyNavigationViewController.h
//  Shelby.tv
//
//  Created by Keren on 1/8/14.
//  Copyright (c) 2014 Shelby TV, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DisplayChannel.h"
#import "ShelbyStreamInfoViewController.h"
#import "ShelbyUserInfoViewController.h"
#import "ShelbyVideoReelViewController.h"
#import "User.h"

@protocol ShelbyNavigationProtocol <NSObject>
- (void)userProfileWasTapped:(NSString *)userID;
- (void)openLikersViewForVideo:(Video *)video withLikers:(NSMutableOrderedSet *)likers;
- (void)logoutUser;
@end

@interface ShelbyNavigationViewController : UINavigationController <ShelbyStreamInfoProtocol>
@property (nonatomic, strong) ShelbyVideoReelViewController *videoReelVC;
@property (nonatomic, strong) User *currentUser;
@property (nonatomic, weak) id<ShelbyNavigationProtocol> topContainerDelegate;

- (void)pushViewController:(UIViewController *)viewController;
- (void)pushUserProfileViewController:(ShelbyUserInfoViewController *)viewController;
- (ShelbyStreamInfoViewController *)pushViewControllerForChannel:(DisplayChannel *)channel;

@end
