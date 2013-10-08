//
//  AppDelegate.m
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 10/17/12.
//  Copyright (c) 2012 Shelby TV. All rights reserved.
//

#import "AppDelegate.h"

#import <AVFoundation/AVFoundation.h>
#import <HockeySDK/HockeySDK.h>
#import "Appirater.h"
#import "DeviceUtilities.h"
#import "FacebookHandler.h"
#import "GAI.h"
#import "GAIFields.h"
#import "Intercom.h"
#import "LocalyticsSession.h"
#import "ShelbyBrain.h"
#import "ShelbyABTestManager.h"

#ifdef SHELBY_ENTERPRISE
    #define HOCKEY_BETA                     @"73f0add2df47cdb17bedfbfe35f9e279"
    #define HOCKEY_LIVE                     @"73f0add2df47cdb17bedfbfe35f9e279"
    #define GOOGLE_ANALYTICS_ID             @"UA-21191360-14"
#else
    #define HOCKEY_BETA                     @"13fd8e2379e7cfff28cf8b069c8b93d3"  // Nightly
    #define HOCKEY_LIVE                     @"67c862299d06ff9d891434abb89da906"  // Live
    #define GOOGLE_ANALYTICS_ID             @"UA-21191360-12"
#endif

#ifdef DEBUG
    #define LOCALYTICS_APP_KEY              @"75bd1ca75d1d486581f93e1-1b905298-1a23-11e3-8e98-005cf8cbabd8"
#else
    #define LOCALYTICS_APP_KEY              @"44581e91bd028aa1fed9703-cc9a5e9c-1963-11e3-9391-009c5fda0a25"
#endif

#define INTERCOM_APP_KEY                    @"ios-fd543f22c20067637c172cd626d957e5abe6c95f"
#define INTERCOM_APP_ID                     @"aeb096feb787399ac1cf3985f891d0e13aa47571"

@interface AppDelegate(HockeyProtocols) <BITHockeyManagerDelegate, BITUpdateManagerDelegate, BITCrashManagerDelegate>
@end

@interface AppDelegate ()

@property (nonatomic) id <GAITracker> googleTracker;
@property (nonatomic, strong) ShelbyBrain *brain;

@end

@implementation AppDelegate

#pragma mark - UIApplicationDelegate Methods
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    if( getenv("NSZombieEnabled") || getenv("NSAutoreleaseFreedObjectCheckEnabled") ) {
        DLog(@"*** NSZombieEnabled/NSAutoreleaseFreedObjectCheckEnabled enabled! ***");
        DLog(@"*** objects are never free'd under NSZombie, expect memory usage to continually grow ***");
    }
    
    //must happen first
    [self setupCrashHandling];
    
    // Crash reporting and user monitoring analytics
    [self setupAnalytics];
    
    [self setupAppirater];
    
    // not yet re-implemented
//    [self setupOfflineMode];
    
//    if (!DEVICE_IPAD) {
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarStyleBlackTranslucent];
//    }
    
    if ([DeviceUtilities isGTEiOS7]) {
        [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    }
    // Brain will set proper ViewController on window and makeKeyAndVisible during -applicationDidBecomeActive:
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.brain = [[ShelbyBrain alloc] init];
    self.brain.mainWindow = self.window;

    // Handle launching from a notification
    UILocalNotification *notification = [launchOptions objectForKey:UIApplicationLaunchOptionsLocalNotificationKey];
    application.applicationIconBadgeNumber = 0;
    if (notification) {
        application.applicationIconBadgeNumber = 0;
        [self fireLocalNotification:notification];
    }

    [self setupAppAppearanceProxies];

    [self.brain handleDidFinishLaunching];
    
    NSDateComponents *components = [[NSDateComponents alloc] init];
    [components setWeekday:2]; // Monday
    [components setHour:10];
    
    [[ShelbyABTestManager sharedInstance] startABTestManager];
    // Appirater
    [Appirater appLaunched:YES];
    
    // https://developers.google.com/analytics/devguides/collection/ios/v3/sessions#managing
    id tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAISessionControl value:@"start"];

    return YES;
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Appirater
    [Appirater appEnteredForeground:YES];

    [[LocalyticsSession shared] resume];
    [[LocalyticsSession shared] upload];
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notifcation {
    // Handle the notificaton when the app is running
    application.applicationIconBadgeNumber = 0;
    UIApplicationState state = [application applicationState];
    if (state == UIApplicationStateInactive) {
        [self fireLocalNotification:notifcation];
    }

}


-(void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    [self.brain performBackgroundFetchWithCompletionHandler:completionHandler];
}


- (void)fireLocalNotification:(UILocalNotification *)notifcation
{
    [self.brain handleLocalNotificationReceived:notifcation];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [self.brain handleDidBecomeActive];
    
    // Enable Audio Play in Vibrate and Background Modes
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    
    [[FacebookHandler sharedInstance] handleDidBecomeActive];

    [[LocalyticsSession shared] resume];
    [[LocalyticsSession shared] upload];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [[LocalyticsSession shared] close];
    [[LocalyticsSession shared] upload];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    [self.brain handleWillResignActive];

    [[LocalyticsSession shared] close];
    [[LocalyticsSession shared] upload];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [[LocalyticsSession shared] close];
    [[LocalyticsSession shared] upload];

    // https://developers.google.com/analytics/devguides/collection/ios/v3/sessions#managing
    id tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAISessionControl value:@"end"];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    NSString *fbAppID = [NSString stringWithFormat:@"fb%@", [[FacebookHandler sharedInstance] facebookAppID]];
    
    if ([[url absoluteString] hasPrefix:fbAppID]) {
        return [[FacebookHandler sharedInstance] handleOpenURL:url];
    }
    
    return YES;
}

#pragma mark - Setup Methods (Private)

- (void)setupAppAppearanceProxies
{
    //navigation bars
    [[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"top-nav-bkgd"] forBarMetrics:UIBarMetricsDefault];
    [[UINavigationBar appearance] setTitleTextAttributes:@{UITextAttributeFont:[UIFont fontWithName:@"Ubuntu-Medium" size:20.0], UITextAttributeTextColor: [UIColor whiteColor], UITextAttributeTextShadowColor: [UIColor clearColor]}];
}

- (void)setupCrashHandling
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

- (void)setupAppirater
{
    // Appirater
    [Appirater setAppId:SHELBY_APP_ID];
    [Appirater setDaysUntilPrompt:5];
    [Appirater setUsesUntilPrompt:10];
    //significant events are: share (any kind), like
    [Appirater setSignificantEventsUntilPrompt:10];
    [Appirater setTimeBeforeReminding:3];
    [Appirater setDebug:NO];
}

- (void)setupAnalytics
{
    /*** Google Analytics ***/
    [GAI sharedInstance].trackUncaughtExceptions = YES; // Optional: automatically send uncaught exceptions to Google Analytics.
    [GAI sharedInstance].dispatchInterval = 20;         // Optional: set Google Analytics dispatch interval to e.g. 20 seconds.
#ifdef SHELBY_APPSTORE
    [[GAI sharedInstance].logger setLogLevel:kGAILogLevelNone];
#else
    [[GAI sharedInstance].logger setLogLevel:kGAILogLevelWarning];
#endif
    self.googleTracker = [[GAI sharedInstance] trackerWithTrackingId:GOOGLE_ANALYTICS_ID];
    
    /*** Hockey ***/
#ifdef SHELBY_APPSTORE
    // Making sure there are no updates in the target we use for dev & app store release
    [[BITHockeyManager sharedHockeyManager] setDisableUpdateManager:YES];
#endif

    /*** Localytics ***/
    [[LocalyticsSession shared] startSession:LOCALYTICS_APP_KEY];

    /*** Intercom.io ***/
    [Intercom setApiKey:INTERCOM_APP_KEY forAppId:INTERCOM_APP_ID];
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

// not yet re-implemented
- (void)setupOfflineMode
{
    // Set offlineMode to OFF by Default
    if ( [[NSUserDefaults standardUserDefaults] boolForKey:kShelbyDefaultUserAuthorized] ) {
        
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kShelbyDefaultOfflineModeEnabled];
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kShelbyDefaultOfflineViewModeEnabled];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

@end
