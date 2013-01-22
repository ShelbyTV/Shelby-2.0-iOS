//
//  AppDelegate.m
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 10/17/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

#import "AppDelegate.h"
#import "MeViewController.h"
#import "LoginViewController.h"

@interface AppDelegate ()
{
    NSManagedObjectModel *_managedObjectModel;
}

@property (strong, nonatomic) NSManagedObjectModel *_managedObjectModel;
@property (strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (strong, nonatomic) LoginViewController *loginViewController;
@property (strong, nonatomic) NSTimer *pollAPITimer;
@property (assign, nonatomic) NSUInteger pollAPICounter;

- (void)pollAPI;
- (void)analytics;
- (void)dismissLoginViewController;

@end

@implementation AppDelegate
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize loginViewController = _loginViewController;
@synthesize pollAPITimer = _pollAPITimer;
@synthesize pollAPICounter = _pollAPICounter;

#pragma mark - UIApplicationDelegate Methods
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    
    // Add analytics
    [self analytics];
    
    // Create UIWindow and rootViewController
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    MeViewController *meVC = [[MeViewController alloc] initWithNibName:@"MeViewController" bundle:nil];
    self.window.rootViewController = meVC;
    [self.window makeKeyAndVisible];
    
    if ( ![[NSUserDefaults standardUserDefaults] boolForKey:kUserAuthorizedDefault] ) {
        
        self.loginViewController = [[LoginViewController alloc] initWithNibName:@"LoginViewController" bundle:nil];
        [self.window.rootViewController presentViewController:self.loginViewController animated:NO completion:nil];
        
    } else {
        
        [self userIsAuthorized];
        
        
    }

    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Enable Audio Play in Vibrate and Background Modes
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    
    // Disable Idle Timer
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
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
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kUserAuthorizedDefault];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // On login, perform API requests
    [ShelbyAPIClient getStream];
    [ShelbyAPIClient getQueueRoll];
    [ShelbyAPIClient getPersonalRoll];
    
    // Perform Sync on Queue
    [ShelbyAPIClient getQueueForSync];
    
    // Begin Polling API
    self.pollAPICounter = 0;
    self.pollAPITimer = [NSTimer scheduledTimerWithTimeInterval:30.0f target:self selector:@selector(pollAPI) userInfo:nil repeats:YES];
    
    // Remove _loginViewController if it exists
    if ( _loginViewController ) {
     
        [NSTimer scheduledTimerWithTimeInterval:3.0f target:self selector:@selector(dismissLoginViewController) userInfo:nil repeats:NO];
        
    }
}

- (void)logout
{
    // Invalidate pollAPITimer
    [self.pollAPITimer invalidate];
    
    // Set NSUserDefaults
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kUserAuthorizedDefault];
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:kSPCurrentVideoStreamID];
    [[NSUserDefaults standardUserDefaults] synchronize];

    // Pop View Controller
    if ( _loginViewController ) {
        [self.window.rootViewController presentViewController:_loginViewController animated:YES completion:nil];
    } else {
        self.loginViewController = [[LoginViewController alloc] initWithNibName:@"LoginViewController" bundle:nil];
        [self.window.rootViewController presentViewController:_loginViewController animated:YES completion:nil];
    }

}

- (void)dismissLoginViewController
{
    [self.loginViewController.indicator stopAnimating];
    [self.loginViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Private Methods
- (void)pollAPI
{
    
    switch ( _pollAPICounter ) {
        
        case 0: { // Stream
            
            self.pollAPICounter = 1;
            
            [ShelbyAPIClient getStream];
            
        } break;
            
        case 1: { // Queue Roll
            
            self.pollAPICounter = 2;
            
            [ShelbyAPIClient getQueueRoll];
            
        } break;
            
            
        case 2: { // Personal Roll
            
            self.pollAPICounter = 0;
            
            [ShelbyAPIClient getPersonalRoll];
            
        } break;

            
        default:
            break;
    }
}

- (void)analytics
{
    [Crashlytics startWithAPIKey:@"84a79b7ee6f2eca13877cd17b9b9a290790f99aa"];
}

#pragma mark - Core Data Methods
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
    
    DLog(@"--- Creating new persistantStoreCoordinator ---");
    return _persistentStoreCoordinator;
}
- (NSManagedObjectContext*)context;
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
    NSPersistentStore *store = [[coordinator persistentStores] objectAtIndex:0];
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    [fileManager removeItemAtURL:store.URL error:nil];
    [coordinator removePersistentStore:store error:nil];
    [self setPersistentStoreCoordinator:nil];
}


@end