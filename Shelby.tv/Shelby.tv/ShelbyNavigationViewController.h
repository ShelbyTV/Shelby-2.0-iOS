//
//  ShelbyNavigationViewController.h
//  Shelby.tv
//
//  Created by Keren on 1/8/14.
//  Copyright (c) 2014 Shelby TV, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DisplayChannel.h"
#import "ShelbyVideoReelViewController.h"
#import "User.h"

@interface ShelbyNavigationViewController : UINavigationController
@property (nonatomic, strong) ShelbyVideoReelViewController *videoReelVC;
@property (nonatomic, strong) User *currentUser;

- (void)pushViewControllerForChannel:(DisplayChannel *)channel shouldInitializeVideoReel:(BOOL)shouldInitializeVideoReel;
@end
