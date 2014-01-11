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
#import "ShelbyVideoReelViewController.h"
#import "User.h"

@protocol ShelbyNavigationProtocol <NSObject>
- (void)userProfileWasTapped:(NSString *)userID;
@end

@interface ShelbyNavigationViewController : UINavigationController <ShelbyStreamInfoProtocol>
@property (nonatomic, strong) ShelbyVideoReelViewController *videoReelVC;
@property (nonatomic, strong) User *currentUser;
@property (nonatomic, weak) id<ShelbyNavigationProtocol> masterDelegate;

- (void)pushViewController:(UIViewController *)viewController;
- (void)pushViewControllerForChannel:(DisplayChannel *)channel shouldInitializeVideoReel:(BOOL)shouldInitializeVideoReel;
@end
