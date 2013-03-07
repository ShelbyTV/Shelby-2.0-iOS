//
//  AppDelegate.m
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 10/17/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

#import "AppDelegate.h"
#import "BrowseViewController.h"
#import "SPVideoDownloader.h"
#import "Video.h"

@interface AppDelegate ()

@property (nonatomic) NSManagedObjectModel *managedObjectModel;
@property (nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic) UIView *categoryLoadingView;
@property (nonatomic) NSMutableArray *videoDownloaders;
@property (nonatomic) NSTimer *pollAPITimer;
@property (assign, nonatomic) NSUInteger pollAPICounter;

/// Setup Methods
- (void)setupAnalytics;
- (void)setupObservers;
- (void)setupCategoryLoadingView;
- (void)removeCategoryLoadingView;
- (void)setupOfflineMode;

/// Notification Methods

- (void)didNotConnect:(NSNotification *)notification;
- (void)postAuthorizationNotification;

/// API Methods
- (void)pingAllRoutes;

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
    
    // Crash reporting and user monitoring analytics
    [self setupAnalytics];
    
    // Setup Offline Mode
    [self setupOfflineMode];
    
    // Observers
    [self setupObservers];
    
    // Setup buffer screen to allow categories to be fetched from web and stored locally
    [self setupCategoryLoadingView];

    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH , 0), ^{
        [ShelbyAPIClient getAllCategories];
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

#pragma mark - Authentication Methods (Public)
- (void)performCleanIfUserDidAuthenticate
{
    // Empty existing CoreData Store (if one exists)
    [self dumpAllData];
    
    // Empty existing disk-stored data (if it exists)
    [SPVideoDownloader deleteAllDownloadedVideos];
    
    // Empty existing Video Cache
    [AsynchronousFreeloader removeAllImages];
}

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
    
    // Set user state (NSUserDefaults)
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kShelbyDefaultUserAuthorized];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kShelbyDefaultUserIsAdmin];
    
    // Set app mode state (NSUserDefaults)
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kShelbyDefaultOfflineModeEnabled];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kShelbyDefaultOfflineViewModeEnabled];
    
    // Set stream dependent variables (NSUserDefaults)
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:kShelbySPCurrentVideoStreamID];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
    
}

#pragma mark - Offline Methods (Public)
- (void)downloadVideo:(Video *)video
{
    
    SPVideoDownloader *videoDownloader = [[SPVideoDownloader alloc] initWithVideo:video];
    [videoDownloader startDownloading];
    
}

- (void)addVideoDownloader:(SPVideoDownloader *)videoDownloader
{
    if ( ![self videoDownloaders] ) {
        self.videoDownloaders = [@[] mutableCopy];
    }

    [self.videoDownloaders addObject:videoDownloader];

    DLog(@"Retain SPVideoDownloader instance");

}

- (void)removeVideoDownloader:(SPVideoDownloader *)videoDownloader
{
    
    if ( [self.videoDownloaders containsObject:videoDownloader] ) {
        
        [self.videoDownloaders removeObject:videoDownloader];
        
        DLog(@"Released SPVideoDownloader instance");

    }
    
}

#pragma mark - Setup Methods (Private)
- (void)setupAnalytics
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

- (void)setupObservers
{
    
    // Add notification to dismiss categoryLoadingView if there's no connectivity
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didNotConnect:)
                                                 name:kShelbyNotificationNoConnectivity
                                               object:nil];
}

- (void)setupCategoryLoadingView
{
    self.categoryLoadingView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 1024.0f, 768.0f)];
    [self.categoryLoadingView setBackgroundColor:[UIColor clearColor]];
    [self.categoryLoadingView setUserInteractionEnabled:YES];
    [self.window.rootViewController.view addSubview:_categoryLoadingView];
    UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] init];
    [indicator setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [indicator setColor:kShelbyColorBlack];
    [indicator setCenter:CGPointMake(_categoryLoadingView.frame.size.width/2.0f, _categoryLoadingView.frame.size.height/2.0f - 21)];
    [indicator setHidesWhenStopped:YES];
    [indicator startAnimating];
    [self.categoryLoadingView addSubview:indicator];

}

- (void)removeCategoryLoadingView
{
    
    [self.categoryLoadingView removeFromSuperview];
    [self setCategoryLoadingView:nil];
    [(BrowseViewController *)self.window.rootViewController fetchAllCategories];
    [(BrowseViewController *)self.window.rootViewController resetView];
    
}

- (void)setupOfflineMode
{
    
    // Set offlineMode to OFF by Default
    if ( [[NSUserDefaults standardUserDefaults] boolForKey:kShelbyDefaultUserAuthorized] ) {
        
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kShelbyDefaultOfflineModeEnabled];
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kShelbyDefaultOfflineViewModeEnabled];
        
    }
    
}

#pragma mark - Notification Methods (Private)

- (void)didNotConnect:(NSNotification *)notification
{
    [self removeCategoryLoadingView];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kShelbyNotificationNoConnectivity object:nil];
}

- (void)postAuthorizationNotification
{
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kShelbyNotificationUserAuthenticationDidSucceed object:nil];
}

#pragma mark - API Methods (Private)
- (void)pingAllRoutes
{
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH , 0), ^{
        [ShelbyAPIClient getLikesForSync];
        [ShelbyAPIClient getPersonalRollForSync];
        [ShelbyAPIClient getStream];
        [ShelbyAPIClient getLikes];
        [ShelbyAPIClient getPersonalRoll];
        [ShelbyAPIClient getAllCategories];
    });
    
    if ( ![_pollAPITimer isValid] ) {
        
        // Begin or restart Polling API
        self.pollAPICounter = 0;
        self.pollAPITimer = [NSTimer scheduledTimerWithTimeInterval:60.0f target:self selector:@selector(pingAllRoutes) userInfo:nil repeats:YES];
        
    }
    
}

#pragma mark - Core Data Methods (Public)
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

- (void)didLoadCategories
{
    if (self.categoryLoadingView) {
        [self removeCategoryLoadingView];
    }
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

#pragma mark - Core Data Methods (Private Accessors)
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

@end
