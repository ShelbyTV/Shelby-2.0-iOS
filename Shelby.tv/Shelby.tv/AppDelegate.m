//
//  AppDelegate.m
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 10/17/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

#import "AppDelegate.h"
#import "MeViewController.h"

@interface AppDelegate ()

@property (nonatomic) NSManagedObjectModel *managedObjectModel;
@property (nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic) NSTimer *pollAPITimer;
@property (assign, nonatomic) NSUInteger pollAPICounter;

- (void)pingAllRoutes;
- (void)pollAPI;
- (void)postAuthorizationNotification;
- (void)analytics;

@end

@implementation AppDelegate

#pragma mark - UIApplicationDelegate Methods
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    
    // Create UIWindow and rootViewController
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    MeViewController *meViewController = [[MeViewController alloc] initWithNibName:@"MeViewController" bundle:nil];
    self.window.rootViewController = meViewController;
    [self.window makeKeyAndVisible];

    // Add analytics
    [self analytics];

    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Enable Audio Play in Vibrate and Background Modes
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    
    // Disable Idle Timer
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    
    // Sync Queue if suer is logged in (this may cause app to crash if user launches app on queue and videos were removed)
    if ( [[NSUserDefaults standardUserDefaults] boolForKey:kDefaultUserAuthorized] ) {
        
        // Perform Sync on Likes
        [ShelbyAPIClient getLikesForSync];
        
        // Perform Sync on Likes
        [ShelbyAPIClient getPersonalRollForSync];
        
        
        // Update All Routs
        [self pingAllRoutes];
        
    }
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // All video.extractedURL references are temporary (session-dependent), so they should be removed when the app shuts down.
    CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
    [dataUtility removeAllVideoExtractionURLReferences];
}

#pragma mark - Public Methods
- (void)userIsAuthorized
{
    // Set NSUserDefault
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kDefaultUserAuthorized];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // On login, perform API requests
    [self pingAllRoutes];
    
    // Perform Sync on Likes
    [ShelbyAPIClient getLikesForSync];
    
    // Perform Sync on Personal Roll
    [ShelbyAPIClient getPersonalRollForSync];
    
    // Begin Polling API
    self.pollAPICounter = 0;
    self.pollAPITimer = [NSTimer scheduledTimerWithTimeInterval:60.0f target:self selector:@selector(pollAPI) userInfo:nil repeats:YES];

    [NSTimer scheduledTimerWithTimeInterval:3.0f target:self selector:@selector(postAuthorizationNotification) userInfo:nil repeats:NO];
}

- (void)logout
{
    // Invalidate pollAPITimer
    [self.pollAPITimer invalidate];
    
    // Set NSUserDefaults
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kDefaultUserAuthorized];
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:kSPCurrentVideoStreamID];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
}

- (void)performCleanIfUserDidAuthenticate
{
    // Empty Existing Core Data Store (if one exists)
    [self dumpAllData];
    
    // Empty Existing Video Cache
    [AsynchronousFreeloader removeAllImages];
}

#pragma mark - Private Methods
- (void)pingAllRoutes
{
    [ShelbyAPIClient getStream];
    [ShelbyAPIClient getLikesRoll];
    [ShelbyAPIClient getPersonalRoll];
    [ShelbyAPIClient getGroups];
}

- (void)pollAPI
{
    
    switch ( _pollAPICounter ) {
        
        case 0: { // Stream
            
            self.pollAPICounter = 1;
            
            [ShelbyAPIClient getStream];
            
        } break;
            
        case 1: { // Queue Roll
            
            self.pollAPICounter = 2;
            
            [ShelbyAPIClient getLikesRoll];
            
        } break;
            
            
        case 2: { // Personal Roll
            
            self.pollAPICounter = 3;
            
            [ShelbyAPIClient getPersonalRoll];
            
        } break;
            
        case 3: { // Personal Roll
            
            self.pollAPICounter = 0;
            
            [ShelbyAPIClient getGroups];
            
        } break;

            
        default:
            break;
    }
}

- (void)postAuthorizationNotification
{
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationUserAuthenticationDidSucceed object:nil];
}

- (void)analytics
{
    
    // Crashlytics - Crash Logging
    [Crashlytics startWithAPIKey:@"84a79b7ee6f2eca13877cd17b9b9a290790f99aa"];
    
    // Add Harpy
    
    // Add Panhandler
    
    
}

#pragma mark - Core Data Methods
- (void)mergeChanges:(NSNotification *)notification
{
    
    // Merge changes into the main context on the main thread
    dispatch_async(dispatch_get_main_queue(), ^{
        
        NSManagedObjectContext *mainThreadContext = [self context];
        
        @synchronized(mainThreadContext) {

            [mainThreadContext performBlock:^{
        
                    [mainThreadContext mergeChangesFromContextDidSaveNotification:notification];
            }];
            
        }
 
    });
}

- (NSManagedObjectModel *)managedObjectModel
{
    
    if ( _managedObjectModel ) {
        return _managedObjectModel;
    }
    
    _managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
    return _managedObjectModel;
    
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if ( _persistentStoreCoordinator ) {
        return _persistentStoreCoordinator;
    }
    
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    
    NSURL *applicationDocumentsDirectory = [[fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    
    NSURL *storeURL = [applicationDocumentsDirectory URLByAppendingPathComponent:@"Shelby.tv.sqlite"];
    
    NSError *error = nil;
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    
    if ( ![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error] )
    {
        // Delete datastore if there's a conflict. User can re-login to repopulate the datastore.
        [fileManager removeItemAtURL:storeURL error:nil];
        
        // Retry
        if ( ![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error] )
        {
            DLog(@"Could not save changes to Core Data. Error: %@, %@", error, [error userInfo]);
        }
    }
    
    return _persistentStoreCoordinator;
}
- (NSManagedObjectContext *)context;
{
    
    // Initialize persistantStoreCoordinator
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    
    NSManagedObjectContext *context;
    if ( [NSThread isMainThread] ) {
        
        context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [context setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
        
    } else {
        
        context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        [context setMergePolicy:NSMergeByPropertyStoreTrumpMergePolicy];
        
    }
    
    // Set thread-independent properties
    [context setUndoManager:nil];
    [context setPersistentStoreCoordinator:coordinator];
    [context setRetainsRegisteredObjects:YES];
    
    return context;
    
}

- (void)dumpAllData
{
    NSPersistentStoreCoordinator *coordinator =  [self persistentStoreCoordinator];
    NSPersistentStore *store = [coordinator persistentStores][0];
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    [fileManager removeItemAtURL:store.URL error:nil];
    [coordinator removePersistentStore:store error:nil];
    [self setPersistentStoreCoordinator:nil];
}

@end
