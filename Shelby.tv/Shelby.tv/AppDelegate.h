//
//  AppDelegate.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 10/17/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

@class SPVideoDownloader;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (nonatomic) UIWindow *window;
@property (nonatomic, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, readonly) NSManagedObjectContext *context;

/// Add/remove dataUtilities hash
- (void)addHash:(NSNumber *)hash;
- (void)removeHash:(NSNumber *)hash;

/// Authentication Methods
- (void)userIsAuthorized;
- (void)logout;

/// Offline Methods
- (void)downloadVideo:(Video *)video;
- (void)addVideoDownloader:(SPVideoDownloader *)videoDownloader;
- (void)removeVideoDownloader:(SPVideoDownloader *)videoDownloader;

/// Core Data Methods
- (void)mergeChanges:(NSNotification *)notification;
- (void)dumpAllData;

@end
