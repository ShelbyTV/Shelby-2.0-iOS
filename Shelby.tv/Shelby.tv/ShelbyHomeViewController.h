//
//  ShelbyHomeViewController.h
//  Shelby.tv
//
//  Created by Keren on 5/1/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BrowseViewController.h"
#import "User.h"

@interface ShelbyHomeViewController : UIViewController

@property (nonatomic, strong) NSArray *channels;
@property (nonatomic, strong) User *currentUser;
// KP KP: Better way to send the delegete to the views below?
@property (nonatomic, weak) id browseAndVideoReelDelegate;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *channelsLoadingActivityIndicator;

- (NSInteger)indexOfItem:(id)item inChannel:(DisplayChannel *)channel;

- (void)setEntries:(NSArray *)channelEntries forChannel:(DisplayChannel *)channel;
- (void)addEntries:(NSArray *)newChannelEntries toEnd:(BOOL)shouldAppend ofChannel:(DisplayChannel *)channel;
- (NSArray *)entriesForChannel:(DisplayChannel *)channel;

- (void)refreshActivityIndicatorForChannel:(DisplayChannel *)channel shouldAnimate:(BOOL)shouldAnimate;

// KP KP: TODO: merge these two methods. With an :animated property
- (void)launchPlayerForChannel:(DisplayChannel *)channel atIndex:(NSInteger)index;
- (void)animateLaunchPlayerForChannel:(DisplayChannel *)channel atIndex:(NSInteger)index;

- (void)animateDismissPlayerForChannel:(DisplayChannel *)channel;
- (void)dismissPlayer;
@end
