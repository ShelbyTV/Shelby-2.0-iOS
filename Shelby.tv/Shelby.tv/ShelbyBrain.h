//
//  ShelbyBrain.h
//  Shelby.tv
//
//  Created by Daniel Spinosa on 5/1/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//
//  Single instance, created by AppDelegate, runs the show.

#import <Foundation/Foundation.h>
#import "BrowseViewController.h"
#import "ShelbyHomeViewController.h"
#import "ShelbyDataMediator.h"
#import "SPVideoReel.h"

@interface ShelbyBrain : NSObject <ShelbyDataMediatorProtocol, ShelbyBrowseProtocol, SPVideoReelDelegate, ShelbyHomeDelegate>

@property (strong, nonatomic) ShelbyHomeViewController *homeVC;

- (void)setup;

- (void)handleDidBecomeActive;

@end
