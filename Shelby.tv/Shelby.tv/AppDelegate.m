//
//  AppDelegate.m
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 10/17/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

#import "AppDelegate.h"

// Apple Libraries
#import <AVFoundation/AVFoundation.h>

// View Controlles
#import "StreamViewController.h"
#import "LoginViewController.h"

@interface AppDelegate ()
{
    NSManagedObjectModel *_managedObjectModel;
    NSPersistentStoreCoordinator *_persistentStoreCoordinator;
}

@property (strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (strong, nonatomic) LoginViewController *loginViewController;

- (void)createObservers;

@end

@implementation AppDelegate
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize loginViewController = _loginViewController;
@synthesize loggedInUser = _loggedInUser;

#pragma mark - UIApplicationDelegate Methods
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    
    // Create Observers
    [self createObservers];
    
    // Create UIWindow and rootViewController
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    UIViewController *viewController = [[StreamViewController alloc] initWithNibName:@"StreamViewController" bundle:nil];
    self.window.rootViewController = viewController;
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
    
    // Disable Idle Timer
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - Private Methods
- (void)createObservers
{
 
}

- (void)userIsAuthorized
{
    
    // Set NSUserDefault
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kUserAuthorizedDefault];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // Set User object in AppDelegate for quick reference
    CoreDataUtility *utility = [[CoreDataUtility alloc] initWithRequestType:DataAPIRequestType_User];
    self.loggedInUser = [utility fetchUser];
    
    // Remove _loginViewController if it exists
    if ( _loginViewController ) [self.loginViewController dismissModalViewControllerAnimated:YES];
    
    // Begin Polling API
    DLog(@"%@", self.loggedInUser);
    
}


#pragma mark - Core Data Accessor Methods
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
    
    NSURL *applicationDocumentsDirectory = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    
    NSURL *storeURL = [applicationDocumentsDirectory URLByAppendingPathComponent:@"Shelby.tv.sqlite"];
    
    NSError *error = nil;
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    
    if ( ![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error] )
    {
        // Delete datastore if there's a conflict. User can re-login to repopulate the datastore.
        [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil];
        
        // Retry
        if ( ![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error] )
        {
            NSLog(@"Could not save changes to Core Data. Error: %@, %@", error, [error userInfo]);
        }
    }
    
    return _persistentStoreCoordinator;
}

@end