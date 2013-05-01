//
//  BrowseViewController.h
//  Shelby.tv
//
//  Created by Keren on 2/13/13.
//  Copyright (c) 2013 Shelby TV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AuthorizationViewController.h"
#import "SPVideoReel.h"

@interface BrowseViewController : GAITrackedViewController <UICollectionViewDataSource, UICollectionViewDelegate, UITableViewDataSource, SPVideoReelDelegate, UITableViewDelegate, AuthorizationDelegate, UIPopoverControllerDelegate>

@property (weak, nonatomic) IBOutlet UIButton *toggleSecretButton;

/// Action Methods
- (IBAction)toggleSecretModes:(id)sender;

/// DataSource Methods
// djs: TODO: this stuff should be handed to me
//- (void)fetchAllChannels;

/// Lanuch Player
- (void)launchMyRollPlayer;
- (void)launchMyLikesPlayer;

- (void)dismissPopover;

@end
