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
#import "FacebookHandler.h"
#import "GAI.h"
#import "Harpy.h"
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
    
    // not yet re-implemented
//    [self setupOfflineMode];
    
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
    
    // Enable Audio Play in Vibrate and Background Modes
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    
    // prevent display from sleeping while watching video
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    
    [[FacebookHandler sharedInstance] handleDidBecomeActive];
}

- (void)applicationWillResignActive:(UIApplication *)application
{

}

- (void)applicationWillTerminate:(UIApplication *)application
{

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
    [[Harpy sharedInstance] setAppID:@"467849037"];
    [[Harpy sharedInstance] setAlertType:HarpyAlertTypeOption];
    [[Harpy sharedInstance] checkVersion];
    
    // TODO - Uncomment for AppStore
    // [Panhandler sharedInstance];
    
    [GAI sharedInstance].trackUncaughtExceptions = YES; // Optional: automatically send uncaught exceptions to Google Analytics.
    [GAI sharedInstance].dispatchInterval = 20;         // Optional: set Google Analytics dispatch interval to e.g. 20 seconds.
    [GAI sharedInstance].debug = NO;                    // Optional: set to YES for extra debugging information.
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
