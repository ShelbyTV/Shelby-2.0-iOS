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

@protocol ShelbyTopContainerProtocol <NSObject>
- (void)userProfileWasTapped:(NSString *)userID;
- (void)openLikersViewForVideo:(Video *)video withLikers:(NSMutableOrderedSet *)likers;
//- (void)shareVideoFrame:(Frame *)videoFrame;
- (void)logoutUser;
@end

@interface ShelbyTopContainerViewController : UIViewController <ShelbyNavigationProtocol>
@property (nonatomic, strong) User *currentUser;
@property (nonatomic, assign) id<ShelbyTopContainerProtocol> masterDelegate;

- (void)pushViewController:(UIViewController *)viewController;
- (void)pushUserProfileViewController:(ShelbyUserInfoViewController *)viewController;
@end
