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
#import "MeViewController.h"
#import "LoginViewController.h"

@interface AppDelegate ()
{
    NSManagedObjectModel *_managedObjectModel;
    NSPersistentStoreCoordinator *_persistentStoreCoordinator;
}

@property (strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (strong, nonatomic) LoginViewController *loginViewController;
@property (strong, nonatomic) NSTimer *pollAPITimer;
@property (assign, nonatomic) NSUInteger pollAPICounter;

- (void)createObservers;
- (void)pollAPI;

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
    
    // Create Observers
    [self createObservers];
    
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
    
    // Begin Polling API
    self.pollAPICounter = 0;
    self.pollAPITimer = [NSTimer scheduledTimerWithTimeInterval:10.0f target:self selector:@selector(pollAPI) userInfo:nil repeats:YES];
    [self.pollAPITimer fire];
    DLog(@"Poll Timer Started");
    
    // Remove _loginViewController if it exists
    if ( _loginViewController ) [self.loginViewController dismissViewControllerAnimated:YES completion:nil];
    
}

- (void)pollAPI
{
    
    CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_User];
    User *user = [dataUtility fetchUser];
    
    switch ( _pollAPICounter ) {
        
        case 0: { // Stream
            
            self.pollAPICounter = 1;
            
            NSString *authToken = [user token];
            NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:kAPIShelbyGetStream, authToken]];
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
            [request setHTTPMethod:@"GET"];
            
            AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

                    CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Stream];
                    [dataUtility storeStream:JSON];
                    
                });
                
            } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
                
                DLog(@"Problem fetching Stream");
                
            }];
            
            [operation start];
            
        } break;
            
        case 1: { // Queue Roll
            
            self.pollAPICounter = 2;
            
            NSString *authToken = [user token];
            NSString *queueRollID = [user queueRollID];
            NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:kAPIShelbyGetRollFrames, queueRollID, authToken]];
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
            [request setHTTPMethod:@"GET"];
            
            AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    
                    CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_QueueRoll];
                    [dataUtility storeRollFrames:JSON];
                    
                });
                
            } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
                
                DLog(@"Problem fetching Queue Roll");
                
            }];
            
            [operation start];
            
        } break;
            
            
        case 2: { // Personal Roll
            
            self.pollAPICounter = 0;
            
            NSString *authToken = [user token];
            NSString *personalRollID = [user personalRollID];
            NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:kAPIShelbyGetRollFrames, personalRollID, authToken]];
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
            [request setHTTPMethod:@"GET"];
            
            AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    
                    CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_PersonalRoll];
                    [dataUtility storeRollFrames:JSON];
                    
                });
                
            } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
                
                DLog(@"Problem fetching User Personal Roll");
                
            }];
            
            [operation start];
            
        } break;

            
        default:
            break;
    }
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