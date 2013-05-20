//
//  AppDelegate.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 10/17/12.
//  Copyright (c) 2012 Shelby TV. All rights reserved.
//

@class SPVideoDownloader;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (nonatomic) UIWindow *window;
//djs pretty sure we *never* need to hold on to the context... you just get it from a managed object
//@property (nonatomic, readonly) NSManagedObjectContext *context;

/// Add/remove dataUtilities hash
//djs don't think we should have this stuff
//- (void)addHash:(NSNumber *)hash;
//- (void)removeHash:(NSNumber *)hash;

/// Authentication Methods
//djs does this need to be explicit?  If so, do we really mean "authorized" ?
//- (void)userIsAuthorized;
//djs moved skeleton to ShelbyDataMediator
//- (void)logout;

/// Offline Methods
//djs TODO: manage video downloading completely outside of AppDelegate
//probably have SPVideoDownloader do it all, used by ShelbyAppBrain
- (void)downloadVideo:(Video *)video;
- (void)addVideoDownloader:(SPVideoDownloader *)videoDownloader;
- (void)removeVideoDownloader:(SPVideoDownloader *)videoDownloader;

/// Core Data Methods
//djs if anything, this is a private member of ShelbyDataMediator
//- (void)mergeChanges:(NSNotification *)notification;
//djs what do we need this for?
// - (void)dumpAllData;

@end
