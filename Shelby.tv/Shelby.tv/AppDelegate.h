//
//  AppDelegate.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 10/17/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (nonatomic) UIWindow *window;
@property (nonatomic, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, readonly) NSManagedObjectContext *context;

/// Authentication Methods
- (void)performCleanIfUserDidAuthenticate;
- (void)userIsAuthorized;
- (void)logout;

/// Core Data Methods
- (void)mergeChanges:(NSNotification *)notification;
- (void)dumpAllData;

@end
