//
//  ShelbyDataMediator.m
//  Shelby.tv
//
//  Created by Daniel Spinosa on 4/29/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyDataMediator.h"
#import "ShelbyAPIClient.h"
#import "DisplayChannel+Helper.h"

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
    //djs TODO 1) go to CoreData and hit up the delegate on main thread
    DLog(@"TODO: fetch channels from CoreData");
    //[self.delegate fetchChannelsDidCompleteWith:nil fromCache:YES];
    
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

-(void)logout
{
    assert(!"TODO: implement logout");
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
    NSAssert([NSThread isMainThread], @"must only use main thread context on main thread");
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
}

#pragma mark - Parsing Helpers

//djs TODO: make constant strings externs
//returns nil on error, otherwise array of DisplayChannel objects
- (NSArray *)channelsForJSON:(id)JSON inContext:(NSManagedObjectContext *)context
{
    NSMutableArray *resultDisplayChannels = [@[] mutableCopy];
    NSInteger order = 0;
    
    if(![JSON isKindOfClass:[NSDictionary class]]){
        return nil;
    }
    NSDictionary *jsonDict = (NSDictionary *)JSON;
    NSArray *categoriesDictArray = jsonDict[@"result"];
    
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
    
    [context save:nil];
    return resultDisplayChannels;
}

@end
