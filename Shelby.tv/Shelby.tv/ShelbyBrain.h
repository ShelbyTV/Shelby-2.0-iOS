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
#import "ShelbyDataMediator.h"

@interface ShelbyBrain : NSObject <ShelbyDataMediatorProtocol>

@property (strong, nonatomic) BrowseViewController *browseVC;

- (void)setup;

- (void)handleDidBecomeActive;

@end
