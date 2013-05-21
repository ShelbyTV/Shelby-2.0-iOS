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
#import "ShelbyAPIClient.h"
#import "TwitterHandler.h"
#import "User+Helper.h"

NSString * const kShelbyOfflineLikesID = @"kShelbyOfflineLikesID";

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
    // KP KP: TODO: don't hardcode the order!
    DisplayChannel *likesChannel = [DisplayChannel channelForOfflineLikesWithOrder:7 inContext:[self mainThreadContext]];
    //djs fine for now, but i'd prefer this hit a helper which returned likes in proper order
    NSArray *channelEntries = [likesChannel.roll.frame allObjects];
    
    // If there are no more likes, delete the Unsynced Likes channels from CoreData
    if (![channelEntries count]) {
        [likesChannel.managedObjectContext deleteObject:likesChannel];
        
        NSError *error;
        [likesChannel.managedObjectContext save:&error];
        STVAssert(!error, @"context save failed, in delete empty likes channel");
        
        channelEntries = nil;
    }
    
    NSSortDescriptor *sortLikes = [NSSortDescriptor sortDescriptorWithKey:@"clientLikedAt" ascending:NO];
    channelEntries = [channelEntries sortedArrayUsingDescriptors:@[sortLikes]];
    [self.delegate fetchOfflineLikesDidCompleteForChannel:likesChannel with:channelEntries];
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
        [self fetchDashboardEntriesForDashboard:channel.dashboard inChannel:channel sinceDashboardEntry:(DashboardEntry *)entry];
    } else {
        STVAssert(false, @"asked to fetch entries in channel with bad parameters");
    }
}

// User
- (void)fetchStreamForUser
{
    User *user = [self fetchAuthenticatedUserOnMainThreadContext];
    if (user) {
        [ShelbyAPIClient fetchStreamForUserWithAuthToken:[user token] andBlock:^(id JSON, NSError *error) {
            if (JSON) {
                NSMutableDictionary *rollDictionary = [NSMutableDictionary dictionaryWithDictionary:JSON];
                rollDictionary[@"user_id"] = [user userID];
                rollDictionary[@"display_channel_color"] = @"444";
                rollDictionary[@"display_description"] = @"My Stream";
                rollDictionary[@"display_title"] = @"My Stream";
                
                NSManagedObjectContext *privateContext = [self createPrivateQueueContext];
                DisplayChannel *myRoll = [DisplayChannel userChannelForDashboardDictionary:rollDictionary withID:[user userID] withOrder:0 inContext:privateContext];
               
                NSArray *dashboardEntries = [self dashboardEntriesForJSON:JSON
                                                            withDashboard:myRoll.dashboard
                                                                inContext:privateContext];

                NSError *error;
                [myRoll.managedObjectContext save:&error];
                STVAssert(!error, @"context save failed, in fetch stream for user");

                dispatch_async(dispatch_get_main_queue(), ^{
                    // 2) load those channels on main thread context
                    //OPTIMIZE: we can actually pre-fetch / fault all of these objects in, we know we need them

                    DisplayChannel *mainThreadDisplayChannel =  (DisplayChannel *)[[self mainThreadContext] objectWithID:myRoll.objectID];
                    
                    NSMutableArray *mainThreadDashboardEntries = [self mainThreadDashboardEntries:dashboardEntries];
     
                    [self.delegate fetchUserChannelDidCompleteWithChannel:mainThreadDisplayChannel with:mainThreadDashboardEntries fromCache:NO];
                });                
            } else if (error) {
                
            }
        }];
    }
}


//when login is enabled, this needs to be re-thought...
- (BOOL)toggleLikeForFrame:(Frame *)frame
{
    STVAssert(frame.managedObjectContext == [self mainThreadContext], @"toggleLike expected frame from main context");
    
    User *user = [self fetchAuthenticatedUserOnMainThreadContext];
    if (user) {
        [ShelbyAPIClient postUserLikedFrame:frame.frameID userToken:user.token withBlock:^(id JSON, NSError *error) {
            if (JSON) { // success
                frame.clientLikedAt = nil;
                
                NSError *error;
                [frame.managedObjectContext save:&error];
                STVAssert(!error, @"context save failed, in toggleLikeForFrame (in block)...");
                return;
            }   
        }];
    }
    
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
    
    //djs TODO: I don't like that we're fetching all unsynced likes here
    //we should just signal the addition/removal of a single frame
    [self fetchAllUnsyncedLikes];
    
    return shouldBeLiked;
}

- (User *)fetchAuthenticatedUserOnMainThreadContext
{
    return [User currentAuthenticatedUserInContext:[self mainThreadContext]];
}


- (void) fetchFramesForRoll:(Roll *)roll
                  inChannel:(DisplayChannel *)channel
                 sinceFrame:(Frame *)sinceFrame
{
    //djs TODO
}

-(void) fetchDashboardEntriesForDashboard:(Dashboard *)dashboard
                                inChannel:(DisplayChannel *)channel
                      sinceDashboardEntry:(DashboardEntry *)sinceDashboardEntry
{
    if(!sinceDashboardEntry){
        //1) go to CoreData and hit up the delegate on main thread
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSManagedObjectContext *privateContext = [self createPrivateQueueContext];

            //djs TODO: delete cached DashboardEntries > 200
     
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
                                               withBlock:^(id JSON, NSError *error) {
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
            [self.delegate fetchChannelsDidCompleteWithError:error];
        }
    }];
}

- (void)cleanupSession
{
    [[FacebookHandler sharedInstance] facebookCleanup];   
}


- (void)logoutWithUserChannels:(NSArray *)userChannels
{
    User *user = [self fetchAuthenticatedUserOnMainThreadContext];
 // TODO: remove if, set token in helper
    if (user) {
//        [user logout];
        user.token = nil;
    }
    
    if (userChannels) {
        NSManagedObjectContext *mainContext = [self mainThreadContext];
        for (DisplayChannel *displayChannel in userChannels) {
            [mainContext deleteObject:displayChannel];
        }
    }

    [self cleanupSession];
    
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
                [context save:&error];
                STVAssert(!error, @"context save failed, put your DEBUG hat on...");
                
                [self.delegate loginUserDidCompleteWithUser:user];
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

- (void)openFacebookSessionWithAllowLoginUI:(BOOL)allowLoginUI
{
    [[FacebookHandler sharedInstance] openSessionWithAllowLoginUI:YES withBlock:^(NSDictionary *facebookUser,
                                                                                  NSString *facebookToken,
                                                                                  NSString *errorMessage) {
  
        User *user = nil;
        if (facebookUser) {
            NSManagedObjectContext *context = [self mainThreadContext];
            user = [User updateUserWithFacebookUser:facebookUser inContext:context];
        
            NSError *error;
            [context save:&error];
            STVAssert(!error, @"context save failed, put your DEBUG hat on...");
     
            [self.delegate facebookConnectDidCompleteWithUser:user];
        }
        if (facebookToken && user) {
            [ShelbyAPIClient postThirdPartyToken:@"facebook" accountID:user.facebookUID token: facebookToken andSecret:nil];
        }
        if (errorMessage) {
            [self.delegate facebookConnectDidCompleteWithError:errorMessage];
        }
    }];
}

- (void)connectTwitterWithViewController:(UIViewController *)viewController
{
    [[TwitterHandler sharedInstance] authenticateWithViewController:viewController];
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
        if ([entry isPlayable]) {
            [resultDashboardEntries addObject:entry];
        }
    }
    
    NSError *error;
    [context save:&error];
    STVAssert(!error, @"context save failed, put your DEBUG hat on...");
    return resultDashboardEntries;
}

@end
