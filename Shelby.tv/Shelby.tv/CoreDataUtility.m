//
//  CoreDataUtility.m
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 10/25/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

#import "CoreDataUtility.h"
#import "SPVideoExtractor.h"

@interface CoreDataUtility ()

@property (strong ,nonatomic) NSManagedObjectContext *context;
@property (nonatomic) AppDelegate *appDelegate;
@property (assign, nonatomic) DataRequestType requestType;

/// Persistance Methods
- (id)checkIfEntity:(NSString *)entityName
        withIDValue:(NSString *)entityIDValue
           forIDKey:(NSString *)entityIDKey;

- (void)deleteFrame:(Frame *)frame;
- (void)removeOlderVideoFramesFromStream;
- (void)removeOlderVideoFramesFromLikes;
- (void)removeOlderVideoFramesFromPersonalRoll;
- (void)removeOlderVideoFramesFromCategoryChannel:(NSString *)channelID;
- (void)removeOlderVideoFramesFromCategoryRoll:(NSString *)rollID;

/// Storage Methods
- (void)storeFrame:(Frame *)frame forDictionary:(NSDictionary *)frameDictionary;
- (void)storeConversation:(Conversation *)conversation fromDictionary:(NSDictionary *)conversationDictionary;
- (void)storeCreator:(Creator *)creator fromDictionary:(NSDictionary *)creatorDictionary;
- (void)storeMessagesFromConversation:(Conversation *)conversation withDictionary:(NSDictionary *)conversationDictionary;
- (void)storeRoll:(Roll *)roll fromDictionary:(NSDictionary *)rollDictionary;
- (void)storeVideo:(Video *)video fromDictionary:(NSDictionary *)videoDictionary;
- (void)storeCategoryRolls:(NSArray *)rollsArray withInitialTag:(NSUInteger)tag;
- (void)storeCategoryChannels:(NSArray *)channelsArray withInitialTag:(NSUInteger)tag;

/// Fetching Methods
- (NSMutableArray *)filterPlayableStreamFrames:(NSArray *)frames;
- (NSMutableArray *)filterPlayableFrames:(NSArray *)frames;
- (NSMutableArray *)removeDuplicateFrames:(NSMutableArray *)frames;
- (void)postNotificationVideoInContext:(NSManagedObjectContext *)context;

/// Syncing Methods
- (void)syncCategories:(NSDictionary *)categoriesArray;
- (void)syncCategoryChannels:(NSMutableArray *)webChannelIDsArray;
- (void)syncCategoryRolls:(NSMutableArray *)webRollIDsArray;

/// Helper methods
- (BOOL)isSupportedProvider:(Frame *)frame;
- (BOOL)isUnplayableVideo:(Video *)video;

@end

@implementation CoreDataUtility

#pragma mark - Initialization Methods
- (id)initWithRequestType:(DataRequestType)requestType
{
    if ( self = [super init] ) {
   
        self.appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        self.context = [self.appDelegate context];
        self.requestType = requestType;
        
        // Add observer for mergining contexts
        [[NSNotificationCenter defaultCenter] addObserver:_appDelegate
                                                 selector:@selector(mergeChanges:)
                                                     name:NSManagedObjectContextDidSaveNotification
                                                   object:_context];
        
    }
    
    return self;
}

#pragma mark - Persistance Methods (Public)
- (void)saveContext:(NSManagedObjectContext *)context
{

    if ( context ) {
        
        NSError *error = nil;
        
        if( ![context save:&error] ) { // Error
            
            DLog(@"Failed to save to data store: %@", [error localizedDescription]);
            DLog(@"Error for Data_Request: %d", _requestType);
            
            NSArray *detailedErrors = [error userInfo][NSDetailedErrorsKey];
            
            if( detailedErrors != nil && [detailedErrors count] > 0 ) {
                
                for(NSError* detailedError in detailedErrors) {
                    DLog(@"Detailed Error: %@", [detailedError userInfo]);
                }
                
            } else {
                
                DLog(@"%@", [error userInfo]);
                
            }
            
        } else { // Success
            
            switch ( _requestType ) {
                    
                case DataRequestType_Fetch: {
                    
                    // Should not get here
                    
                } break;
                    
                case DataRequestType_StoreUser: {
                    
                    DLog(@"User Data Saved Successfully!");
                    [self.appDelegate userIsAuthorized];
                    
                } break;
                    
                case DataRequestType_StoreCategories: {
                    
                    DLog(@"Categories Synced and Saved Successfully");
                    [self.appDelegate didLoadCategories];
                    
                } break;
                    
                case DataRequestType_Sync:{
                    
                    DLog(@"Core Data Sync Successful");
                    
                } break;
                    
                case DataRequestType_ActionUpdate: {
                    
                    DLog(@"User Action Update Successful");
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[NSNotificationCenter defaultCenter] postNotificationName:kShelbySPUserDidScrollToUpdate object:nil];
                    });
                    
                } break;
                    
                case DataRequestType_VideoExtracted: {
                    
                    DLog(@"Video Extracted and Data Stored Successfully!");
                    [self postNotificationVideoInContext:context];
                    
                } break;
                    
                case DataRequestType_StoreVideoInCache: {
                    
                    DLog(@"Video Stored in Cache");
                    
                } break;
                    
                default:
                    break;
            }
        }
    }
}

- (void)removeOlderVideoFramesForGroupType:(GroupType)groupType andCategoryID:(NSString *)categoryID
{

    switch ( groupType ) {
            
        case GroupType_Likes:{
        
            if ( [[NSUserDefaults standardUserDefaults] boolForKey:kShelbyDefaultUserAuthorized] ) {
                
                [self removeOlderVideoFramesFromLikes];
            }
        
        } break;
            
        case GroupType_PersonalRoll:{
            
            if ( [[NSUserDefaults standardUserDefaults] boolForKey:kShelbyDefaultUserAuthorized] ) {
                
                [self removeOlderVideoFramesFromPersonalRoll];
                
            }
            
        } break;
        
        case GroupType_Stream:{
            
            if ( [[NSUserDefaults standardUserDefaults] boolForKey:kShelbyDefaultUserAuthorized] ) {
                
                [self removeOlderVideoFramesFromStream];
                
            }
            
        } break;
            
        case GroupType_CategoryChannel: {
     
            [self removeOlderVideoFramesFromCategoryChannel:categoryID];
            
        }
            
        case GroupType_CategoryRoll: {
            
            [self removeOlderVideoFramesFromCategoryRoll:categoryID];
            
        }
    }
}

- (void)removeAllVideoExtractionURLReferences
{
    // Create fetch request
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setReturnsObjectsAsFaults:NO];
    
    // Search Stream table
    NSEntityDescription *description = [NSEntityDescription entityForName:kShelbyCoreDataEntityVideo inManagedObjectContext:_context];
    [request setEntity:description];
    
    // Execute request that returns array of stream entries
    NSMutableArray *entries = [[self.context executeFetchRequest:request error:nil] mutableCopy];
    
    for (NSUInteger i = 0; i < [entries count]; ++i ) {
        
        Video *video = (Video *)[entries objectAtIndex:i];
        [video setExtractedURL:[NSString coreDataNullTest:nil]];
        
    }
    
    DLog(@"All video extractedURLs removed");

}

#pragma mark - Storage Methods (Public)
- (void)storeUser:(NSDictionary *)resultsDictionary
{
    NSArray *userDictionary = resultsDictionary[@"result"];
    
    User *user = [self checkIfEntity:kShelbyCoreDataEntityUser
                         withIDValue:[userDictionary valueForKey:@"id"]
                            forIDKey:kShelbyCoreDataUserID];
    
    NSString *userID = [NSString coreDataNullTest:[userDictionary valueForKey:@"id"]];
    [user setValue:userID forKey:kShelbyCoreDataUserID];
    
    NSString *userImage = [NSString coreDataNullTest:[userDictionary valueForKey:@"user_image"]];
    [user setValue:userImage forKey:kShelbyCoreDataUserImage];
    
    NSString *token = [NSString coreDataNullTest:[userDictionary valueForKey:@"authentication_token"]];
    [user setValue:token forKey:kShelbyCoreDataUserToken];
    
    NSString *nickname = [NSString coreDataNullTest:[userDictionary valueForKey:@"nickname"]];
    [user setValue:nickname forKey:kShelbyCoreDataUserNickname];
    
    NSString *personalRollID = [NSString coreDataNullTest:[userDictionary valueForKey:@"personal_roll_id"]];
    [user setValue:personalRollID forKey:kShelbyCoreDataUserPersonalRollID];
    
    NSString *likesRollID = [NSString coreDataNullTest:[userDictionary valueForKey:@"watch_later_roll_id"]];
    [user setValue:likesRollID forKey:kShelbyCoreDataUserLikesRollID];

    /*
     Check if Facebook and Twitter are connected
     
     By default, set twitterConnected to NO 
     By default, set facebookConnected to NO
     */
    [user setValue:@NO forKey:kShelbyCoreDataUserTwitterConnected];
    [user setValue:@NO forKey:kShelbyCoreDataUserTwitterConnected];
    
    if ( [[userDictionary valueForKey:@"authentications"] count] ) {
        
        NSArray *authentications = [userDictionary valueForKey:@"authentications"];
        NSUInteger i = 0;
        
        while ( i < [authentications count] ) {
            
            if ( [[authentications objectAtIndex:i] containsObject:@"twitter"] ) {
                
                DLog(@"Shelby User has a Twitter account that's connected.");
                [user setValue:@YES forKey:kShelbyCoreDataUserTwitterConnected];
                
            }
            
            if ( [[authentications objectAtIndex:i] containsObject:@"facebook"] ) {
                
                DLog(@"Shelby User has a Facebook account that's connected.");
                [user setValue:@YES forKey:kShelbyCoreDataUserFacebookConnected];
                
            }
            
            i++;
            
        }

    }
    
    BOOL admin = [[userDictionary valueForKey:@"admin"] boolValue];
    [user setValue:@(admin) forKey:kShelbyCoreDataUserAdmin];
    [[NSUserDefaults standardUserDefaults] setBool:admin forKey:kShelbyDefaultUserIsAdmin];
    
    [self saveContext:_context];

}

- (void)storeStream:(NSDictionary *)resultsDictionary
{
    NSArray *resultsArray = resultsDictionary[@"result"];
    
    for (NSUInteger i = 0; i < [resultsArray count]; ++i ) {
        
        @autoreleasepool {
            
            // Conditions for saving entires into database
            NSDictionary *frameDictionary = [resultsArray[i] valueForKey:@"frame"];
            BOOL frameExists = [frameDictionary isKindOfClass:([NSNull class])] ? NO : YES;
            
            if ( !frameExists ) {
                
                // Do nothing (e.g., don't store this frame in core data)
                
            } else {
                
                Stream *stream = [self checkIfEntity:kShelbyCoreDataEntityStream
                                         withIDValue:[resultsArray[i] valueForKey:@"id"]
                                            forIDKey:kShelbyCoreDataStreamID];
                
                NSString *streamID = [NSString coreDataNullTest:[resultsArray[i] valueForKey:@"id"]];
                [stream setValue:streamID forKey:kShelbyCoreDataStreamID];
                
                NSDate *timestamp = [NSDate dataFromBSONObjectID:streamID];
                [stream setValue:timestamp forKey:kShelbyCoreDataStreamTimestamp];
                
                Frame *frame = [self checkIfEntity:kShelbyCoreDataEntityFrame
                                       withIDValue:[frameDictionary valueForKey:@"id"]
                                          forIDKey:kShelbyCoreDataFrameID];
                stream.frame = frame;
                
                [self storeFrame:frame forDictionary:frameDictionary];
            }
        }
    }
    
    [self saveContext:_context];
    
}

- (void)storeCategories:(NSDictionary *)resultsDictionary
{
    NSArray *categoriesArray = resultsDictionary[@"result"];
    NSUInteger displayTag = 0;
    
    for ( NSUInteger i = 0; i < [categoriesArray count]; ++i ) {
        
        NSEnumerator *enumerator = [[categoriesArray objectAtIndex:i] keyEnumerator];
        NSEnumerator *reverseEnumerator = [[enumerator allObjects] reverseObjectEnumerator];
        
        for(NSString *key in reverseEnumerator) {
            
            if ( [key isEqualToString:@"rolls"] ) {
                
                // Parse and store rolls as CategoryRolls
                NSArray *rollsArray = [[categoriesArray objectAtIndex:i] valueForKey:@"rolls"];
                
                [self storeCategoryRolls:rollsArray withInitialTag:displayTag];
                
                // Set minimum tag for next itertation
                NSUInteger total = [rollsArray count];
                displayTag = displayTag + (total ? (total - 1) : 0);
                
            } else if ( [key isEqualToString:@"user_channels"] ) {
                
                // Parse and store user_channels as CategoryChannels
                NSArray *channelsArray = [[categoriesArray objectAtIndex:i] valueForKey:@"user_channels"];
                
                [self storeCategoryChannels:channelsArray withInitialTag:displayTag];
                
                // Set minimum tag for next itertation
                NSUInteger total = [channelsArray count];
                displayTag = displayTag + (total ? (total - 1) : 0);

                
            } else {
                
                // Do nothing
                
            }
            
        }
        
    }
    
    [self syncCategories:resultsDictionary];
}

- (void)storeRollFrames:(NSDictionary *)resultsDictionary forGroupType:(GroupType)groupType
{
    NSArray *resultsArray = [resultsDictionary[@"result"] valueForKey:@"frames"];
    
    for ( NSUInteger i = 0; i < [resultsArray count]; ++i ) {
        
        @autoreleasepool {
                            
            Frame *frame = [self checkIfEntity:kShelbyCoreDataEntityFrame
                                   withIDValue:[resultsArray[i] valueForKey:@"id"]
                                      forIDKey:kShelbyCoreDataFrameID];
            
            [self storeFrame:frame forDictionary:resultsArray[i]];

        }
    }
    
    if ( groupType == GroupType_Likes ) {
     
        [ShelbyAPIClient getLikesForSync];
        
    } else if ( groupType == GroupType_PersonalRoll) {
        
        [ShelbyAPIClient getPersonalRollForSync];
        
    } else { // The remaining type, CategoryRolls, is synced at the end of the storeCategories: method
        
        // Do nothing
    }
    
    [self saveContext:_context];
    
}

- (void)storeFrames:(NSDictionary *)resultsDictionary forCategoryChannel:(NSString *)channelID
{
    NSArray *resultsArray = resultsDictionary[@"result"];
    
    for ( NSUInteger i = 0; i < [resultsArray count]; ++i ) {
        
        @autoreleasepool {
            
            NSDictionary *frameDictionary = [resultsArray[i] valueForKey:@"frame"];
            
            Frame *frame = [self checkIfEntity:kShelbyCoreDataEntityFrame
                                   withIDValue:[frameDictionary valueForKey:@"id"]
                                      forIDKey:kShelbyCoreDataFrameID];
            
            frame.channelID = channelID;
            
            [self storeFrame:frame forDictionary:frameDictionary];
            
        }
    }
    
    [self saveContext:_context];
    
}

- (void)storeFrames:(NSDictionary *)resultsDictionary forCategoryRoll:(NSString *)rollID
{
    NSArray *resultsArray = [resultsDictionary[@"result"] valueForKey:@"frames"];
    
    for ( NSUInteger i = 0; i < [resultsArray count]; ++i ) {
        
        @autoreleasepool {
            
            Frame *frame = [self checkIfEntity:kShelbyCoreDataEntityFrame
                                   withIDValue:[resultsArray[i] valueForKey:@"id"]
                                      forIDKey:kShelbyCoreDataFrameID];
            
            frame.rollID = rollID;
            
            [self storeFrame:frame forDictionary:resultsArray[i]];
            
        }
    }
    
    [self saveContext:_context];
}

- (void)storeFrameInLoggedOutLikes:(Frame *)frame
{
    NSError *error = nil;
    frame = (Frame *)[self.context existingObjectWithID:[frame objectID] error:&error];
    frame.isStoredForLoggedOutUser = @YES;
    [self saveContext:_context];
}

#pragma mark - Fetch Methods (Public)
- (User *)fetchUser
{
    // Create fetch request
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setReturnsObjectsAsFaults:NO];
    
    // Search User table
    NSEntityDescription *description = [NSEntityDescription entityForName:kShelbyCoreDataEntityUser inManagedObjectContext:_context];
    [request setEntity:description];
    
    // Execute request that returns array of Users
    NSArray *resultsArray = [self.context executeFetchRequest:request error:nil];
    
    return resultsArray[0];
}

- (NSUInteger)fetchStreamCount
{
    // Create fetch request
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setReturnsObjectsAsFaults:NO];
    
    // Search Stream table
    NSEntityDescription *description = [NSEntityDescription entityForName:kShelbyCoreDataEntityStream inManagedObjectContext:_context];
    [request setEntity:description];
    
    // Execute request that returns array of Stream entries
    NSArray *streamEntries = [self.context executeFetchRequest:request error:nil];
    
    return [streamEntries count];
}

- (NSUInteger)fetchLikesCount
{
    // Create fetch request
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setReturnsObjectsAsFaults:NO];
    
    // Search Likes table
    NSEntityDescription *description = [NSEntityDescription entityForName:kShelbyCoreDataEntityFrame inManagedObjectContext:_context];
    [request setEntity:description];
    
    // Filter by rollID
    User *user = [self fetchUser];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"rollID == %@", [user likesRollID]];
    [request setPredicate:predicate];
    
    // Execute request that returns array of frames
    NSArray *frameResults = [self.context executeFetchRequest:request error:nil];
    
    return [frameResults count];
}

- (NSUInteger)fetchPersonalRollCount
{
    // Create fetch request
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setReturnsObjectsAsFaults:NO];
    
    // Search Personal Roll table
    NSEntityDescription *description = [NSEntityDescription entityForName:kShelbyCoreDataEntityFrame inManagedObjectContext:_context];
    [request setEntity:description];
    
    // Filter by rollID
    User *user = [self fetchUser];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"rollID == %@", [user personalRollID]];
    [request setPredicate:predicate];
    
    // Execute request that returns array of frames
    NSArray *frameResults = [self.context executeFetchRequest:request error:nil];
    
    return [frameResults count];
}

- (NSUInteger)fetchCountForCategoryChannel:(NSString *)channelID
{
    // Create fetch request
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setReturnsObjectsAsFaults:NO];
    
    // Search Frame table
    NSEntityDescription *description = [NSEntityDescription entityForName:kShelbyCoreDataEntityFrame inManagedObjectContext:_context];
    [request setEntity:description];
    
    // Filter by rollID
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"channelID == %@", channelID];
    [request setPredicate:predicate];
    
    // Execute request that returns array of frames
    NSArray *frameResults = [self.context executeFetchRequest:request error:nil];
    
    return [frameResults count];
}

- (NSUInteger)fetchCountForCategoryRoll:(NSString *)rollID
{
    // Create fetch request
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setReturnsObjectsAsFaults:NO];
    
    // Search Frame table
    NSEntityDescription *description = [NSEntityDescription entityForName:kShelbyCoreDataEntityFrame inManagedObjectContext:_context];
    [request setEntity:description];
    
    // Filter by rollID
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"rollID == %@", rollID];
    [request setPredicate:predicate];
    
    // Execute request that returns array of frames
    NSArray *frameResults = [self.context executeFetchRequest:request error:nil];
    
    return [frameResults count];
}

- (NSMutableArray *)fetchStreamEntries
{
    
    // Create fetch request
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setReturnsObjectsAsFaults:NO];
    
    // Search Stream table
    NSEntityDescription *description = [NSEntityDescription entityForName:kShelbyCoreDataEntityStream inManagedObjectContext:_context];
    [request setEntity:description];
    
    // Sort by timestamp
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:NO];
    [request setSortDescriptors:@[sortDescriptor]];
    
    // Execute request that returns array of Stream entries
    NSArray *requestResults = [self.context executeFetchRequest:request error:nil];
    
    // Filter Playable Results (YouTube, Vimeo, DailyMotion)
    NSMutableArray *playableFrames = [self filterPlayableStreamFrames:requestResults];
    
    // Remove Frames that link to the same Video object
    NSMutableArray *deduplicatedFrames = [self removeDuplicateFrames:playableFrames];
    
    // If SecretMode_OfflineView is enabled, return only videos that have been downloaded, otherwise return deduplicated frames
    BOOL offlineViewModeEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:kShelbyDefaultOfflineViewModeEnabled];
    
    return ( offlineViewModeEnabled ) ? [self filterDownloadedFrames:deduplicatedFrames] : deduplicatedFrames;
}

- (NSMutableArray *)fetchMoreStreamEntriesAfterDate:(NSDate *)date
{
    
    // Create fetch request
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setReturnsObjectsAsFaults:NO];
    
    // Search Stream table
    NSEntityDescription *description = [NSEntityDescription entityForName:kShelbyCoreDataEntityStream inManagedObjectContext:_context];
    [request setEntity:description];
    
    // Sort by timestamp
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:NO];
    [request setSortDescriptors:@[sortDescriptor]];
    
    // Filter by timestamp
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"timestamp < %@", date];
    [request setPredicate:predicate];
    
    // Execute request that returns array of Stream entries
    NSArray *requestResults = [self.context executeFetchRequest:request error:nil];
    
    // Filter Playable Results (YouTube, Vimeo, DailyMotion)
    NSMutableArray *playableFrames = [self filterPlayableStreamFrames:requestResults];
    
    // Remove Frames that link to the same Video object
    NSMutableArray *deduplicatedFrames = [self removeDuplicateFrames:playableFrames];
    
    // If SecretMode_OfflineView is enabled, return only videos that have been downloaded, otherwise return deduplicated frames
    BOOL offlineViewModeEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:kShelbyDefaultOfflineViewModeEnabled];
    
    return ( offlineViewModeEnabled ) ? [self filterDownloadedFrames:deduplicatedFrames] : deduplicatedFrames;
}

- (NSMutableArray *)fetchLikesEntries
{
    
    // Create fetch request
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setReturnsObjectsAsFaults:NO];
    
    // Search Frame table
    NSEntityDescription *description = [NSEntityDescription entityForName:kShelbyCoreDataEntityFrame inManagedObjectContext:_context];
    [request setEntity:description];
    
    // Sort by timestamp
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:NO];
    [request setSortDescriptors:@[sortDescriptor]];
    
    // Filter by rollID
    if ( [[NSUserDefaults standardUserDefaults] boolForKey:kShelbyDefaultUserAuthorized] ) {
        
        User *user = [self fetchUser];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"rollID == %@", [user likesRollID]];
        [request setPredicate:predicate];
        
    } else {
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isStoredForLoggedOutUser == %d", YES];
        [request setPredicate:predicate];
        
    }
    
    // Execute request that returns array of frames in Queue Roll
    NSArray *requestResults = [NSMutableArray arrayWithArray:[self.context executeFetchRequest:request error:nil]];
    
    // Filter Playable Results (YouTube, Vimeo, DailyMotion)
    NSMutableArray *playableFrames = [self filterPlayableFrames:requestResults];
    
    // Remove Frames that link to the same Video object
    NSMutableArray *deduplicatedFrames = [self removeDuplicateFrames:playableFrames];
    
    // If SecretMode_OfflineView is enabled, return only videos that have been downloaded, otherwise return deduplicated frames
    BOOL offlineViewModeEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:kShelbyDefaultOfflineViewModeEnabled];
    
    return ( offlineViewModeEnabled ) ? [self filterDownloadedFrames:deduplicatedFrames] : deduplicatedFrames;
}

- (NSMutableArray *)fetchMoreLikesEntriesAfterDate:(NSDate *)date
{
    
    // Create fetch request
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setReturnsObjectsAsFaults:NO];
    
    // Search Frame table
    NSEntityDescription *description = [NSEntityDescription entityForName:kShelbyCoreDataEntityFrame inManagedObjectContext:_context];
    [request setEntity:description];
    
    // Sort by timestamp
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:NO];
    [request setSortDescriptors:@[sortDescriptor]];
    
    // Filter by rollID and timestamp
    if ( [[NSUserDefaults standardUserDefaults] boolForKey:kShelbyDefaultUserAuthorized] ) {
        
        User *user = [self fetchUser];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"rollID == %@ AND (timestamp < %@)", [user likesRollID], date];
        [request setPredicate:predicate];
        
    } else {
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isStoredForLoggedOutUser == %d AND (timestamp < %@)", YES, date];
        [request setPredicate:predicate];
        
    }
    
    // Execute request that returns array of frames in Queue Roll
    NSArray *requestResults = [NSMutableArray arrayWithArray:[self.context executeFetchRequest:request error:nil]];
    
    // Filter Playable Results (YouTube, Vimeo, DailyMotion)
    NSMutableArray *playableFrames = [self filterPlayableFrames:requestResults];
    
    // Remove Frames that link to the same Video object
    NSMutableArray *deduplicatedFrames = [self removeDuplicateFrames:playableFrames];
    
    // If SecretMode_OfflineView is enabled, return only videos that have been downloaded, otherwise return deduplicated frames
    BOOL offlineViewModeEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:kShelbyDefaultOfflineViewModeEnabled];
    
    return ( offlineViewModeEnabled ) ? [self filterDownloadedFrames:deduplicatedFrames] : deduplicatedFrames;
}

- (NSMutableArray *)fetchPersonalRollEntries
{
    
    // Create fetch request
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setReturnsObjectsAsFaults:NO];
    
    // Search Frame table
    NSEntityDescription *description = [NSEntityDescription entityForName:kShelbyCoreDataEntityFrame inManagedObjectContext:_context];
    [request setEntity:description];
    
    // Sort by timestamp
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:NO];
    [request setSortDescriptors:@[sortDescriptor]];
    
    // Filter by rollID
    User *user = [self fetchUser];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"rollID == %@", [user personalRollID]];
    [request setPredicate:predicate];
    
    // Execute request that returns array of frames in Personal Roll
    NSArray *requestResults = [NSMutableArray arrayWithArray:[self.context executeFetchRequest:request error:nil]];
    
    // Filter Playable Results (YouTube, Vimeo, DailyMotion)
    NSMutableArray *playableFrames = [self filterPlayableFrames:requestResults];
    
    // Remove Frames that link to the same Video object
    NSMutableArray *deduplicatedFrames = [self removeDuplicateFrames:playableFrames];
    
    // If SecretMode_OfflineView is enabled, return only videos that have been downloaded, otherwise return deduplicated frames
    BOOL offlineViewModeEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:kShelbyDefaultOfflineViewModeEnabled];
    
    return ( offlineViewModeEnabled ) ? [self filterDownloadedFrames:deduplicatedFrames] : deduplicatedFrames;
}

- (NSMutableArray *)fetchMorePersonalRollEntriesAfterDate:(NSDate *)date
{
    
    // Create fetch request
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setReturnsObjectsAsFaults:NO];
    
    // Search Frame table
    NSEntityDescription *description = [NSEntityDescription entityForName:kShelbyCoreDataEntityFrame inManagedObjectContext:_context];
    [request setEntity:description];
    
    // Sort by timestamp
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:NO];
    [request setSortDescriptors:@[sortDescriptor]];
    // Set Predicate
    
    // Filter by rollID and timestamp
    User *user = [self fetchUser];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"((rollID == %@) AND (timestamp < %@))", [user personalRollID], date];
    [request setPredicate:predicate];
    
    // Execute request that returns array of frames in Personal Roll
    NSArray *requestResults = [NSMutableArray arrayWithArray:[self.context executeFetchRequest:request error:nil]];

    // Filter Playable Results (YouTube, Vimeo, DailyMotion)
    NSMutableArray *playableFrames = [self filterPlayableFrames:requestResults];
    
    // Remove Frames that link to the same Video object
    NSMutableArray *deduplicatedFrames = [self removeDuplicateFrames:playableFrames];
    
    // If SecretMode_OfflineView is enabled, return only videos that have been downloaded, otherwise return deduplicated frames
    BOOL offlineViewModeEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:kShelbyDefaultOfflineViewModeEnabled];
    
    return ( offlineViewModeEnabled ) ? [self filterDownloadedFrames:deduplicatedFrames] : deduplicatedFrames;
}

- (NSMutableArray *)fetchFramesInCategoryChannel:(NSString *)channelID
{
    // Create fetch request
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setReturnsObjectsAsFaults:NO];
    
    // Search Frame table
    NSEntityDescription *description = [NSEntityDescription entityForName:kShelbyCoreDataEntityFrame inManagedObjectContext:_context];
    [request setEntity:description];
    
    // Sort by timestamp
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:NO];
    [request setSortDescriptors:@[sortDescriptor]];
    
    // Filter by rollID
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"channelID == %@", channelID];
    [request setPredicate:predicate];
    
    // Execute request that returns array of frames in Queue Roll
    NSArray *requestResults = [NSMutableArray arrayWithArray:[self.context executeFetchRequest:request error:nil]];
    
    // Filter Playable Results (YouTube, Vimeo, DailyMotion)
    NSMutableArray *playableFrames = [self filterPlayableFrames:requestResults];
    
    // Remove Frames that link to the same Video object
    NSMutableArray *deduplicatedFrames = [self removeDuplicateFrames:playableFrames];
    
    // If SecretMode_OfflineView is enabled, return only videos that have been downloaded, otherwise return deduplicated frames
    BOOL offlineViewModeEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:kShelbyDefaultOfflineViewModeEnabled];
    
    return ( offlineViewModeEnabled ) ? [self filterDownloadedFrames:deduplicatedFrames] : deduplicatedFrames;
}

- (NSMutableArray *)fetchMoreFramesInCategoryChannel:(NSString *)channelID afterDate:(NSDate *)date
{
    // Create fetch request
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setReturnsObjectsAsFaults:NO];
    
    // Search Frame table
    NSEntityDescription *description = [NSEntityDescription entityForName:kShelbyCoreDataEntityFrame inManagedObjectContext:_context];
    [request setEntity:description];
    
    // Sort by timestamp
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:NO];
    [request setSortDescriptors:@[sortDescriptor]];
    // Set Predicate
    
    // Filter by rollID and timestamp
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"((channelID == %@) AND (timestamp < %@))", channelID, date];
    [request setPredicate:predicate];
    
    // Execute request that returns array of frames in Personal Roll
    NSArray *requestResults = [NSMutableArray arrayWithArray:[self.context executeFetchRequest:request error:nil]];
    
    // Filter Playable Results (YouTube, Vimeo, DailyMotion)
    NSMutableArray *playableFrames = [self filterPlayableFrames:requestResults];
    
    // Remove Frames that link to the same Video object
    NSMutableArray *deduplicatedFrames = [self removeDuplicateFrames:playableFrames];
    
    // If SecretMode_OfflineView is enabled, return only videos that have been downloaded, otherwise return deduplicated frames
    BOOL offlineViewModeEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:kShelbyDefaultOfflineViewModeEnabled];
    
    return ( offlineViewModeEnabled ) ? [self filterDownloadedFrames:deduplicatedFrames] : deduplicatedFrames;
}

- (NSMutableArray *)fetchFramesInCategoryRoll:(NSString *)rollID
{
    // Create fetch request
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setReturnsObjectsAsFaults:NO];
    
    // Search Frame table
    NSEntityDescription *description = [NSEntityDescription entityForName:kShelbyCoreDataEntityFrame inManagedObjectContext:_context];
    [request setEntity:description];
    
    // Sort by timestamp
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:NO];
    [request setSortDescriptors:@[sortDescriptor]];
    
    // Filter by rollID
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"rollID == %@", rollID];
    [request setPredicate:predicate];
    
    // Execute request that returns array of frames in Queue Roll
    NSArray *requestResults = [NSMutableArray arrayWithArray:[self.context executeFetchRequest:request error:nil]];
    
    // Filter Playable Results (YouTube, Vimeo, DailyMotion)
    NSMutableArray *playableFrames = [self filterPlayableFrames:requestResults];
    
    // Remove Frames that link to the same Video object
    NSMutableArray *deduplicatedFrames = [self removeDuplicateFrames:playableFrames];
    
    // If SecretMode_OfflineView is enabled, return only videos that have been downloaded, otherwise return deduplicated frames
    BOOL offlineViewModeEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:kShelbyDefaultOfflineViewModeEnabled];
    
    return ( offlineViewModeEnabled ) ? [self filterDownloadedFrames:deduplicatedFrames] : deduplicatedFrames;
}

- (NSMutableArray *)fetchMoreFramesInCategoryRoll:(NSString *)rollID afterDate:(NSDate *)date
{
    // Create fetch request
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setReturnsObjectsAsFaults:NO];
    
    // Search Frame table
    NSEntityDescription *description = [NSEntityDescription entityForName:kShelbyCoreDataEntityFrame inManagedObjectContext:_context];
    [request setEntity:description];
    
    // Sort by timestamp
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:NO];
    [request setSortDescriptors:@[sortDescriptor]];
    // Set Predicate
    
    // Filter by rollID and timestamp
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"((rollID == %@) AND (timestamp < %@))", rollID, date];
    [request setPredicate:predicate];
    
    // Execute request that returns array of frames in Personal Roll
    NSArray *requestResults = [NSMutableArray arrayWithArray:[self.context executeFetchRequest:request error:nil]];
    
    // Filter Playable Results (YouTube, Vimeo, DailyMotion)
    NSMutableArray *playableFrames = [self filterPlayableFrames:requestResults];
    
    // Remove Frames that link to the same Video object
    NSMutableArray *deduplicatedFrames = [self removeDuplicateFrames:playableFrames];
    
    // If SecretMode_OfflineView is enabled, return only videos that have been downloaded, otherwise return deduplicated frames
    BOOL offlineViewModeEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:kShelbyDefaultOfflineViewModeEnabled];
    
    return ( offlineViewModeEnabled ) ? [self filterDownloadedFrames:deduplicatedFrames] : deduplicatedFrames;
}

- (NSString *)fetchTextFromFirstMessageInConversation:(Conversation *)conversation
{

    // Create fetch request
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setReturnsObjectsAsFaults:NO];
    
    // Fetch messages data
    NSEntityDescription *description = [NSEntityDescription entityForName:kShelbyCoreDataEntityMessages inManagedObjectContext:_context];
    [request setEntity:description];
    
    // Only include messages that belong to this specific conversation
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"conversationID == %@", conversation.conversationID];
    [request setPredicate:predicate];
    
    // Sort by timestamp
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:NO];
    [request setSortDescriptors:@[sortDescriptor]];
    
    // Execute request that returns array of dashboardEntrys
    NSArray *messagesArray = [self.context executeFetchRequest:request error:nil];
    
    NSString *messageText;
    
    if ( [messagesArray count] ) {
        
        Messages *message = (Messages *) messagesArray[0];
        messageText = message.text;
    }

    
    return messageText.length ? messageText : @"No information available";
}

- (NSMutableArray *)fetchAllCategories
{
    
    /// First, fetch all Channel objects ///
    
    // Create channel fetch request
    NSFetchRequest *channelsRequest = [[NSFetchRequest alloc] init];
    [channelsRequest setReturnsObjectsAsFaults:NO];
    
    // Fetch channels data
    NSEntityDescription *channelsDescription = [NSEntityDescription entityForName:kShelbyCoreDataEntityChannel inManagedObjectContext:_context];
    [channelsRequest setEntity:channelsDescription];
    
    // Sort by channelID
    NSSortDescriptor *channelSortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"channelID" ascending:NO];
    [channelsRequest setSortDescriptors:@[channelSortDescriptor]];
    
    // Execute request that returns array of channels
    NSArray *channelsArray = [self.context executeFetchRequest:channelsRequest error:nil];
    
    /// Second, fetch all Rolls objects with isCategory == YES ///
    
    // Create roll fetch request
    NSFetchRequest *rollRequest = [[NSFetchRequest alloc] init];
    [rollRequest setReturnsObjectsAsFaults:NO];
    
    // Fetch roll data
    NSEntityDescription *rollsDescription = [NSEntityDescription entityForName:kShelbyCoreDataEntityRoll inManagedObjectContext:_context];
    [rollRequest setEntity:rollsDescription];
    
    // Only include rolls that have isCategory == YES
    NSPredicate *rollPredicate = [NSPredicate predicateWithFormat:@"isCategory == %d", YES];
    [rollRequest setPredicate:rollPredicate];
    
    // Sort by channelID
    NSSortDescriptor *rollSortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"rollID" ascending:NO];
    [rollRequest setSortDescriptors:@[rollSortDescriptor]];
    
    // Execute request that returns array of channels
    NSArray *rollsArray = [self.context executeFetchRequest:rollRequest error:nil];
    
    /// Finally, add channelsArray and rollsArray to NSMutableArray object, and return said object
    
    NSMutableArray *categoriesArray = [[NSMutableArray alloc] init];
    [categoriesArray addObjectsFromArray:channelsArray];
    [categoriesArray addObjectsFromArray:rollsArray];
    
    NSSortDescriptor *displayTagSortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"displayTag" ascending:YES];
    [categoriesArray sortUsingDescriptors:[NSArray arrayWithObject:displayTagSortDescriptor]];

    return categoriesArray;
    
}

#pragma mark - Sync Methods (Public)
- (void)syncLoggedOutLikes
{
    // Create fetch request
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setReturnsObjectsAsFaults:NO];
    
    // Search Frame table
    NSEntityDescription *description = [NSEntityDescription entityForName:kShelbyCoreDataEntityFrame inManagedObjectContext:_context];
    [request setEntity:description];
    
    // Sort by timestamp
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:NO];
    [request setSortDescriptors:@[sortDescriptor]];
    
    // Filter by offline frames
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isStoredForLoggedOutUser == %d", YES];
    [request setPredicate:predicate];
    
    // Execute request that returns array of frames in Likes Roll
    NSArray *requestResults = [NSMutableArray arrayWithArray:[self.context executeFetchRequest:request error:nil]];

    for ( Frame *frame in requestResults ) {
        
        [ShelbyAPIClient postFrameToLikes:frame.frameID];
        [frame setIsStoredForLoggedOutUser:NO];
        
    }
    
    [self saveContext:_context];
}

- (void)syncLikes:(NSDictionary *)webResultsDictionary
{
    // Create fetch request
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setReturnsObjectsAsFaults:NO];
    
    // Search Queue table
    NSEntityDescription *description = [NSEntityDescription entityForName:kShelbyCoreDataEntityFrame inManagedObjectContext:_context];
    [request setEntity:description];
    
    // Filter by rollID
    User *user = [self fetchUser];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"rollID == %@", [user likesRollID]];
    [request setPredicate:predicate];
    
    // Execute request that returns array of frames
    NSArray *frameResults = [self.context executeFetchRequest:request error:nil];

    // Extract frameIDs from results from Shelby's Web Database
    NSArray *webResultsArray = [webResultsDictionary[@"result"] valueForKey:@"frames"];
    NSMutableArray *webFrameIdentifiersInLikes = [@[] mutableCopy];
    for (NSUInteger i = 0; i < [webResultsArray count]; ++i) {
        
        NSString *frameID = [webResultsArray[i] valueForKey:@"id"];
        [webFrameIdentifiersInLikes addObject:frameID];
    }

    // Perform Core Data vs. Shelby Database comparison and remove objects that don't exist
    for ( NSUInteger i = 0; i < [frameResults count]; ++i ) {
        
        Frame *frame = (Frame *)frameResults[i];
        NSString *frameID = frame.frameID;
        
        // Delete object if it doesn't exist on web any more
        if ( ![webFrameIdentifiersInLikes containsObject:frameID] ) {
        
            DLog(@"Likes FrameID no longer exist on web, so it is being removed: %@", frameID);
            
            [self.context deleteObject:frame];
        }
    }
    
    [self saveContext:_context];
}

- (void)syncPersonalRoll:(NSDictionary *)webResultsDictionary
{
    // Create fetch request
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setReturnsObjectsAsFaults:NO];
    
    // Search Personal Roll table
    NSEntityDescription *description = [NSEntityDescription entityForName:kShelbyCoreDataEntityFrame inManagedObjectContext:_context];
    [request setEntity:description];
    
    // Filter by rollID
    User *user = [self fetchUser];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"rollID == %@", [user personalRollID]];
    [request setPredicate:predicate];
    
    // Execute request that returns array of frames
    NSArray *frameResults = [self.context executeFetchRequest:request error:nil];
    
    // Extract frameIDs from results from Shelby's Web Database
    NSArray *webResultsArray = [webResultsDictionary[@"result"] valueForKey:@"frames"];
    NSMutableArray *webFrameIdentifiersInPersonalRoll = [@[] mutableCopy];
    for (NSUInteger i = 0; i < [webResultsArray count]; ++i) {
        
        NSString *frameID = [webResultsArray[i] valueForKey:@"id"];
        [webFrameIdentifiersInPersonalRoll addObject:frameID];
    }
    
    // Perform Core Data vs. Shelby Database comparison and remove objects that don't exist
    for ( NSUInteger i = 0; i < [frameResults count]; ++i ) {
        
        Frame *frame = (Frame *)frameResults[i];
        NSString *frameID = frame.frameID;
        
        // Delete object if it doesn't exist on web any more
        if ( ![webFrameIdentifiersInPersonalRoll containsObject:frameID] ) {
            
            DLog(@"Personal Roll FrameID no longer exist on web, so it is being removed: %@", frameID);
            
            [self.context deleteObject:frame];
        }
    }
    
    [self saveContext:_context];
}

#pragma mark - Persistance Methods (Private)
- (id)checkIfEntity:(NSString *)entityName
        withIDValue:(NSString *)entityIDValue
           forIDKey:(NSString *)entityIDKey
{
    
    ///* This is the Find-or-Create method for all Core Data objects in the application *///
    
    // Create fetch request
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setReturnsObjectsAsFaults:NO];
    
    NSEntityDescription *description = [NSEntityDescription entityForName:entityName inManagedObjectContext:_context];
    [request setEntity:description];
    
    // Only include objects that exist (i.e. entityIDKey and entityIDValue's must exist)
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", entityIDKey, entityIDValue];
    [request setPredicate:predicate];
    
    // Execute request that returns array with one object, the requested entity
    NSArray *array = [self.context executeFetchRequest:request error:nil];
    
    if ( [array count] ) {
        return array[0];
    }
    
    return [NSEntityDescription insertNewObjectForEntityForName:entityName inManagedObjectContext:_context];
}

- (void)deleteFrame:(Frame *)frame
{
    frame = (Frame* )[self.context existingObjectWithID:[frame objectID] error:nil];
    
    if ( ![frame isStoredForLoggedOutUser] ) {
     
        [self.context deleteObject:frame];
        [self saveContext:_context];
    }
}

- (void)removeOlderVideoFramesFromStream
{
    // Create fetch request
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setReturnsObjectsAsFaults:NO];
    
    NSEntityDescription *description = [NSEntityDescription entityForName:kShelbyCoreDataEntityStream inManagedObjectContext:_context];
    [request setEntity:description];
    
    // Sort by timestamp
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:NO];
    [request setSortDescriptors:@[sortDescriptor]];
    
    // Execute request that returns array of Stream entries}
    NSArray *results = [self.context executeFetchRequest:request error:nil];
    
    NSUInteger maxLimit = 60;
    
    // Remove older videos from data store
    if ( [results count] > maxLimit ) {
        
        NSMutableArray *olderResults = [results mutableCopy];
        NSUInteger i = [results count];
        
        while ( i > maxLimit ) {
            
            Stream *streamEntry = (Stream*)[olderResults lastObject];
            [self.context deleteObject:streamEntry];
            [olderResults removeLastObject];
            
            i--;
        }
        
        [self saveContext:_context];
        
    }

}

- (void)removeOlderVideoFramesFromLikes
{
    
    // Create fetch request
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setReturnsObjectsAsFaults:NO];
    
    // Search Likes table
    NSEntityDescription *description = [NSEntityDescription entityForName:kShelbyCoreDataEntityFrame inManagedObjectContext:_context];
    [request setEntity:description];
    
    // Filter by rollID
    User *user = [self fetchUser];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"rollID == %@", [user likesRollID]];
    [request setPredicate:predicate];
    
    // Execute request that returns array of frames
    NSArray *results = [self.context executeFetchRequest:request error:nil];
    
    NSUInteger maxLimit = 60;
    
    // Remove older videos from data store
    if ( [results count] > maxLimit ) {
        
        NSMutableArray *olderResults = [results mutableCopy];
        NSUInteger i = [results count];
        
        while ( i > maxLimit ) {
            
            Frame *frame = (Frame*)[olderResults lastObject];
            [self.context deleteObject:frame];
            [olderResults removeLastObject];
            
            i--;
        }

        [self saveContext:_context];
        
    }
}

- (void)removeOlderVideoFramesFromPersonalRoll
{
    // Create fetch request
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setReturnsObjectsAsFaults:NO];
    
    // Search Personal Roll table
    NSEntityDescription *description = [NSEntityDescription entityForName:kShelbyCoreDataEntityFrame inManagedObjectContext:_context];
    [request setEntity:description];
    
    // Filter by rollID
    User *user = [self fetchUser];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"rollID == %@", [user personalRollID]];
    [request setPredicate:predicate];
    
    // Execute request that returns array of frames
    NSArray *results = [self.context executeFetchRequest:request error:nil];
    
    NSUInteger maxLimit = 60;
    
    // Remove older videos from data store
    if ( [results count] > maxLimit ) {
        
        NSMutableArray *olderResults = [results mutableCopy];
        NSUInteger i = [results count];
        
        while ( i > maxLimit ) {
            
            Frame *frame = (Frame*)[olderResults lastObject];
            [self.context deleteObject:frame];
            [olderResults removeLastObject];
            
            i--;
        }
        
        [self saveContext:_context];
        
    }
}

- (void)removeOlderVideoFramesFromCategoryChannel:(NSString *)channelID
{
    // Create fetch request
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setReturnsObjectsAsFaults:NO];
    
    // Search CategoryChannels table
    NSEntityDescription *description = [NSEntityDescription entityForName:kShelbyCoreDataEntityFrame inManagedObjectContext:_context];
    [request setEntity:description];
    
    // Filter by channelID
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"channelID == %@", channelID];
    [request setPredicate:predicate];
    
    // Execute request that returns array of frames
    NSArray *results = [self.context executeFetchRequest:request error:nil];
    
    NSUInteger maxLimit = 60;
    
    // Remove older videos from data store
    if ( [results count] > maxLimit ) {
        
        NSMutableArray *olderResults = [results mutableCopy];
        NSUInteger i = [results count];
        
        while ( i > maxLimit ) {
            
            Frame *frame = (Frame*)[olderResults lastObject];
            [self deleteFrame:frame];
            [olderResults removeLastObject];
            
            i--;
        }
        
        [self saveContext:_context];
        
    }
}

- (void)removeOlderVideoFramesFromCategoryRoll:(NSString *)rollID
{
    // Create fetch request
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setReturnsObjectsAsFaults:NO];
    
    // Search CategoryRolls table
    NSEntityDescription *description = [NSEntityDescription entityForName:kShelbyCoreDataEntityFrame inManagedObjectContext:_context];
    [request setEntity:description];
    
    // Filter by channelID
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"rollID == %@", rollID];
    [request setPredicate:predicate];
    
    // Execute request that returns array of frames
    NSArray *results = [self.context executeFetchRequest:request error:nil];
    
    NSUInteger maxLimit = 60;
    
    // Remove older videos from data store
    if ( [results count] > maxLimit ) {
        
        NSMutableArray *olderResults = [results mutableCopy];
        NSUInteger i = [results count];
        
        while ( i > maxLimit ) {
            
            Frame *frame = (Frame*)[olderResults lastObject];
            [self deleteFrame:frame];
            [olderResults removeLastObject];
            
            i--;
        }
        
        [self saveContext:_context];
        
    }
}

#pragma mark - Storage Methods (Private) 
- (void)storeCategoryRolls:(NSArray *)rollsArray withInitialTag:(NSUInteger)displayTag
{
    
    for ( NSUInteger i = 0; i < [rollsArray count]; ++i ) {
        
        NSDictionary *rollDictionary = [rollsArray objectAtIndex:i];
        
        if ( rollDictionary ) {
            
            Roll *roll = [self checkIfEntity:kShelbyCoreDataEntityRoll
                                 withIDValue:[rollDictionary valueForKey:@"id"]
                                    forIDKey:kShelbyCoreDataRollID];
            
            NSString *rollID = [NSString coreDataNullTest:[rollDictionary valueForKey:@"id"]];
            [roll setValue:rollID forKey:kShelbyCoreDataRollID];
            
            [roll setValue:@YES forKey:kShelbyCoreDataRollIsCategory];
            
            [roll setValue:[NSNumber numberWithInt:(displayTag+i)] forKey:kShelbyCoreDataRollDisplayTag];
            
            NSString *displayTitle = [NSString coreDataNullTest:[rollDictionary valueForKey:@"display_title"]];
            [roll setValue:displayTitle forKey:kShelbyCoreDataRollDisplayTitle];
            
            NSString *displayDescription = [NSString coreDataNullTest:[rollDictionary valueForKey:@"display_description"]];
            [roll setValue:displayDescription forKey:kShelbyCoreDataRollDisplayDescription];
            
            NSString *displayThumbnail = [NSString coreDataNullTest:[rollDictionary valueForKey:@"display_thumbnail_ipad_src"]];
            displayThumbnail = [NSString stringWithFormat: @"http://shelby.tv%@", displayThumbnail];
            [roll setValue:displayThumbnail forKey:kShelbyCoreDataRollDisplayThumbnailURL];
            
            [ShelbyAPIClient getCategoryRoll:rollID];
            
        }
    }
}

- (void)storeCategoryChannels:(NSArray *)channelsArray withInitialTag:(NSUInteger)displayTag
{
    for ( NSUInteger i = 0; i < [channelsArray count]; ++i ) {
        
        NSDictionary *channelDictionary = [channelsArray objectAtIndex:i];
        
        if ( channelDictionary ) {
            
            Channel *channel = [self checkIfEntity:kShelbyCoreDataEntityChannel
                                       withIDValue:[channelDictionary valueForKey:@"user_id"]
                                          forIDKey:kShelbyCoreDataChannelID];
            
            NSString *channelID = [NSString coreDataNullTest:[channelDictionary valueForKey:@"user_id"]];
            [channel setValue:channelID forKey:kShelbyCoreDataChannelID];
            
            [channel setValue:[NSNumber numberWithInt:(displayTag+i)] forKey:kShelbyCoreDataRollDisplayTag];
            
            NSString *displayTitle = [NSString coreDataNullTest:[channelDictionary valueForKey:@"display_title"]];
            [channel setValue:displayTitle forKey:kShelbyCoreDataChannelDisplayTitle];
            
            NSString *displayDescription = [NSString coreDataNullTest:[channelDictionary valueForKey:@"display_description"]];
            [channel setValue:displayDescription forKey:kShelbyCoreDataChannelDisplayDescription];
            
            NSString *displayThumbnail = [NSString coreDataNullTest:[channelDictionary valueForKey:@"display_thumbnail_ipad_src"]];
            displayThumbnail = [NSString stringWithFormat:@"http://shelby.tv%@", displayThumbnail];
            [channel setValue:displayThumbnail forKey:kShelbyCoreDataChannelDisplayThumbnailURL];
            
            [ShelbyAPIClient getCategoryChannel:channelID];
            
        }
        
    }
    
}

- (void)storeFrame:(Frame *)frame forDictionary:(NSDictionary *)frameDictionary
{
        
    NSString *frameID = [NSString coreDataNullTest:[frameDictionary valueForKey:@"id"]];
    [frame setValue:frameID forKey:kShelbyCoreDataFrameID];
    
    NSString *conversationID = [NSString coreDataNullTest:[frameDictionary valueForKey:@"conversation_id"]];
    [frame setValue:conversationID forKey:kShelbyCoreDataFrameConversationID];
    
    NSString *createdAt = [NSString coreDataNullTest:[frameDictionary valueForKey:@"created_at"]];
    [frame setValue:createdAt forKey:kShelbyCoreDataFrameCreatedAt];
    
    NSString *creatorID = [NSString coreDataNullTest:[frameDictionary valueForKey:@"creator_id"]];
    [frame setValue:creatorID forKey:kShelbyCoreDataFrameCreatorID];
    
    [frame setValue:@NO forKey:kShelbyCoreDataFrameIsStoredForLoggedOutUser];
    
    NSString *rollID = [NSString coreDataNullTest:[frameDictionary valueForKey:@"roll_id"]];
    [frame setValue:rollID forKey:kShelbyCoreDataFrameRollID];
    
    NSDate *timestamp = [NSDate dataFromBSONObjectID:frameID];
    [frame setValue:timestamp forKey:kShelbyCoreDataFrameTimestamp];
    
    NSString *videoID = [NSString coreDataNullTest:[frameDictionary valueForKey:@"video_id"]];
    [frame setValue:videoID forKey:kShelbyCoreDataFrameVideoID];
    
    // Store Conversation (and Messages)
    Conversation *conversation = [self checkIfEntity:kShelbyCoreDataEntityConversation
                                         withIDValue:conversationID
                                            forIDKey:kShelbyCoreDataFrameConversationID];
    
    if ( ![(id)conversation isEqual:[NSNull null]] ) {
        
        frame.conversation = conversation;
        conversation.frame = frame;
        [self storeConversation:conversation fromDictionary:[frameDictionary valueForKey:@"conversation"]];
        
    }
    
    // Store Creator
    Creator *creator = [self checkIfEntity:kShelbyCoreDataEntityCreator
                               withIDValue:creatorID
                                  forIDKey:kShelbyCoreDataFrameCreatorID];
    
    if ( ![(id)creator isEqual:[NSNull null]] ) {
    
        frame.creator = creator;
        [creator addFrameObject:frame];
        [self storeCreator:creator fromDictionary:[frameDictionary valueForKey:@"creator"]];
        
    }
    
    // Store Roll
    Roll *roll = [self checkIfEntity:kShelbyCoreDataEntityRoll
                         withIDValue:rollID
                            forIDKey:kShelbyCoreDataRollID];
    
    if ( ![(id)roll isEqual:[NSNull null]] ) {
    
        frame.roll = roll;
        roll.frame = frame;
        [self storeRoll:roll fromDictionary:[frameDictionary valueForKey:@"roll"]];
        
    }
    
    // Store Video
    Video *video = [self checkIfEntity:kShelbyCoreDataEntityVideo
                           withIDValue:videoID
                              forIDKey:kShelbyCoreDataFrameVideoID];
    
    if ( ![(id)video isEqual:[NSNull null]] ) {
    
        frame.video = video;
        [video addFrameObject:frame];
        [self storeVideo:video fromDictionary:[frameDictionary valueForKey:@"video"]];
        
    }
    
    
}

- (void)storeConversation:(Conversation *)conversation fromDictionary:(NSDictionary *)conversationDictionary
{
    
    NSString *conversationID = [NSString coreDataNullTest:[conversationDictionary valueForKey:@"id"]];
    [conversation setValue:conversationID forKey:kShelbyCoreDataConversationID];
    
    // Store Messages
    [self storeMessagesFromConversation:conversation withDictionary:conversationDictionary];
    
}

- (void)storeMessagesFromConversation:(Conversation *)conversation withDictionary:(NSDictionary *)conversationDictionary
{
    
    NSArray *messagesArray = [conversationDictionary valueForKey:@"messages"];

    if ( ![messagesArray isEqual:[NSNull null]] ) {
       
        [conversation setValue:[NSNumber numberWithInt:[messagesArray count]] forKey:kShelbyCoreDataConversationMessageCount];
        
        for ( NSUInteger i = 0; i < [messagesArray count]; ++i ) {
            
            Messages *messages = [self checkIfEntity:kShelbyCoreDataEntityMessages
                                         withIDValue:[messagesArray[i] valueForKey:@"id"]
                                            forIDKey:kShelbyCoreDataMessagesID];
            
            [conversation addMessagesObject:messages];
            
            // Hold reference to parent conversationID
            [messages setValue:conversation.conversationID forKey:kShelbyCoreDataConversationID];
            
            NSString *messageID = [NSString coreDataNullTest:[messagesArray[i] valueForKey:@"id"]];
            [messages setValue:messageID forKey:kShelbyCoreDataMessagesID];
            
            NSString *createdAt = [NSString coreDataNullTest:[messagesArray[i]  valueForKey:@"created_at"]];
            [messages setValue:createdAt forKey:kShelbyCoreDataMessagesCreatedAt];
            
            NSString *nickname = [NSString coreDataNullTest:[messagesArray[i]  valueForKey:@"nickname"]];
            [messages setValue:nickname forKey:kShelbyCoreDataMessagesNickname];
            
            NSString *originNetwork = [NSString coreDataNullTest:[messagesArray[i] valueForKey:@"origin_network"]];
            [messages setValue:originNetwork forKey:kShelbyCoreDataMessagesOriginNetwork];
            
            NSDate *timestamp = [NSDate dataFromBSONObjectID:messageID];
            [messages setValue:timestamp forKey:kShelbyCoreDataMessagesTimestamp];
            
            NSString *text = [NSString coreDataNullTest:[messagesArray[i]  valueForKey:@"text"]];
            [messages setValue:text forKey:kShelbyCoreDataMessagesText];
            
            NSString *userImage = [NSString coreDataNullTest:[messagesArray[i]  valueForKey:@"user_image_url"]];
            [messages setValue:userImage forKey:kShelbyCoreDataMessagesUserImage];
            
        }
    }
}

- (void)storeCreator:(Creator *)creator fromDictionary:(NSDictionary *)creatorDictionary
{
    
    NSString *creatorID = [NSString coreDataNullTest:[creatorDictionary valueForKey:@"id"]];
    [creator setValue:creatorID forKey:kShelbyCoreDataCreatorID];
    
    NSString *nickname = [NSString coreDataNullTest:[creatorDictionary valueForKey:@"nickname"]];
    [creator setValue:nickname forKey:kShelbyCoreDataCreatorNickname];
    
    NSString *userImage = [NSString coreDataNullTest:[creatorDictionary valueForKey:@"user_image"]];
    [creator setValue:userImage forKey:kShelbyCoreDataCreatorUserImage];
}

- (void)storeRoll:(Roll *)roll fromDictionary:(NSArray *)rollDictionary
{
    
    NSString *rollID = [NSString coreDataNullTest:[rollDictionary valueForKey:@"id"]];
    [roll setValue:rollID forKey:kShelbyCoreDataRollID];
    
    NSString *creatorID = [NSString coreDataNullTest:[rollDictionary valueForKey:@"creator_id"]];
    [roll setValue:creatorID forKey:kShelbyCoreDataRollCreatorID];
    
    NSString *frameCount = [NSString coreDataNullTest:[rollDictionary valueForKey:@"frame_count"]];
    [roll setValue:@([frameCount integerValue]) forKey:kShelbyCoreDataRollFrameCount];
    
    NSString *thumbnailURL = [NSString coreDataNullTest:[rollDictionary valueForKey:@"thumbnail_url"]];
    [roll setValue:thumbnailURL forKey:kShelbyCoreDataRollThumbnailURL];

    NSString *title = [NSString coreDataNullTest:[rollDictionary valueForKey:@"title"]];
    [roll setValue:title forKey:kShelbyCoreDataRollTitle];
    
}

- (void)storeVideo:(Video *)video fromDictionary:(NSDictionary *)videoDictionary
{
    NSString *videoID = [NSString coreDataNullTest:[videoDictionary valueForKey:@"id"]];
    [video setValue:videoID forKey:kShelbyCoreDataVideoID];
    
    NSString *caption = [NSString coreDataNullTest:[videoDictionary valueForKey:@"description"]];
    [video setValue:caption forKey:kShelbyCoreDataVideoCaption];
    
    NSString *providerName = [NSString coreDataNullTest:[videoDictionary valueForKey:@"provider_name"] ];
    [video setValue:providerName forKey:kShelbyCoreDataVideoProviderName];
    
    NSString *thumbnailURL = [NSString coreDataNullTest:[videoDictionary valueForKey:@"thumbnail_url"]];
    [video setValue:thumbnailURL forKey:kShelbyCoreDataVideoThumbnailURL];
    
    NSString *title = [NSString coreDataNullTest:[videoDictionary valueForKey:@"title"]];
    [video setValue:title forKey:kShelbyCoreDataVideoTitle];
    
    NSString *providerID = [NSString coreDataNullTest:[videoDictionary valueForKey:@"provider_id"]];
    [video setValue:providerID forKey:kShelbyCoreDataVideoProviderID];
    
    NSString *firstUnplayable = [NSString coreDataNullTest:[videoDictionary valueForKey:@"first_unplayable_at"]];
    [video setValue:@([firstUnplayable longLongValue])forKey:kShelbyCoreDataVideoFirstUnplayable];

    NSString *lastUnplayable = [NSString coreDataNullTest:[videoDictionary valueForKey:@"last_unplayable_at"]];
    [video setValue:@([lastUnplayable longLongValue])forKey:kShelbyCoreDataVideoLastUnplayable];
    
}

#pragma mark - Helper Methods (Private)
- (BOOL)isSupportedProvider:(Frame *)frame
{
    NSString *providerName = frame.video.providerName;
    NSString *providerID = frame.video.providerID;
    
    if ( [providerName isEqualToString:@"youtube"] || [providerName isEqualToString:@"dailymotion"] || ([providerName isEqualToString:@"vimeo"] && [providerID length] >= 6) ) {
        
        return YES;
    }
    
    return NO;
}

- (BOOL)isUnplayableVideo:(Video *)video
{
    NSNumber *firstUnplayable = [video firstUnplayable];
    if (firstUnplayable && [firstUnplayable longLongValue] != 0) {
        NSNumber *lastUnplayable = [video lastUnplayable];
        
        // Check if a video is marked unplayable for over 2 days
        if (lastUnplayable && [lastUnplayable longLongValue] != 0) {
            float unplayableTime = (float)([lastUnplayable longLongValue] - [firstUnplayable longLongValue]) / (1000 * 60 * 60);
            if (unplayableTime > 48) {
                return YES;
            }
        }
        
        // Check if a video was marked unplayable in the last 1 hour
        double currentSeconds = [[NSDate date] timeIntervalSince1970];
        float unplayableTimeSinceFirst = (currentSeconds - [lastUnplayable longLongValue] / 1000.0) / (60 * 60);
        if (unplayableTimeSinceFirst < 1) {
            return YES;
        }
    }

    return NO;
}

#pragma mark - Fetching Methods (Private)
- (NSMutableArray *)filterPlayableStreamFrames:(NSArray *)frames
{
    NSMutableArray *playableFrames = [@[] mutableCopy];
    
    for (Stream *stream in frames) {
        if ([self isSupportedProvider:stream.frame] && ![self isUnplayableVideo:[stream.frame video]]) {
            [playableFrames addObject:stream.frame];
        }
    }
    
    return playableFrames;
}

- (NSMutableArray *)filterPlayableFrames:(NSArray *)frames
{
    NSMutableArray *playableFrames = [@[] mutableCopy];
    
    for (Frame *frame in frames) {
        if ([self isSupportedProvider:frame] && ![self isUnplayableVideo:[frame video]]) {
            [playableFrames addObject:frame];
        }
    }
    
    return playableFrames;
}

- (NSMutableArray *)removeDuplicateFrames:(NSMutableArray *)frames
{
    NSMutableArray *tempFrames = [frames mutableCopy];
    
    for (NSUInteger i = 0; i < [tempFrames count]; ++i) {
        
        Frame *frame = (Frame *)tempFrames[i];
        NSString *videoID = frame.video.videoID;
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"videoID == %@", videoID];
        NSMutableArray *filteredArray = [NSMutableArray arrayWithArray:[frames filteredArrayUsingPredicate:predicate]];
        
        if ( [filteredArray count] > 1 ) {
            
            for (NSUInteger j = 1; j < [filteredArray count]; j++ ) {

                [frames removeObjectIdenticalTo:filteredArray[j]];
                
            }
        }
    }

    return frames;
}

- (NSMutableArray *)filterDownloadedFrames:(NSMutableArray *)frames
{
    NSMutableArray *downloadedFrames = [@[] mutableCopy];
    
    for (Frame *frame in frames) {
        if ( [frame.video.offlineURL length] > 0 ) {
            [downloadedFrames addObject:frame];
        }
    }
    
    return downloadedFrames;
}

- (void)postNotificationVideoInContext:(NSManagedObjectContext *)context
{
    if ( _videoID ) {
    
        // Create fetch request
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        [request setReturnsObjectsAsFaults:NO];
        
        // Search video data
        NSEntityDescription *description = [NSEntityDescription entityForName:kShelbyCoreDataEntityVideo inManagedObjectContext:context];
        [request setEntity:description];
        
        // Filter by videoID
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"videoID == %@", [self videoID]];
        [request setPredicate:predicate];
        
        // Execute request that returns array of Videos (should only have one object)
        NSArray *videoArray = [self.context executeFetchRequest:request error:nil];
        
        // Extract video from videoArray
        Video *video = (Video *)videoArray[0];
        
        // Post notification if SPVideoReel object is available
        NSDictionary *videoDictionary = @{kShelbySPCurrentVideo: video};
        [[NSNotificationCenter defaultCenter] postNotificationName:kShelbySPVideoExtracted
                                                            object:nil
                                                          userInfo:videoDictionary];
    }
}

#pragma mark - Syncing Methods (Private)
- (void)syncCategories:(NSDictionary *)webResultsDictionary
{
    
    /// Reference Web Categories
    NSArray *categoriesArray = webResultsDictionary[@"result"];
    NSMutableArray *webRollIDsArray = [@[] mutableCopy];;
    NSMutableArray *webChannelIDsArray = [@[] mutableCopy];
    
    // Reference all channels and rolls found on web as categories
    for ( NSUInteger i = 0; i < [categoriesArray count]; ++i ) {
        
                    
        // Rolls
        NSArray *webRollsArray = [[categoriesArray objectAtIndex:i] valueForKey:@"rolls"];
        
        for ( NSUInteger j = 0; j < [webRollsArray count]; ++j ) {
            
            NSDictionary *rollDictionary = [webRollsArray objectAtIndex:j];
            NSString *rollID = [rollDictionary valueForKey:@"id"];
            [webRollIDsArray addObject:rollID];
            
        }
        
        // Channels
        NSArray *webChannelsArray = [[categoriesArray objectAtIndex:i] valueForKey:@"user_channels"];
        
        for ( NSUInteger j = 0; j < [webChannelsArray count]; ++j ) {
            
            NSDictionary *channelDictionary = [webChannelsArray objectAtIndex:j];
            NSString *channelID = [channelDictionary valueForKey:@"user_id"];
            [webChannelIDsArray addObject:channelID];
            
        }
    }
    
    [self syncCategoryRolls:webRollIDsArray];
    [self syncCategoryChannels:webChannelIDsArray];
    
}

- (void)syncCategoryChannels:(NSMutableArray *)webChannelIDsArray
{
    /// Compare channels
    
    // Create channel fetch request
    NSFetchRequest *channelRequest = [[NSFetchRequest alloc] init];
    [channelRequest setReturnsObjectsAsFaults:NO];
    
    // Search channel table
    NSEntityDescription *channelDescription = [NSEntityDescription entityForName:kShelbyCoreDataEntityChannel inManagedObjectContext:_context];
    [channelRequest setEntity:channelDescription];
    
    // Execute request that returns array of rolls
    NSArray *channelResults = [self.context executeFetchRequest:channelRequest error:nil];
    
    // Perform Core Data vs. Shelby Web Database comparison
    for ( NSUInteger i = 0; i < [channelResults count]; ++i ) {
        
        Channel *channel = (Channel *)channelResults[i];
        NSString *channelID = channel.channelID;
        
        // If channel doesn't exist as web category any more, delete it
        if ( ![webChannelIDsArray containsObject:channelID] ) {
            
            [self.context deleteObject:channel];
            
        }
    }
    
    [self saveContext:_context];
}

- (void)syncCategoryRolls:(NSMutableArray *)webRollIDsArray
{
    // Create roll fetch request
    NSFetchRequest *rollRequest = [[NSFetchRequest alloc] init];
    [rollRequest setReturnsObjectsAsFaults:NO];
    
    // Search roll table
    NSEntityDescription *rollDescription = [NSEntityDescription entityForName:kShelbyCoreDataEntityRoll inManagedObjectContext:_context];
    [rollRequest setEntity:rollDescription];
    
    // Filter by isCategory
    NSPredicate *rollPredicate = [NSPredicate predicateWithFormat:@"isCategory == %d", YES];
    [rollRequest setPredicate:rollPredicate];
    
    // Execute request that returns array of rolls
    NSArray *rollResults = [self.context executeFetchRequest:rollRequest error:nil];
    
    // Perform Core Data vs. Shelby Web Database comparison
    for ( NSUInteger i = 0; i < [rollResults count]; ++i ) {
        
        Roll *roll = (Roll *)rollResults[i];
        NSString *rollID = roll.rollID;
        
        /*
         If roll doesn't exist as web category any more, retain the roll, but disallow it from showing up in the fetchAllCategories results
         This is done in case a specific roll is a logged-in user's personal roll (e.g., Reece's roll being a featured CategoryRoll and his personal roll)
         */
        
        if ( ![webRollIDsArray containsObject:rollID] ) {
            
            roll.isCategory = @NO;
            
        }
    }
    
    [self saveContext:_context];
}

@end