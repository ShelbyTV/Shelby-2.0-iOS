//
//  ShelbyNavBarViewController.h
//  Shelby.tv
//
//  Created by Daniel Spinosa on 7/9/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyViewController.h"

@class ShelbyNavBarViewController;

@protocol ShelbyNavBarDelegate <NSObject>

- (void)navBarViewControllerStreamWasTapped:(ShelbyNavBarViewController *)navBarVC;
- (void)navBarViewControllerLikesWasTapped:(ShelbyNavBarViewController *)navBarVC;
- (void)navBarViewControllerSharesWasTapped:(ShelbyNavBarViewController *)navBarVC;
- (void)navBarViewControllerCommunityWasTapped:(ShelbyNavBarViewController *)navBarVC;

@end

@interface ShelbyNavBarViewController : ShelbyViewController

@property (nonatomic, weak) id<ShelbyNavBarDelegate> delegate;

@end
