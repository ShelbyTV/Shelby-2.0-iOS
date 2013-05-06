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

@protocol ShelbyBrowseProtocol <NSObject>

- (void)userPressedChannel:(DisplayChannel *)channel atItem:(id)item;

@end

@protocol ShelbyPlayerProtocol;

// KP KP: TODO: right now, browseVC is the delegate of the SPVideoReel. Need to be changed - the brain should be the delegate
@interface BrowseViewController : GAITrackedViewController <UICollectionViewDataSource, UICollectionViewDelegate, UITableViewDataSource, SPVideoReelDelegate, UITableViewDelegate, AuthorizationDelegate, UIPopoverControllerDelegate>

@property (weak, nonatomic) IBOutlet UIButton *toggleSecretButton;
@property (weak, nonatomic) id<ShelbyBrowseProtocol> browseDelegate;

//data model: Array of DisplayChannel
@property (nonatomic, strong) NSArray *channels;

/// Action Methods
- (IBAction)toggleSecretModes:(id)sender;

/// DataSource Methods
// djs: TODO: this stuff should be handed to me
//- (void)fetchAllChannels;

- (void)setEntries:(NSArray *)entries forChannel:(DisplayChannel *)channel;
- (void)refreshActivityIndicatorForChannel:(DisplayChannel *)channel shouldAnimate:(BOOL)shouldAnimate;

/// Lanuch Player
- (void)launchMyRollPlayer;
- (void)launchMyLikesPlayer;

- (void)dismissPopover;

@end
