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
#import "ShelbyStreamBrowseViewController.h"
#import "ShelbyDataMediator.h"
#import "SPVideoReel.h"
#import "TriageViewController.h"
#import "TwitterHandler.h"

// KP KP: TODO: Once ShelbyDataM takes care of TwitterHandler, there would be no need for the TwitterHandlerDelegate. It would be part of the ShelbyDataMediatorProtocol
@interface ShelbyBrain : NSObject <ShelbyDataMediatorProtocol, ShelbyBrowseProtocol, ShelbyStreamBrowseProtocol, ShelbyTriageProtocol, SPVideoReelDelegate, ShelbyHomeDelegate, TwitterHandlerDelegate>

@property (strong, nonatomic) ShelbyHomeViewController *homeVC;

- (void)setup;

- (void)handleDidBecomeActive;
- (void)handleLocalNotificationReceived:(UILocalNotification *)notification;

@end
