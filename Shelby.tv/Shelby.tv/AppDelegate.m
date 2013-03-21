//
//  AppDelegate.m
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 10/17/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

#import "AppDelegate.h"

#import <HockeySDK/HockeySDK.h>
#import "BrowseViewController.h"
#import "SPModel.h"
#import "SPVideoDownloader.h"
#import "SPVideoPlayer.h"
#import "SPVideoReel.h"
#import "Video.h"

// HOCKEY_APPSTORE                 @"67c862299d06ff9d891434abb89da906"
// HOCKEY_NIGHTLY                  @"13fd8e2379e7cfff28cf8b069c8b93d3"
// HOCKEY_ENTERPRISE               @"73f0add2df47cdb17bedfbfe35f9e279"
#ifdef SHELBY_ENTERPRISE
    #define HOCKEY_BETA                     @"73f0add2df47cdb17bedfbfe35f9e279"
    #define HOCKEY_LIVE                     @"73f0add2df47cdb17bedfbfe35f9e279"
#else
    #define HOCKEY_BETA                     @"13fd8e2379e7cfff28cf8b069c8b93d3"
    #define HOCKEY_LIVE                     @"67c862299d06ff9d891434abb89da906"
#endif

NSString *const kShelbyLastActiveDate       = @"kShelbyLastActiveDate";

@interface AppDelegate(HockeyProtocols) <BITHockeyManagerDelegate, BITUpdateManagerDelegate, BITCrashManagerDelegate>
@end

@interface AppDelegate ()

@property (nonatomic) NSManagedObjectModel *managedObjectModel;
@property (nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic) UIView *categoryLoadingView;
@property (nonatomic) NSMutableArray *videoDownloaders;
@property (assign, nonatomic) NSUInteger pollAPICounter;
@property (nonatomic) id <GAITracker> googleTracker;
@property (nonatomic) NSInvocation *invocationMethod;

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
    
    self.dataUtilities = [@[] mutableCopy];
    
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
    NSDate *lastActiveDate = [[NSUserDefaults standardUserDefaults] objectForKey:kShelbyLastActiveDate];
    if (lastActiveDate && [lastActiveDate isKindOfClass:[NSDate class]]) {
        
        NSTimeInterval interval = fabs([lastActiveDate timeIntervalSinceNow]);
        
        // Remove SPVideoReel if more than 5 minutes (300 seconds) have elapsed since app went to background
        if (interval >= 300) {
            if ([[SPModel sharedInstance] videoReel]) {
                [[[SPModel sharedInstance] videoReel] homeButtonAction:self];
            }
        }
        
        // Remove invocationMethod and any pending dataUtilities if app was in background for more than a minute
        if (interval > 60) {
            [self setDataUtilities:nil];
            [self setInvocationMethod:nil];
        }
    }
    
    if (!self.dataUtilities) {
        self.dataUtilities = [@[] mutableCopy];
    }
    
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
    [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:kShelbyLastActiveDate];
    [[NSUserDefaults standardUserDefaults] synchronize];
  
}


- (void)applicationWillTerminate:(UIApplication *)application
{
    // All video.extractedURL references are temporary (session-dependent), so they should be removed when the app shuts down.
    CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
    [dataUtility removeAllVideoExtractionURLReferences];
    
    [self removeObserver:self forKeyPath:@"dataUtilities"];
}

#pragma mark - Authentication Methods (Public)
- (void)userIsAuthorized
{
    // Set NSUserDefault
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kShelbyDefaultUserAuthorized];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // Send GA Identifier: clientId
    [ShelbyAPIClient putGoogleAnalyticsClientID:[self.googleTracker clientId]];
    
    // Sync/Send Logged-Out Likes to Web
    CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
    [dataUtility syncLoggedOutLikes];
    
    // Perform API requests
    [self pingAllRoutes];

    [NSTimer scheduledTimerWithTimeInterval:2.0f target:self selector:@selector(postAuthorizationNotification) userInfo:nil repeats:NO];
}

- (void)logout
{
    
    if ([self.dataUtilities count] != 0) {
        NSMethodSignature *logoutSignature = [AppDelegate instanceMethodSignatureForSelector:@selector(logout)];
        NSInvocation *logoutInvocation = [NSInvocation invocationWithMethodSignature:logoutSignature];
        
        [logoutInvocation setTarget:self];
        [logoutInvocation setSelector:@selector(logout)];
        
        [self setInvocationMethod:logoutInvocation];
        return;
    }
    
    // Reset user state (Authorization NSUserDefaults)
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kShelbyDefaultUserAuthorized];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kShelbyDefaultUserIsAdmin];
    
    // Reset app mode state (Secred Mode NSUserDefaults)
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kShelbyDefaultOfflineModeEnabled];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kShelbyDefaultOfflineViewModeEnabled];
    
    // Reset stream dependent variables (Playback UX NSUserDefaults)
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:kShelbySPCurrentVideoStreamID];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // Empty existing Video Cache
    [AsynchronousFreeloader removeAllImages];
    
    // Empty existing disk-stored data (if there exists any data)
    [SPVideoDownloader deleteAllDownloadedVideos];
    
    // Empty existing CoreData Store (if one exists)
    [self dumpAllData];
    
    // Refetch Categories, since core-data store was dumped
    [ShelbyAPIClient getAllCategories];
}

#pragma mark - Persistance Methods (Public)
- (void)storeVideoReel:(SPVideoReel *)videoReel
{
    
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
    
    // TODO - Uncomment for AppStore
    // Panhandler
//    [Panhandler sharedInstance];
    
    // Crashlytics - Crash Logging
    [Crashlytics startWithAPIKey:@"84a79b7ee6f2eca13877cd17b9b9a290790f99aa"];
    
    // Hockey
    [[BITHockeyManager sharedHockeyManager] configureWithBetaIdentifier:HOCKEY_BETA
                                                         liveIdentifier:HOCKEY_LIVE
                                                               delegate:self];
    [[BITHockeyManager sharedHockeyManager] startManager];

    // Google Analytics
    [GAI sharedInstance].trackUncaughtExceptions = YES;     // Optional: automatically send uncaught exceptions to Google Analytics.
    [GAI sharedInstance].dispatchInterval = 20;             // Optional: set Google Analytics dispatch interval to e.g. 20 seconds.
    [GAI sharedInstance].debug = NO;                       // Optional: set debug to YES for extra debugging information.
    self.googleTracker = [[GAI sharedInstance] trackerWithTrackingId:@"UA-21191360-12"];
    self.googleTracker.sessionStart = YES;    
    
#ifdef SHELBY_APPSTORE
    // Making sure there are no updates in the target we use for dev & app store release
    [[BITHockeyManager sharedHockeyManager] setDisableUpdateManager:YES];
#endif
    
}

- (void)setupObservers
{
    // Add notification to dismiss categoryLoadingView if there's no connectivity
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didNotConnect:)
                                                 name:kShelbyNotificationNoConnectivity
                                               object:nil];

    [self addObserver:self forKeyPath:@"dataUtilities" options:NSKeyValueObservingOptionNew context:nil];
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
    
}

- (void)setupOfflineMode
{
    
    // Set offlineMode to OFF by Default
    if ( [[NSUserDefaults standardUserDefaults] boolForKey:kShelbyDefaultUserAuthorized] ) {
        
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kShelbyDefaultOfflineModeEnabled];
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kShelbyDefaultOfflineViewModeEnabled];
        
    }
    
}

#pragma mark - BITUpdateManagerDelegate
- (NSString *)customDeviceIdentifierForUpdateManager:(BITUpdateManager *)updateManager {
#ifndef SHELBY_APPSTORE
    if ([[UIDevice currentDevice] respondsToSelector:@selector(uniqueIdentifier)]) {
        return [[UIDevice currentDevice] performSelector:@selector(uniqueIdentifier)];
    }
#endif
    return nil;
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

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ( object == self && [keyPath isEqualToString:@"dataUtilities"] ) {
        
        DLog(@"DataUtlities Count: %d", [self.dataUtilities count]);
        
        if ([self.dataUtilities count] == 0  && self.invocationMethod) {
            [self.invocationMethod invoke];
            [self setInvocationMethod:nil];
        }
    }
}

#pragma mark - API Methods (Private)
- (void)pingAllRoutes
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH , 0), ^{
        [ShelbyAPIClient getStream];
        [ShelbyAPIClient getPersonalRoll];
        [ShelbyAPIClient getLikes];
    });
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
    dispatch_async(dispatch_get_main_queue(), ^{
        [(BrowseViewController *)self.window.rootViewController fetchAllCategories];

        if (self.categoryLoadingView) {
            [self removeCategoryLoadingView];

            BrowseViewController *browseViewController = (BrowseViewController *)self.window.rootViewController;
            [browseViewController performSelector:@selector(resetView) withObject:nil afterDelay:1];
        }
    });
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
