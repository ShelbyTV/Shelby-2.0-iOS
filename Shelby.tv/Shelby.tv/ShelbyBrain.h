//
//  ShelbyBrain.h
//  Shelby.tv
//
//  Created by Daniel Spinosa on 5/1/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//
//  Single instance, created by AppDelegate, runs the show.

#import <Foundation/Foundation.h>
#import "LoginViewController.h"
#import "SettingsViewController.h"
#import "ShelbyHomeViewController.h"
#import "ShelbyStreamBrowseViewController.h"
#import "SignupFlowNavigationViewController.h"
#import "ShelbyDataMediator.h"
#import "ShelbyLikersViewController.h"
#import "ShelbyUserProfileViewController.h"
#import "SPVideoReel.h"
#import "TwitterHandler.h"
#import "WelcomeViewController.h"

extern NSString * const kShelbyBrainFetchNotificationEntriesDidCompleteNotification;
extern NSString * const kShelbyBrainFetchEntriesDidCompleteForChannelNotification;
extern NSString * const kShelbyBrainFetchEntriesDidCompleteForChannelWithErrorNotification;
extern NSString * const kShelbyBrainFocusOnEntityNotification;
extern NSString * const kShelbyBrainDidBecomeActiveNotification;
extern NSString * const kShelbyBrainWillResignActiveNotification;
extern NSString * const kShelbyBrainDismissVideoReelNotification;
extern NSString * const kShelbyBrainDidAutoadvanceNotification;
extern NSString * const kShelbyBrainSetEntriesNotification;

extern NSString * const kShelbyBrainChannelKey;
extern NSString * const kShelbyBrainChannelEntriesKey;
extern NSString * const kShelbyBrainCachedKey;
extern NSString * const kShelbyBrainEntityKey;

// KP KP: TODO: Once ShelbyDataM takes care of TwitterHandler, there would be no need for the TwitterHandlerDelegate. It would be part of the ShelbyDataMediatorProtocol
@interface ShelbyBrain : NSObject <ShelbyDataMediatorProtocol, ShelbyStreamBrowseManagementDelegate, SPVideoReelDelegate, ShelbyHomeDelegate, ShelbyUserProfileDelegate, TwitterHandlerDelegate, SignupFlowNavigationViewDelegate, UIActionSheetDelegate, LoginViewControllerDelegate, SettingsViewDelegate, WelcomeViewDelegate, ShelbyLikersViewDelegate>

@property (nonatomic) UIWindow *mainWindow;

- (void)handleDidBecomeActive;
- (void)handleWillResignActive;
- (void)handleDidFinishLaunching;
- (void)handleLocalNotificationReceived:(UILocalNotification *)notification;
- (void)performBackgroundFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler;

@end
