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
@property (nonatomic, weak) id brainAsDelegate;

- (void)setEntries:(NSArray *)channelEntries forChannel:(DisplayChannel *)channel;

- (void)launchPlayerForChannel:(DisplayChannel *)channel atIndex:(NSInteger)index;
- (void)animateLaunchPlayerForChannel:(DisplayChannel *)channel atIndex:(NSInteger)index;
- (void)animateDismissPlayerForChannel:(DisplayChannel *)channel;
- (void)dismissPlayer;
@end
