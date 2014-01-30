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

    [[UIApplication sharedApplication] setStatusBarHidden:(!DEVICE_IPAD)];
    
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
    
    // Reseting time zome on App Launch. To get new time zone in case user changed time zone. (This is used for notifications)
    [NSTimeZone resetSystemTimeZone];

    // Appirater
    [Appirater appLaunched:YES];
    
    // https://developers.google.com/analytics/devguides/collection/ios/v3/sessions#managing
    id tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAISessionControl value:@"start"];

    // TODO: Add Shelbytv URL Schema to Shelby.tv and Beta targets
    if ([launchOptions objectForKey:UIApplicationLaunchOptionsURLKey]) {
        // KP KP: TODO: Check for LaunchOptionsURL and open App accordingly
        NSURL *url = [launchOptions objectForKey:UIApplicationLaunchOptionsURLKey];
        if ([[url scheme] isEqualToString:@"shelbytv"]) {
            [self handleOpenURL:url];
        }
    }
    
    // Handle Push Notification
    if (launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey]) {
        [self prepareToBecomeActiveFromPushNotification:launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey]];
    }
    
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

- (void)handleOpenURL:(NSURL *)url
{
    // KP KP: TODO: lets put error check
    if ([[url host] isEqualToString:@"user"]) {
        [self.brain userProfileWasTapped:[url lastPathComponent]];
    } else if ([[url host] isEqualToString:@"frame"]) {
        [self.brain openSingleVideoViewWithFrameID:[url lastPathComponent]];
    }
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
    
    // KP KP: TODO: handle Shelbytv URLS
    if ([[url scheme] isEqualToString:@"shelbytv"]) {
        [self handleOpenURL:url];
        return YES;
    }
    
    if ([[url absoluteString] hasPrefix:fbAppID]) {
        return [[FacebookHandler sharedInstance] handleOpenURL:url];
    }
    
    return YES;
}

#pragma mark - Setup Methods (Private)

- (void)setupAppAppearanceProxies
{
    //navigation bars
    if (DEVICE_IPAD) {
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
        [[UIView appearance] setTintColor:kShelbyColorGreen];
        [[UINavigationBar appearance] setTitleTextAttributes:@{NSFontAttributeName:[UIFont fontWithName:@"HelveticaNeue" size:18.0], NSForegroundColorAttributeName: [UIColor blackColor]}];
    } else {
        [[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"top-nav-bkgd"] forBarMetrics:UIBarMetricsDefault];
        [[UINavigationBar appearance] setTitleTextAttributes:@{NSFontAttributeName:[UIFont fontWithName:@"Ubuntu-Medium" size:20.0], NSForegroundColorAttributeName: [UIColor whiteColor]}];
    }
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

- (void)prepareToBecomeActiveFromPushNotification:(NSDictionary *)userInfo
{
    if (![userInfo isKindOfClass:[NSDictionary class]]) {
        return;
    }
    
    if (userInfo[@"user_id"]) {
        [ShelbyAnalyticsClient sendEventWithCategory:kAnalyticsCategoryPush
                                              action:kAnalyticsPushAfterUserPush
                                     nicknameAsLabel:YES];
        [ShelbyAnalyticsClient sendLocalyticsEvent:kLocalyticsDidLaunchAfterUserPush];
        
        [self.brain onNextBecomeActiveOpenNotificationCenterWithUserID:userInfo[@"user_id"]];
    } else if (userInfo[@"dashboard_entry_id"]) {
        [ShelbyAnalyticsClient sendEventWithCategory:kAnalyticsCategoryPush
                                              action:kAnalyticsPushAfterVideoPush
                                     nicknameAsLabel:YES];
        [ShelbyAnalyticsClient sendLocalyticsEvent:kLocalyticsDidLaunchAfterVideoPush];

        [self.brain onNextBecomeActiveOpenNotificationCenterWithDashboardEntryID:userInfo[@"dashboard_entry_id"]];
    }
}

#pragma mark - Push Notifications
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    NSString *token = [NSString stringWithFormat:@"%@",deviceToken];
    [self.brain registerDeviceToken:token];
    DLog(@"%@", token);
}
- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    [self.brain deleteDeviceToken];
    DLog(@"Error registering push notifications: %@", error.localizedDescription);
}

// Push Notifications for iOS 6
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    //not ideal, see discussion in -didReceiveRemoteNotification:fetchCompletionHandler:
    [self.brain performBackgroundFetchWithCompletionHandler:nil];
    
    if([[UIApplication sharedApplication] applicationState] != UIApplicationStateActive) {
        [self prepareToBecomeActiveFromPushNotification:userInfo];
    }
}

// Push Notifications for iOS 7
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler
{
    if (![userInfo isKindOfClass:[NSDictionary class]]) {
        completionHandler(UIBackgroundFetchResultNoData);
        return;
    }
    
    //Ideally, all notifications would include the corresponding dashboard_entry_id in payload.
    //We would then fetch just that DBE right here.  Being short on time, the short-cut is to
    //fetch user's entire (recent) dashboard, which will include the item from this notification.
    [self.brain performBackgroundFetchWithCompletionHandler:completionHandler];
    
    if([[UIApplication sharedApplication] applicationState] != UIApplicationStateActive) {
        [self prepareToBecomeActiveFromPushNotification:userInfo];
    } else {
        //when active we're not popping anything up right now
        //but the fetch above will result in an updated notification center
    }
}
@end
