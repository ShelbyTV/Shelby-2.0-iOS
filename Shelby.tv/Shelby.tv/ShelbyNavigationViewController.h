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

extern NSString * const kShelbyNavigateToSingleVideoEntryNotification;
extern NSString * const kShelbyNavigateToChannelKey;
extern NSString * const kShelbyNavigateToSingleVideoEntryArrayKey;
extern NSString * const kShelbyNavigateToTitleOverrideKey;

@protocol ShelbyNavigationProtocol <NSObject>
- (void)userProfileWasTapped:(NSString *)userID;
- (void)openLikersViewForVideo:(Video *)video withLikers:(NSMutableOrderedSet *)likers;
- (void)logoutUser;
@end

@interface ShelbyNavigationViewController : UINavigationController <ShelbyStreamInfoProtocol>
@property (nonatomic, strong) ShelbyVideoReelViewController *videoReelVC;
@property (nonatomic, strong) User *currentUser;
@property (nonatomic, weak) id<ShelbyNavigationProtocol> topContainerDelegate;
@property (nonatomic, assign) CGFloat bottomInsetForContainedScrollViews;

- (void)pushViewController:(UIViewController *)viewController;
- (void)pushUserProfileViewController:(ShelbyUserInfoViewController *)viewController;
- (ShelbyStreamInfoViewController *)pushViewControllerForChannel:(DisplayChannel *)channel titleOverride:(NSString *)titleOverride animated:(BOOL)animated;
- (ShelbyStreamInfoViewController *)pushViewControllerForChannel:(DisplayChannel *)channel singleVideoEntry:(NSArray *)singleVideoEntry titleOverride:(NSString *)titleOverride animated:(BOOL)animated;
- (ShelbyStreamInfoViewController *)pushViewControllerForChannel:(DisplayChannel *)channel titleOverride:(NSString *)titleOverride showUserEducationSections:(BOOL)showUserEducationSections animated:(BOOL)animated;
@end
