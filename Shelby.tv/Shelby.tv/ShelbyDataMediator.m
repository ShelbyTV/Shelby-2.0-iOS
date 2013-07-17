//
//  ShelbyDataMediator.m
//  Shelby.tv
//
//  Created by Daniel Spinosa on 4/29/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyDataMediator.h"

#import "Dashboard+Helper.h"
#import "DisplayChannel+Helper.h"
#import "DashboardEntry+Helper.h"
#import "FacebookHandler.h"
#import "Frame+Helper.h"
#import "Roll+Helper.h"
#import "ShelbyAPIClient.h"
#import "TwitterHandler.h"
#import "User+Helper.h"

NSString * const kShelbyOfflineLikesID = @"kShelbyOfflineLikesID";
NSString * const kShelbyNotificationFacebookConnectCompleted = @"kShelbyNotificationFacebookConnectCompleted";
NSString * const kShelbyNotificationTwitterConnectCompleted = @"kShelbyNotificationTwitterConnectCompleted";

@interface ShelbyDataMediator()
@property (nonatomic, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, strong) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, strong) NSManagedObjectContext *mainThreadMOC;
@end

@implementation ShelbyDataMediator

+ (ShelbyDataMediator *)sharedInstance
{
    static ShelbyDataMediator *sharedInstance = nil;
    static dispatch_once_t modelToken = 0;
    dispatch_once(&modelToken, ^{
        sharedInstance = [[super allocWithZone:NULL] init];
    });
    
    return sharedInstance;
}

/*
 * New pattern for using ManagedObjectContexts...
 *
 * After watching WWDC 2012 #214 and reading http://www.objc.io/issue-2/common-background-practices.html
 *
 * Internal to this class, we should...
 * 1) create, and hang on to, a permenent privateQueueContext
 * 2) have it register for change notifications and merge them into itself
 * 3) have the mainThread context register for change notifications and merge them into itself as well
 * 4) Re-work the API fetch->save->dispatch logic as follows...
 *      -initial fetch-
 *      1) CoreData-only initial fetching can just use the main thread, it's going to be fast
 *      -API fetch-
 *      1) do the fetch, then SAVE using a block from private queue
 *      2) send them to the UI on the main thread MoC like we're already doing
 *          ** make sure the main thread MoC got the notification before this runs **
 *
 *
 *
 * Externally, if anybody uses createPrivateQueueContext or mainThreadContext need to make sure....
 * 1) They are performing operations using block syntax.
 * 2) They don't hang on to the context
 *
 */

- (void)fetchChannels
{
    // 1) go to CoreData and hit up the delegate on main thread
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray *cachedChannels = [DisplayChannel allChannelsInContext:[self createPrivateQueueContext]];
        if(cachedChannels && [cachedChannels count]){
            dispatch_async(dispatch_get_main_queue(), ^{
                // 2) load those channels on main thread context
                //OPTIMIZE: we can actually pre-fetch / fault all of these objects in, we know we need them
                NSMutableArray *mainThreadDisplayChannels = [NSMutableArray arrayWithCapacity:[cachedChannels count]];
                for (DisplayChannel *channel in cachedChannels) {
                    DisplayChannel *mainThreadChannel = (DisplayChannel *)[[self mainThreadContext] objectWithID:channel.objectID];
                    [mainThreadDisplayChannels addObject:mainThreadChannel];
                }
                [self.delegate fetchChannelsDidCompleteWith:mainThreadDisplayChannels fromCache:YES];
            });
        }
    });
    
    
    //2) fetch remotely NB: AFNetworking returns us to the main thread
    [ShelbyAPIClient fetchChannelsWithBlock:^(id JSON, NSError *error) {
        if(JSON){
            // 1) store this in core data (with a new context b/c we're on some background thread)
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSArray *channels = [self channelsForJSON:JSON inContext:[self createPrivateQueueContext]];
                dispatch_async(dispatch_get_main_queue(), ^{
                    // 2) load those channels on main thread context
                    //OPTIMIZE: we can actually pre-fetch / fault all of these objects in, we know we need them
                    NSMutableArray *mainThreadDisplayChannels = [NSMutableArray arrayWithCapacity:[channels count]];
                    for (DisplayChannel *channel in channels) {
                        DisplayChannel *mainThreadChannel = (DisplayChannel *)[[self mainThreadContext] objectWithID:channel.objectID];
                        [mainThreadDisplayChannels addObject:mainThreadChannel];
                    }
                    [self.delegate fetchChannelsDidCompleteWith:mainThreadDisplayChannels fromCache:NO];
                });
            });
            
        } else {
            [self.delegate fetchChannelsDidCompleteWithError:error];
        }
    }];
}

- (void)fetchAllUnsyncedLikes
{
    DisplayChannel *likesChannel = [DisplayChannel channelForOfflineLikesInContext:[self mainThreadContext]];
    NSArray *channelEntries = [likesChannel.roll.frame allObjects];
    
    NSSortDescriptor *sortLikes = [NSSortDescriptor sortDescriptorWithKey:@"clientLikedAt" ascending:NO];
    channelEntries = [channelEntries sortedArrayUsingDescriptors:@[sortLikes]];
    [self.delegate fetchOfflineLikesDidCompleteForChannel:likesChannel with:channelEntries];
}

- (DisplayChannel *)fetchDisplayChannelOnMainThreadContextForRollID:(NSString *)rollID
{
    return [DisplayChannel fetchChannelWithRollID:rollID inContext:[self mainThreadContext]];
}

- (DisplayChannel *)fetchDisplayChannelOnMainThreadContextForDashboardID:(NSString *)dashboardID
{
    return [DisplayChannel fetchChannelWithDashboardID:dashboardID inContext:[self mainThreadContext]];
}

- (void)fetchEntriesInChannel:(DisplayChannel *)channel sinceEntry:(NSManagedObject *)entry
{
    if(!channel.canFetchRemoteEntries){
        //djs should probably do a local fetch and update accordingly
        //but, we only have 1 special case right now.
        //so, until we have logic to properly handle this...
        return;
    }
    
    if(channel.roll && (!entry || [entry isKindOfClass:[Frame class]])){
        [self fetchFramesForRoll:channel.roll inChannel:channel sinceFrame:(Frame *)entry];
    } else if(channel.dashboard && (!entry || [entry isKindOfClass:[DashboardEntry class]])){
        NSString *authToken = nil;
        User *currentUser = [self fetchAuthenticatedUserOnMainThreadContext];
        if (currentUser) {
            authToken = currentUser.token;
        }
        [self fetchDashboardEntriesForDashboard:channel.dashboard inChannel:channel sinceDashboardEntry:(DashboardEntry *)entry withAuthToken:authToken];
    } else {
        STVAssert(false, @"asked to fetch entries in channel with bad parameters");
    }
}


- (void)fetchUpvoterUser:(NSString *)userID inContect:(NSManagedObjectContext *)context
{
    [ShelbyAPIClient fetchUserForUserID:userID andBlock:^(id JSON, NSError *error) {
        if (JSON) {
            [User userForDictionary:JSON inContext:context];
        }
    }];
}

- (void)likeFrame:(Frame *)frame forUser:(User *)user
{
    //Do Like
    [ShelbyAPIClient postUserLikedFrame:frame.frameID withAuthToken:user.token andBlock:^(id JSON, NSError *error) {
        if (JSON) { // success
            frame.clientUnsyncedLike = @0;
            frame.clientLikedAt = nil;
            //API is NOT returning the liked frame, so...
            [self fetchEntriesInChannel:[user displayChannelForLikesRoll] sinceEntry:nil];
            
            NSError *error;
            [frame.managedObjectContext save:&error];
            STVAssert(!error, @"context save failed, in toggleLikeForFrame when liking (in block)...");
        } else {
            DLog(@"Failed to like!  DEBUG this %@", error);
        }
    }];
}


- (void)unlikeFrame:(Frame *)frame forUser:(User *)user
{
    [ShelbyAPIClient deleteFrame:frame.frameID withAuthToken:user.token andBlock:^(id JSON, NSError *error) {
        if (JSON) {
            NSError *error;
            [frame.managedObjectContext save:&error];
            STVAssert(!error, @"context save failed, in toggleLikeForFrame when deleting (in block)...");
            
            //djs
            //TODO: need to smartly update the Browse View b/c the unliked frame is still in there :(
            //... until next launch
        } else {
            DLog(@"Failed to delete liked frame, DEBUG this %@", error);
        }
    }];

}

- (void)toggleUnsyncedLikeForFrame:(Frame *)frame
{
    BOOL shouldBeLiked = ![frame.clientUnsyncedLike boolValue];

    frame.clientUnsyncedLike = shouldBeLiked ? @1 : @0;
    
    if (frame.clientUnsyncedLike) {
        frame.clientLikedAt = [NSDate date];
    } else {
        frame.clientLikedAt = nil;
    }
    
    NSError *error;
    [frame.managedObjectContext save:&error];
    STVAssert(!error, @"context save failed, in toggleLikeForFrame...");
}

//when login is enabled, this needs to be re-thought...
- (BOOL)toggleLikeForFrame:(Frame *)frame
{
    STVAssert(frame.managedObjectContext == [self mainThreadContext], @"toggleLike expected frame from main context");
    
    User *user = [self fetchAuthenticatedUserOnMainThreadContext];
    
    if (user) {
        if (![user hasLikedVideoOfFrame:frame]) {
            [self likeFrame:frame forUser:user];
            
            //represent liked state until the API call succeeds
            frame.clientUnsyncedLike = @1;
            frame.clientLikedAt = [NSDate date];
            
            return YES;
            
        } else {
            //Do Unlike
            Frame *likedFrame = [user likedFrameWithVideoOfFrame:frame];
            STVAssert(likedFrame, @"expected liked frame");
 
            [self unlikeFrame:frame forUser:user];
            
            //represnt unliked state assuming the API call succeeds
            frame.clientUnsyncedLike = @0;
            frame.clientLikedAt = nil;
            likedFrame.clientUnliked = @1;
            return NO;
        }
        
    } else {
        //not logged in
        BOOL shouldBeLiked = ![frame.clientUnsyncedLike boolValue];
        [self toggleUnsyncedLikeForFrame:frame];
        
        //djs TODO: I don't like that we're fetching all unsynced likes here
        //we should just signal the addition/removal of a single frame
        [self fetchAllUnsyncedLikes];
        
        return shouldBeLiked;
    }
}

- (User *)fetchAuthenticatedUserOnMainThreadContext
{
    return [self fetchAuthenticatedUserOnMainThreadContextWithForceRefresh:NO];
}

- (User *)fetchAuthenticatedUserOnMainThreadContextWithForceRefresh:(BOOL)forceRefresh
{
    return [User currentAuthenticatedUserInContext:[self mainThreadContext] forceRefresh:forceRefresh];
}


- (void)fetchFramesForRoll:(Roll *)roll
                 inChannel:(DisplayChannel *)channel
                sinceFrame:(Frame *)sinceFrame
{
    if(!sinceFrame){
        //1) go to CoreData and hit up the delegate on main thread
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSManagedObjectContext *privateContext = [self createPrivateQueueContext];
            
            Roll *privateContextRoll = (Roll *)[privateContext objectWithID:roll.objectID];
            //djs TODO: delete cached Frames > 200
            NSArray *cachedFrames = [Frame framesForRoll:privateContextRoll inContext:privateContext];
            
            if(cachedFrames && [cachedFrames count]){
                dispatch_async(dispatch_get_main_queue(), ^{
                    // 2) load those frames on main thread context
                    //OPTIMIZE: we can actually pre-fetch / fault all of these objects in, we know we need them
                    NSMutableArray *mainThreadFrames = [self mainThreadFrames:cachedFrames];
                    
                    [self.delegate fetchEntriesDidCompleteForChannel:(DisplayChannel *)[[self mainThreadContext] objectWithID:channel.objectID]
                                                                with:mainThreadFrames
                                                           fromCache:YES];
                });
            }
        });
    }
    
    
    //2) fetch remotely NB: AFNetworking returns us to the main thread
    [ShelbyAPIClient fetchFramesForRollID:roll.rollID
                               sinceEntry:sinceFrame
                                withBlock:^(id JSON, NSError *error) {
            if(JSON){
                // 1) store this in core data (with a new context b/c we're on some background thread)
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    NSManagedObjectContext *privateContext = [self createPrivateQueueContext];
                    DisplayChannel *privateContextChannel = (DisplayChannel *)[privateContext objectWithID:channel.objectID];
                    Roll *privateContextRoll = (Roll *)[privateContext objectWithID:roll.objectID];
                    NSArray *frames = [self framesForJSON:JSON withRoll:privateContextRoll inContext:privateContext];
                    privateContextChannel.roll.frame = [NSSet setWithArray:frames];
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSMutableArray *results = [@[] mutableCopy];
                        //OPTIMIZE: we can actually pre-fetch / fault all of these objects in, we know we need them
                        //this is probably fairly slow
                        for (Frame *frame in frames) {
                            Frame *mainThreadFrame = (Frame *)[[self mainThreadContext] objectWithID:frame.objectID];
                            [results addObject:mainThreadFrame];
                        }
                        [self.delegate fetchEntriesDidCompleteForChannel:(DisplayChannel *)[[self mainThreadContext] objectWithID:channel.objectID]
                                                                    with:results
                                                               fromCache:NO];
                    });
                });
                
            } else {
                [self.delegate fetchEntriesDidCompleteForChannel:(DisplayChannel *)[[self mainThreadContext] objectWithID:channel.objectID]
                                                       withError:error];
                DLog(@"fetch error: %@", error);
            }
    }];
}

-(void) fetchDashboardEntriesForDashboard:(Dashboard *)dashboard
                                inChannel:(DisplayChannel *)channel
                      sinceDashboardEntry:(DashboardEntry *)sinceDashboardEntry
                            withAuthToken:(NSString *)authToken
{
    if(!sinceDashboardEntry){
        //1) go to CoreData and hit up the delegate on main thread
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSManagedObjectContext *privateContext = [self createPrivateQueueContext];

            //djs TODO: delete cached DashboardEntries > 200
            // could use relationship on dashboard, but instead using this helper to get dashboard entries in correct order
            NSArray *cachedDashboardEntries = [DashboardEntry entriesForDashboard:(Dashboard *)[privateContext objectWithID:dashboard.objectID]
                                                                        inContext:privateContext];
            if(cachedDashboardEntries && [cachedDashboardEntries count]){
                dispatch_async(dispatch_get_main_queue(), ^{
                    // 2) load those dashboard entries on main thread context
                    //OPTIMIZE: we can actually pre-fetch / fault all of these objects in, we know we need them
                    NSMutableArray *mainThreadDashboardEntries = [self mainThreadDashboardEntries:cachedDashboardEntries];
                    
                    [self.delegate fetchEntriesDidCompleteForChannel:(DisplayChannel *)[[self mainThreadContext] objectWithID:channel.objectID]
                                                                with:mainThreadDashboardEntries
                                                           fromCache:YES];
                });
            }
        });
    }
    
    
    //2) fetch remotely NB: AFNetworking returns us to the main thread
    [ShelbyAPIClient fetchDashboardEntriesForDashboardID:dashboard.dashboardID
                                              sinceEntry:sinceDashboardEntry
                                           withAuthToken:authToken
                                                andBlock:^(id JSON, NSError *error) {
        if(JSON){            
            // 1) store this in core data (with a new context b/c we're on some background thread)
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSManagedObjectContext *privateContext = [self createPrivateQueueContext];
                Dashboard *privateContextDashboard = (Dashboard *)[privateContext objectWithID:dashboard.objectID];
                NSArray *dashboardEntries = [self dashboardEntriesForJSON:JSON
                                                            withDashboard:privateContextDashboard
                                                                inContext:privateContext];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSMutableArray *results = [@[] mutableCopy];
                    //OPTIMIZE: we can actually pre-fetch / fault all of these objects in, we know we need them
                    //this is probably fairly slow
                    for (DashboardEntry *dashboardEntry in dashboardEntries) {
                        DashboardEntry *mainThreadDashboardEntry = (DashboardEntry *)[[self mainThreadContext] objectWithID:dashboardEntry.objectID];
                        [results addObject:mainThreadDashboardEntry];
                    }
                    [self.delegate fetchEntriesDidCompleteForChannel:(DisplayChannel *)[[self mainThreadContext] objectWithID:channel.objectID]
                                                                with:results
                                                           fromCache:NO];
                });
            });
        } else {
            [self.delegate fetchEntriesDidCompleteForChannel:(DisplayChannel *)[[self mainThreadContext] objectWithID:channel.objectID]
                                                   withError:error];
        }
    }];
}

- (void)syncLikes
{
    NSManagedObjectContext *moc = [self mainThreadContext];
    DisplayChannel *likesChannel = [DisplayChannel channelForOfflineLikesInContext:moc];
    NSArray *channelEntries = [likesChannel.roll.frame allObjects];

    User *user = [User currentAuthenticatedUserInContext:moc];
    
    for (Frame *frame in channelEntries) {
        [self likeFrame:frame forUser:user];
        //TODO: remove this from the offline likes channel
    }

    [self.delegate fetchOfflineLikesDidCompleteForChannel:likesChannel with:nil];
}

- (void)cleanupSession
{
    [[FacebookHandler sharedInstance] facebookCleanup];
}

- (void)clearAllCookies
{
    NSHTTPCookieStorage *cookieStore = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (NSHTTPCookie *cookie in cookieStore.cookies) {
        [cookieStore deleteCookie:cookie];
    }
}

- (void)logoutCurrentUser
{
    User *user = [self fetchAuthenticatedUserOnMainThreadContext];
 // TODO: remove if, set token in helper
    if (user) {
//        [user logout];
        user.token = nil;
    }

    NSManagedObjectContext *mainContext = [self mainThreadContext];
    NSArray *userChannels = [User channelsForUserInContext:mainContext];
    for (DisplayChannel *displayChannel in userChannels) {
        [mainContext deleteObject:displayChannel];
    }

    [self cleanupSession];
    [self clearAllCookies];
    
    NSError *error;
    [[self mainThreadContext] save:&error];
    STVAssert(!error, @"context save failed, put your DEBUG hat on...");
}

- (void)loginUserWithEmail:(NSString *)email password:(NSString *)password
{
    [ShelbyAPIClient loginUserWithEmail:email password:password andBlock:^(id JSON, NSError *error) {
  
        if (JSON) {
            NSManagedObjectContext *context = [self mainThreadContext];
            NSDictionary *result = JSON[@"result"];
            if ([result isKindOfClass:[NSDictionary class]]) {
                User *user = [User userForDictionary:result inContext:context];
                NSError *error;
                [user.managedObjectContext save:&error];
                STVAssert(!error, @"context save failed, put your DEBUG hat on...");
                
                [self.delegate loginUserDidComplete];
                
                [self syncLikes];
                return;
            }
        }

        NSString *errorMessage = nil;
        // Error code -1009 - no connection
        // Error code -1001 - timeout
        if ([error code] == -1009 || [error code] == -1001) {
            errorMessage = @"Please make sure you are connected to the Internet";
        } else {
            errorMessage = @"Please make sure you've entered your login credientials correctly.";
        }
        
        [self.delegate loginUserDidCompleteWithError:errorMessage];
    }];
}

- (void)saveUserFromJSON:(id)JSON
{
    NSManagedObjectContext *context = [self mainThreadContext];
    NSDictionary *result = JSON[@"result"];
    if ([result isKindOfClass:[NSDictionary class]]) {
        User *user = [User userForDictionary:result inContext:context];
        NSError *error;
        [user.managedObjectContext save:&error];
        STVAssert(!error, @"context after saveUserFromJSON");
        [self syncLikes];
        return;
    }
}

- (void)signupUserWithName:(NSString *)name andEmail:(NSString *)email
{
    __weak ShelbyDataMediator *weakSelf = self;
    [ShelbyAPIClient postSignupWithName:name email:email andBlock:^(id JSON, NSError *error) {
        [weakSelf saveUserFromJSON:JSON];
        // Not sending loginUserDidComplete until signup process is done.
    }];
}

- (void)completeSignupUserWithUsername:(NSString *)username andPassword:(NSString *)password
{
    __weak ShelbyDataMediator *weakSelf = self;
    [ShelbyAPIClient completeUserSignupWithNickname:username password:password passwordConfirmation:password andBlock:^(id JSON, NSError *error) {
        [weakSelf saveUserFromJSON:JSON];
        [self.delegate loginUserDidComplete];
    }];
}

- (void)userAskForFacebookPublishPermissions
{
    [self openFacebookSessionWithAllowLoginUI:NO andAskPublishPermissions:YES];
}

- (void)openFacebookSessionWithAllowLoginUI:(BOOL)allowLoginUI
{
    [self openFacebookSessionWithAllowLoginUI:allowLoginUI andAskPublishPermissions:NO];
}

- (void)openFacebookSessionWithAllowLoginUI:(BOOL)allowLoginUI andAskPublishPermissions:(BOOL)askForPublishPermission
{
    [[FacebookHandler sharedInstance] openSessionWithAllowLoginUI:YES
                                          andAskPublishPermission:askForPublishPermission
                                                        withBlock:^(NSDictionary *facebookUser,
                                                                                  NSString *facebookToken,
                                                                                  NSString *errorMessage) {
        User *user = nil;
        if (facebookUser) {
            NSManagedObjectContext *context = [self mainThreadContext];
            user = [User currentAuthenticatedUserInContext:context];
            //try adding token to the user
            [ShelbyAPIClient postThirdPartyToken:@"facebook"
                                   withAccountID:facebookUser[@"id"]
                                      oauthToken:facebookToken
                                     oauthSecret:nil
                                 shelbyAuthToken:user.token
                                        andBlock:^(id JSON, NSError *error) {
                                            if(!error){
                                                //user updated by API
                                                [user updateWithFacebookUser:facebookUser];
                                                NSError *error;
                                                [user.managedObjectContext save:&error];
                                                STVAssert(!error, @"context save failed saving User after facebook login...");
                                               
                                                [self.delegate facebookConnectDidComplete];
                                               
                                                [[NSNotificationCenter defaultCenter] postNotificationName:kShelbyNotificationFacebookConnectCompleted object:nil];

                                                if (askForPublishPermission) {
                                                    [[FacebookHandler sharedInstance] askForPublishPermissions];
                                                }
                                            } else {
                                                //did NOT add this auth to the current user
                                                [self.delegate facebookConnectDidCompleteWithError:nil];
                                            }
                                        }];
        } else if (facebookToken) {
            [self.delegate facebookConnectDidComplete];
        } else if (errorMessage) {
            [self.delegate facebookConnectDidCompleteWithError:errorMessage];
        }
     }];
}

- (void)connectTwitterWithViewController:(UIViewController *)viewController
{
    User *user = [User currentAuthenticatedUserInContext:[self createPrivateQueueContext]];
    NSString *token = nil;
    if (user) {
        token = user.token;
    }
    [[TwitterHandler sharedInstance] authenticateWithViewController:viewController withDelegate:self.delegate andAuthToken:token];
}

- (NSManagedObjectModel *)managedObjectModel
{
    if ( _managedObjectModel ) {
        return _managedObjectModel;
    }
    _managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
    return _managedObjectModel;
}

// TODO: this should perform lightweight migrations
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
    
    //djs TODO: handle this gracefully...
    //djs NB: IF you crash when updating CoreData, next run you can get an EXC_BAD_ACCESS on the following line
    if ( ![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error] )
    {
        // Delete datastore if there's a conflict. User can re-login to repopulate the datastore.
        //djs TODO: perform lightweight migration when possible
        [fileManager removeItemAtURL:storeURL error:nil];
        
        // Retry
        if ( ![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error] )
        {
            DLog(@"Could not save changes to Core Data. Error: %@, %@", error, [error userInfo]);
        }
    }
    
    return _persistentStoreCoordinator;
}

- (NSManagedObjectContext *)mainThreadContext
{
    STVAssert([NSThread isMainThread], @"must only use main thread context on main thread");
    if(!self.mainThreadMOC){
        self.mainThreadMOC = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        self.mainThreadMOC.persistentStoreCoordinator = [self persistentStoreCoordinator];
        self.mainThreadMOC.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
        self.mainThreadMOC.undoManager = nil;
        //djs old CoreDataUtility set this, but I'm not going to.  Don't see a reason to keep this stuff around, let it be faulted in.
        //self.mainThreadMOC.retainsRegisteredObjects = YES;
    }
    return self.mainThreadMOC;
}

// XXX Are we using private MOCs properly?
//
// According to http://www.objc.io/issue-2/common-background-practices.html
// when you create a context with NSPrivateQueueConcurrencyType, you must perform all operations on the context
// via the context's -performBlock or -performBlockAndWait to ensure the operation runs on the private thread (b/c the context itself
// is managing it's own operation queue).  Although this seems to be working fine, we're not doing that...
- (NSManagedObjectContext *)createPrivateQueueContext
{
    NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    context.persistentStoreCoordinator = [self persistentStoreCoordinator];
    context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
    context.undoManager = nil;
    return context;
}

- (void)nuclearCleanup
{
    self.mainThreadMOC = nil;
    self.persistentStoreCoordinator = nil;
    
    DLog(@"Deleting Persistent Store Backing File");
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSURL *applicationDocumentsDirectory = [[fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    NSURL *storeURL = [applicationDocumentsDirectory URLByAppendingPathComponent:@"Shelby.tv.sqlite"];
    [fileManager removeItemAtURL:storeURL error:nil];
    
    DLog(@"Recreating Persistent Store Coordinator");
    [self persistentStoreCoordinator];
    
    [self cleanupSession];
}

#pragma mark - Parsing Helpers
- (NSMutableArray *)mainThreadDashboardEntries:(NSArray *)backgroundThreadDashboardEntries
{
    NSMutableArray *mainThreadDashboardEntries = [NSMutableArray arrayWithCapacity:[backgroundThreadDashboardEntries count]];
    for (DashboardEntry *entry in backgroundThreadDashboardEntries) {
        DashboardEntry *mainThreadEntry = (DashboardEntry *)[[self mainThreadContext] objectWithID:entry.objectID];
        [mainThreadDashboardEntries addObject:mainThreadEntry];
    }

    return mainThreadDashboardEntries;
}

- (NSMutableArray *)mainThreadFrames:(NSArray *)backgroundThreadFrames
{
    NSMutableArray *mainThreadFrames = [NSMutableArray arrayWithCapacity:[backgroundThreadFrames count]];
    for (Frame *entry in backgroundThreadFrames) {
        Frame *mainThreadEntry = (Frame *)[[self mainThreadContext] objectWithID:entry.objectID];
        [mainThreadFrames addObject:mainThreadEntry];
    }
    
    return mainThreadFrames;
    
}

//djs TODO: make constant strings externs
//returns nil on error, otherwise array of DisplayChannel objects
- (NSArray *)channelsForJSON:(id)JSON inContext:(NSManagedObjectContext *)context
{
    if(![JSON isKindOfClass:[NSDictionary class]]){
        return nil;
    }
    
    NSInteger order = 0;
    NSDictionary *jsonDict = (NSDictionary *)JSON;
    NSArray *categoriesDictArray = jsonDict[@"result"];
    
    if(![categoriesDictArray isKindOfClass:[NSArray class]]){
        return nil;
    }
    
    NSMutableArray *resultDisplayChannels = [@[] mutableCopy];
    
    for (NSDictionary *category in categoriesDictArray) {
        if(![category isKindOfClass:[NSDictionary class]]){
            continue;
        }
        //each category dictionary looks like: { category_title: "", rolls: [], user_channels: [] }
        NSArray *rolls = category[@"rolls"];
        if([rolls isKindOfClass:[NSArray class]]){
            for (NSDictionary *roll in rolls) {
                if([roll isKindOfClass:[NSDictionary class]]){
                    DisplayChannel *channel = [DisplayChannel channelForRollDictionary:roll
                                                                             withOrder:order
                                                                             inContext:context];
                    order++;
                    [resultDisplayChannels addObject:channel];
                }
            }
        }
        NSArray *dashboards = category[@"user_channels"];
        if([dashboards isKindOfClass:[NSArray class]]){
            for (NSDictionary *dashboard in dashboards) {
                if([dashboard isKindOfClass:[NSDictionary class]]){
                    DisplayChannel *channel = [DisplayChannel channelForDashboardDictionary:dashboard
                                                                                  withOrder:order
                                                                                  inContext:context];
                    order++;
                    [resultDisplayChannels addObject:channel];
                }
            }
        }
    }
    
    NSError *error;
    [context save:&error];
    STVAssert(!error, @"context save failed, put your DEBUG hat on...");
    return resultDisplayChannels;
}

- (NSArray *)framesForJSON:(id)JSON withRoll:(Roll *)roll inContext:(NSManagedObjectContext *)context
{
    if(![JSON isKindOfClass:[NSDictionary class]]){
        return nil;
    }
    
    NSDictionary *jsonDict = (NSDictionary *)JSON;
    NSDictionary *rollDictArray = jsonDict[@"result"];
    
    if(![rollDictArray isKindOfClass:[NSDictionary class]]){
        return nil;
    }
    
    NSArray *frames = rollDictArray[@"frames"];
    if (![frames isKindOfClass:[NSArray class]]){
        return nil;
    }

    NSMutableArray *resultDashboardEntries = [@[] mutableCopy];
    
    for (NSDictionary *frameDict in frames) {
        if(![frameDict isKindOfClass:[NSDictionary class]]){
            continue;
        }
        
        Frame *entry = [Frame frameForDictionary:frameDict inContext:context];
 
        if (entry) {
            [resultDashboardEntries addObject:entry];
        }
    }
    
    NSError *error;
    [context save:&error];
    STVAssert(!error, @"context save failed, in framesForJSON...");
    return resultDashboardEntries;
}

- (NSArray *)dashboardEntriesForJSON:(id)JSON withDashboard:(Dashboard *)dashboard inContext:(NSManagedObjectContext *)context
{
    if(![JSON isKindOfClass:[NSDictionary class]]){
        return nil;
    }
    
    NSDictionary *jsonDict = (NSDictionary *)JSON;
    NSArray *dashboardEntriesDictArray = jsonDict[@"result"];
    
    if(![dashboardEntriesDictArray isKindOfClass:[NSArray class]]){
        return nil;
    }
    
    NSMutableArray *resultDashboardEntries = [@[] mutableCopy];
    
    for (NSDictionary *dashboardEntryDict in dashboardEntriesDictArray) {
        if(![dashboardEntryDict isKindOfClass:[NSDictionary class]]){
            continue;
        }
        DashboardEntry *entry = [DashboardEntry dashboardEntryForDictionary:dashboardEntryDict
                                                              withDashboard:dashboard
                                                                  inContext:context];
        if (entry) {
            [resultDashboardEntries addObject:entry];
        }
    }
    
    NSError *error;
    [context save:&error];
    STVAssert(!error, @"context save failed, put your DEBUG hat on...");
    return resultDashboardEntries;
}

@end
