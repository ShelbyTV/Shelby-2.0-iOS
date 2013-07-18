//
//  ShelbyNavBarViewController.h
//  Shelby.tv
//
//  Created by Daniel Spinosa on 7/9/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyViewController.h"
#import "User+Helper.h"

@class ShelbyNavBarViewController;

@protocol ShelbyNavBarDelegate <NSObject>

- (void)navBarViewControllerStreamWasTapped:(ShelbyNavBarViewController *)navBarVC;
- (void)navBarViewControllerLikesWasTapped:(ShelbyNavBarViewController *)navBarVC;
- (void)navBarViewControllerSharesWasTapped:(ShelbyNavBarViewController *)navBarVC;
- (void)navBarViewControllerCommunityWasTapped:(ShelbyNavBarViewController *)navBarVC;
- (void)navBarViewControllerSettingsWasTapped:(ShelbyNavBarViewController *)navBarVC;
- (void)navBarViewControllerLoginWasTapped:(ShelbyNavBarViewController *)navBarVC;

@end

@interface ShelbyNavBarViewController : ShelbyViewController

//our model, used to determine which rows we display
@property (nonatomic, strong) User *currentUser;

@property (nonatomic, weak) id<ShelbyNavBarDelegate> delegate;

- (void)didNavigateToCommunityChannel;
- (void)didNavigateToUsersStream;
- (void)didNavigateToUsersLikes;
- (void)didNavigateToUsersShares;

@end
