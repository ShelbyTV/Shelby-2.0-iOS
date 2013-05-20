//
//  AppDelegate.m
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 10/17/12.
//  Copyright (c) 2012 Shelby TV. All rights reserved.
//

#import "AppDelegate.h"

#import <HockeySDK/HockeySDK.h>
#import "ShelbyHomeViewController.h"
//djs
//#import "SPModel.h"
#import "SPVideoDownloader.h"
#import "SPVideoPlayer.h"
#import "SPVideoReel.h"
#import "Video.h"
#import "FacebookHandler.h"
#import "SettingsViewController.h"
#import "ShelbyDataMediator.h"
#import "ShelbyBrain.h"

#ifdef SHELBY_ENTERPRISE
    #define HOCKEY_BETA                     @"73f0add2df47cdb17bedfbfe35f9e279"
    #define HOCKEY_LIVE                     @"73f0add2df47cdb17bedfbfe35f9e279"
    #define GOOGLE_ANALYTICS_ID             @"UA-21191360-14"
#else
    #define HOCKEY_BETA                     @"13fd8e2379e7cfff28cf8b069c8b93d3"  // Nightly
    #define HOCKEY_LIVE                     @"67c862299d06ff9d891434abb89da906"  // Live
    #define GOOGLE_ANALYTICS_ID             @"UA-21191360-12"
#endif

NSString *const kShelbyLastActiveDate       = @"kShelbyLastActiveDate";

@interface AppDelegate(HockeyProtocols) <BITHockeyManagerDelegate, BITUpdateManagerDelegate, BITCrashManagerDelegate>
@end

@interface AppDelegate ()

//djs don't need these...
//@property (nonatomic) NSManagedObjectModel *managedObjectModel;
//@property (nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic) NSMutableArray *videoDownloaders;
@property (assign, nonatomic) NSUInteger pollAPICounter;
@property (nonatomic) id <GAITracker> googleTracker;
//djs shouldn't need these anymore
//@property (nonatomic) NSInvocation *invocationMethod;
//@property (strong) NSMutableArray *dataUtilities;
@property (nonatomic, strong) ShelbyBrain *brain;

/// Setup Methods
//djs move most of this crap into ShelbyAppBrain
//- (void)setupInitialSettings;
- (void)setupAnalytics;
- (void)setupOfflineMode;
//- (void)setupDataUtilities;

/// Notification Methods
//djs TODO: remove this notification, too (at least move it out of AppDelegate)
- (void)postAuthorizationNotification;

/// API Methods
//djs DEF don't want this in here
//- (void)pingAllRoutes;

@end

@implementation AppDelegate

#pragma mark - UIApplicationDelegate Methods
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    if( getenv("NSZombieEnabled") || getenv("NSAutoreleaseFreedObjectCheckEnabled") ) {
        //objects are never free'd under NSZombie, expect memory usage to continually grow
        DLog(@"NSZombieEnabled/NSAutoreleaseFreedObjectCheckEnabled enabled!");
    }
    
    //must happen first
    [self setupCrashHandling];
    
    // Data Utilities
    //djs we shouldn't need this...
    //[self setupDataUtilities];
    
    // Initial Conditions
    //djs killing this too
    //[self setupInitialSettings];
    
    // Crash reporting and user monitoring analytics
    [self setupAnalytics];
    
    // Setup Offline Mode
    [self setupOfflineMode];
    
    // Create UIWindow and rootViewController
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    ShelbyHomeViewController *homeViewController = [[ShelbyHomeViewController alloc] initWithNibName:@"ShelbyHomeView" bundle:nil];
    self.window.rootViewController = homeViewController;
    self.brain = [[ShelbyBrain alloc] init];
    [self.brain setup];
    self.brain.homeVC = homeViewController;
    [self.window makeKeyAndVisible];

    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    
    [self.brain handleDidBecomeActive];
    
    NSDate *lastActiveDate = [[NSUserDefaults standardUserDefaults] objectForKey:kShelbyLastActiveDate];
    if (lastActiveDate && [lastActiveDate isKindOfClass:[NSDate class]]) {
        
//        NSTimeInterval interval = fabs([lastActiveDate timeIntervalSinceNow]);
        
        // Remove SPVideoReel if more than 5 minutes (300 seconds) have elapsed since app went to background
        //djs TODO: this functionality moves to brain
//        if (interval >= 300) {
//            SPVideoReel *videoReel = [[SPModel sharedInstance] videoReel];
//            if (videoReel && [videoReel delegate]) {
//                [[videoReel delegate] userDidCloseChannel:videoReel];
//            }
//        }
        
        // Remove invocationMethod and any pending dataUtilities if app was in background for more than a minute
        //djs we're getting rid of all this...
//        if (interval > 60) {
//            [self setDataUtilities:nil];
//            [self setInvocationMethod:nil];
//        }
    }
    
    //djs again, shouldn't have stuff like this
//    if (!self.dataUtilities) {
//        [self setupDataUtilities];
//    }
    
    // djs assuming this fetches channels and then on its return, does a bunch of UI updating via back channels...
    //djs TODO: replicate this via Brain and ShelbyDataMediator
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH , 0), ^{
//        [ShelbyAPIClient getAllChannels];
//    });
    
    // Enable Audio Play in Vibrate and Background Modes
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    
    // Disable Idle Timer
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    
    //djs again, this is like getAllChannels...
    //djs TODO: some sort of initialization via Brain / ShelbyDataMediator
    // Sync Queue if user is logged in (this may cause app to crash if user launches app on queue and videos were removed)
//    if ( [[NSUserDefaults standardUserDefaults] boolForKey:kShelbyDefaultUserAuthorized] ) {
//        // Update All Routes
//        [self pingAllRoutes];
//    }
    
    [[FacebookHandler sharedInstance] handleDidBecomeActive];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:kShelbyLastActiveDate];
    [[NSUserDefaults standardUserDefaults] synchronize];
  
}


- (void)applicationWillTerminate:(UIApplication *)application
{
    // All video.extractedURL references are temporary (session-dependent), so they should be removed when the app shuts down.
    //djs nope
    //CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
    //[dataUtility removeAllVideoExtractionURLReferences];
    //djs nope
    //[self removeObserver:self forKeyPath:@"dataUtilities"];
}


- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    NSString *fbAppID = [NSString stringWithFormat:@"fb%@", [[FacebookHandler sharedInstance] facebookAppID]];
    
    if ([[url absoluteString] hasPrefix:fbAppID]) {
        return [[FacebookHandler sharedInstance] handleOpenURL:url];
    }
    
    return YES;
}
#pragma mark - Authentication Methods (Public)
//djs not sure if we need this, but if so, it will get moved to ShelbyDataMediator
//- (void)userIsAuthorized
//{
//    // Set NSUserDefault
//    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kShelbyDefaultUserAuthorized];
//    [[NSUserDefaults standardUserDefaults] synchronize];
//    
//    // Send GA Identifier: clientId
//    [ShelbyAPIClient putGoogleAnalyticsClientID:[self.googleTracker clientId]];
//    
//    // Sync/Send Logged-Out Likes to Web
//    CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
//    [dataUtility syncLoggedOutLikes];
//    
//    // Perform API requests
//    [self pingAllRoutes];
//
//    [NSTimer scheduledTimerWithTimeInterval:2.0f target:self selector:@selector(postAuthorizationNotification) userInfo:nil repeats:NO];
//}

//djs moving skeleton this to ShelbyDataMediator
//- (void)logout
//{
//    
//    if ([self.dataUtilities count] != 0) {
//        NSMethodSignature *logoutSignature = [AppDelegate instanceMethodSignatureForSelector:@selector(logout)];
//        NSInvocation *logoutInvocation = [NSInvocation invocationWithMethodSignature:logoutSignature];
//        
//        [logoutInvocation setTarget:self];
//        [logoutInvocation setSelector:@selector(logout)];
//        
//        [self setInvocationMethod:logoutInvocation];
//        return;
//    }
//    
//    // Remove any session properties
//    [SettingsViewController cleanupSession];
//    
//    // Empty existing image cache
//    [AsynchronousFreeloader removeAllImages];
//    
//    // Empty existing disk-stored data (if there exists any data)
//    [SPVideoDownloader deleteAllDownloadedVideos];
//    
//    // Empty existing Core Data store (if one exists)
//    [self dumpAllData];
//    
//    // Refetch Channels, since the Core Data store was dumped
//    [ShelbyAPIClient getAllChannels];
//}

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
//djs i definatley don't like this
//- (void)setupInitialSettings
//{
//    static dispatch_once_t coordinatorToken = 0;
//    dispatch_once(&coordinatorToken, ^{
//        CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_InitialSave];
//        [dataUtility saveContext:[self context]];
//    });
//}

-(void)setupCrashHandling
{
    // Hockey
    [[BITHockeyManager sharedHockeyManager] configureWithBetaIdentifier:HOCKEY_BETA
                                                         liveIdentifier:HOCKEY_LIVE
                                                               delegate:self];
    [[BITHockeyManager sharedHockeyManager] startManager];
    
    // Agressive re-crash prevention
    if([[BITHockeyManager sharedHockeyManager].crashManager didCrashInLastSession]){
        DLog(@"Due to crash in last session, destroying Core Data backing file...");
        [[ShelbyDataMediator sharedInstance] nuclearCleanup];
    }
}

- (void)setupAnalytics
{
    
    // Harpy
    [[Harpy sharedInstance] setAppID:@"467849037"];
    [[Harpy sharedInstance] setAlertType:HarpyAlertTypeOption];
    [[Harpy sharedInstance] checkVersion];
    
    // TODO - Uncomment for AppStore
    // Panhandler
    // [Panhandler sharedInstance];
    
    

    // Google Analytics
    [GAI sharedInstance].trackUncaughtExceptions = YES;     // Optional: automatically send uncaught exceptions to Google Analytics.
    [GAI sharedInstance].dispatchInterval = 20;             // Optional: set Google Analytics dispatch interval to e.g. 20 seconds.
    [GAI sharedInstance].debug = NO;                       // Optional: set debug to YES for extra debugging information.
    self.googleTracker = [[GAI sharedInstance] trackerWithTrackingId:GOOGLE_ANALYTICS_ID];
    self.googleTracker.sessionStart = YES;    
    
#ifdef SHELBY_APPSTORE
    // Making sure there are no updates in the target we use for dev & app store release
    [[BITHockeyManager sharedHockeyManager] setDisableUpdateManager:YES];
#endif
    
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

//djs No reason for this stuff
//- (void)setupDataUtilities
//{
//    _dataUtilities = [@[] mutableCopy];
//    [self addObserver:self forKeyPath:@"dataUtilities" options:NSKeyValueObservingOptionNew context:nil];
//}

- (void)setupOfflineMode
{
    
    // Set offlineMode to OFF by Default
    if ( [[NSUserDefaults standardUserDefaults] boolForKey:kShelbyDefaultUserAuthorized] ) {
        
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kShelbyDefaultOfflineModeEnabled];
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kShelbyDefaultOfflineViewModeEnabled];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
}

#pragma mark - Notification Methods (Private)
//djs TODO: pretty sure this should move into ShelbyDataMediator
- (void)postAuthorizationNotification
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kShelbyNotificationUserAuthenticationDidSucceed object:nil];
}

//djs this whole data utilities crap has got to go
//- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
//{
//    if ( object == self && [keyPath isEqualToString:@"dataUtilities"] ) {
//        
//        DLog(@"DataUtlities Count: %d", [self.dataUtilities count]);
//        
//        if ([self.dataUtilities count] == 0  && self.invocationMethod) {
//            [self.invocationMethod invoke];
//            [self setInvocationMethod:nil];
//        }
//    }
//}

#pragma mark - API Methods (Private)
//djs this moves, in sort forms, to ShelbyDataMediator
//- (void)pingAllRoutes
//{
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH , 0), ^{
//        [ShelbyAPIClient getStream];
//        [ShelbyAPIClient getPersonalRoll];
//        [ShelbyAPIClient getLikes];
//    });
//}

#pragma mark - Core Data Methods (Public)
//djs def don't like this in here
//- (void)mergeChanges:(NSNotification *)notification
//{
//    
//    // Merge changes into the main context on the main thread
//    dispatch_async(dispatch_get_main_queue(), ^{
//        
//        NSManagedObjectContext *mainThreadContext = [self context];
//        
//        @synchronized(mainThreadContext) {
//            
//            [mainThreadContext performBlock:^{
//                
//                [mainThreadContext mergeChangesFromContextDidSaveNotification:notification];
//            }];
//            
//        }
//        
//    });
//}

//djs don't like this in here, either
//- (void)dumpAllData
//{
//    NSPersistentStoreCoordinator *coordinator =  [self persistentStoreCoordinator];
//    NSPersistentStore *store = [coordinator persistentStores][0];
//    NSFileManager *fileManager = [[NSFileManager alloc] init];
//    [fileManager removeItemAtURL:store.URL error:nil];
//    [coordinator removePersistentStore:store error:nil];
//    [self setPersistentStoreCoordinator:nil];
//}

#pragma mark - Core Data Methods (Private Accessors)

//djs if anything, this is misnamed (or under-named), and will get re-created in ShelbyDataMediator
//- (NSManagedObjectContext *)context;
//{
//    
//    // Initialize persistantStoreCoordinator
//    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
//    
//    NSManagedObjectContext *context;
//    if ( [NSThread isMainThread] ) {
//        
//        context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
//        [context setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
//        
//    } else {
//        
//        context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
//        [context setMergePolicy:NSMergeByPropertyStoreTrumpMergePolicy];
//        
//    }
//    
//    // Set thread-independent properties
//    [context setUndoManager:nil];
//    [context setPersistentStoreCoordinator:coordinator];
//    [context setRetainsRegisteredObjects:YES];
//    
//    return context;
//    
//}

//#pragma mark - Add/remove dataUtilities hash (Public)
// djs, nope, not any more
//- (void)addHash:(NSNumber *)hash
//{
//    NSMutableArray *dataUtilitiesArray = [self mutableArrayValueForKey:@"dataUtilities"];
//    @synchronized(dataUtilitiesArray) {
//        [dataUtilitiesArray addObject:hash];
//    }
//}
//
//
//- (void)removeHash:(NSNumber *)hash
//{
//    NSMutableArray *dataUtilitiesArray = [self mutableArrayValueForKey:@"dataUtilities"];
//    @synchronized(dataUtilitiesArray) {
//        if (dataUtilitiesArray && [dataUtilitiesArray count] && [dataUtilitiesArray containsObject:hash]) {
//            [dataUtilitiesArray removeObject:hash];
//        }
//    }
//}

@end
