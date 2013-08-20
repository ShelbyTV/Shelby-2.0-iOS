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

- (void)navBarViewControllerWillExpand:(ShelbyNavBarViewController *)navBarVC;
- (void)navBarViewControllerWillContract:(ShelbyNavBarViewController *)navBarVC;
- (void)navBarViewControllerStreamWasTapped:(ShelbyNavBarViewController *)navBarVC selectionShouldChange:(BOOL)selectedNewRow;
- (void)navBarViewControllerLikesWasTapped:(ShelbyNavBarViewController *)navBarVC selectionShouldChange:(BOOL)selectedNewRow;
- (void)navBarViewControllerSharesWasTapped:(ShelbyNavBarViewController *)navBarVC selectionShouldChange:(BOOL)selectedNewRow;
- (void)navBarViewControllerCommunityWasTapped:(ShelbyNavBarViewController *)navBarVC selectionShouldChange:(BOOL)selectedNewRow;
- (void)navBarViewControllerSettingsWasTapped:(ShelbyNavBarViewController *)navBarVC selectionShouldChange:(BOOL)selectedNewRow;
- (void)navBarViewControllerSignupWasTapped:(ShelbyNavBarViewController *)navBarVC selectionShouldChange:(BOOL)selectedNewRow;

@end

@interface ShelbyNavBarViewController : ShelbyViewController

//our model, used to determine which rows we display
@property (nonatomic, strong) User *currentUser;

@property (nonatomic, weak) id<ShelbyNavBarDelegate> delegate;

- (void)didNavigateToCommunityChannel;
- (void)didNavigateToUsersStream;
- (void)didNavigateToUsersLikes;
- (void)didNavigateToUsersShares;
- (void)didNavigateToSettings;

- (void)returnSelectionToPreviousRow;

@end
