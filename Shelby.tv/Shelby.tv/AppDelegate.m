//
//  AppDelegate.m
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 10/17/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

#import "AppDelegate.h"
#import "BrowseViewController.h"

@interface AppDelegate ()

@property (nonatomic) NSManagedObjectModel *managedObjectModel;
@property (nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic) NSTimer *pollAPITimer;
@property (assign, nonatomic) NSUInteger pollAPICounter;
@property (nonatomic) UIViewController *channelloadingViewController;

- (void)pingAllRoutes;
- (void)setupChannelLoadingScreen;
- (void)didLoadChannels:(NSNotification *)notification;
- (void)postAuthorizationNotification;
- (void)analytics;

@end

@implementation AppDelegate

#pragma mark - UIApplicationDelegate Methods
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Create UIWindow and rootViewController
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    BrowseViewController *pageViewController = [[BrowseViewController alloc] initWithNibName:@"BrowseView" bundle:nil];
    self.window.rootViewController = pageViewController;
    [self.window makeKeyAndVisible];
    
    // Setup buffer screen to allow channels to be fetched from web and stored locally
    [self setupChannelLoadingScreen];
    
    // Add notification observe when channels have finished loading
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didLoadChannels:)
                                                 name:kShelbyNotificationChannelsFetched
                                               object:nil];
    
    
    // Crash reporting and user monitoring analytics
    [self analytics];

    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH , 0), ^{
        [ShelbyAPIClient getAllChannels];
    });
    
    // Enable Audio Play in Vibrate and Background Modes
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    
    // Disable Idle Timer
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    
    // Sync Queue if user is logged in (this may cause app to crash if user launches app on queue and videos were removed)
    if ( [[NSUserDefaults standardUserDefaults] boolForKey:kShelbyDefaultUserAuthorized] ) {
        
        // Update All Routes
        [self pingAllRoutes];
        
    }
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Invalidate timer as user goes to background mode.
    [self.pollAPITimer invalidate];
    
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
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kShelbyDefaultUserAuthorized];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // Perform API requests
    [self pingAllRoutes];

    [NSTimer scheduledTimerWithTimeInterval:2.0f target:self selector:@selector(postAuthorizationNotification) userInfo:nil repeats:NO];
}

- (void)logout
{
    // Invalidate pollAPITimer
    [self.pollAPITimer invalidate];
    
    // Set NSUserDefaults
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kShelbyDefaultUserAuthorized];
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:kShelbySPCurrentVideoStreamID];
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

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH , 0), ^{
        [ShelbyAPIClient getLikesForSync];
        [ShelbyAPIClient getPersonalRollForSync];
        [ShelbyAPIClient getStream];
        [ShelbyAPIClient getLikes];
        [ShelbyAPIClient getPersonalRoll];
        [ShelbyAPIClient getAllChannels];
    });
    
    if ( ![_pollAPITimer isValid] ) {
        
        // Begin or restart Polling API
        self.pollAPICounter = 0;
        self.pollAPITimer = [NSTimer scheduledTimerWithTimeInterval:60.0f target:self selector:@selector(pingAllRoutes) userInfo:nil repeats:YES];

    }

}

- (void)setupChannelLoadingScreen
{
    self.channelloadingViewController = [[UIViewController alloc] init];
    _channelloadingViewController.view.frame = CGRectMake(0.0f, 0.0f, 1024.0f, 768.0f);
    [_channelloadingViewController.view setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"Default-Landscape.png"]]];
    UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithFrame:_channelloadingViewController.view.frame];
    [indicator setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [indicator setColor:kShelbyColorBlack];
    [indicator setCenter:CGPointMake(_channelloadingViewController.view.frame.size.width/2.0f, _channelloadingViewController.view.frame.size.height/2.0f)];
    [indicator setHidesWhenStopped:YES];
    [indicator startAnimating];
    [_channelloadingViewController.view addSubview:indicator];
    [self.window.rootViewController presentViewController:_channelloadingViewController animated:NO completion:nil];
}

- (void)didLoadChannels:(NSNotification *)notification
{
    [self.channelloadingViewController dismissViewControllerAnimated:NO completion:nil];
    [(BrowseViewController *)self.window.rootViewController fetchChannels];
}


- (void)postAuthorizationNotification
{
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kShelbyNotificationUserAuthenticationDidSucceed object:nil];
}


- (void)analytics
{
    
    // Harpy
    [Harpy checkVersion];
    
    // Panhandler
    [Panhandler sharedInstance];
    
    // Crashlytics - Crash Logging
    [Crashlytics startWithAPIKey:@"84a79b7ee6f2eca13877cd17b9b9a290790f99aa"];
    
    // Hockey
    
    // Google Analytics
    
    
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
