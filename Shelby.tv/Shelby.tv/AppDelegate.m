//
//  AppDelegate.m
//  Shelby Beta
//
//  Created by Keren on 11/11/13.
//  Copyright (c) 2013 Shelby TV. All rights reserved.
//

#import "AppDelegate.h"
#import <HockeySDK/HockeySDK.h>

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

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Hockey
    [[BITHockeyManager sharedHockeyManager] configureWithBetaIdentifier:HOCKEY_BETA
                                                         liveIdentifier:HOCKEY_LIVE
                                                               delegate:self];
    [[BITHockeyManager sharedHockeyManager] startManager];

    // Override point for customization after application launch.
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
