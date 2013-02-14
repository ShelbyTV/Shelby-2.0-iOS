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

- (void)removeOlderVideoFramesFromStream;
- (void)removeOlderVideoFramesFromLikes;
- (void)removeOlderVideoFramesFromPersonalRoll;

/// Storage Methods
- (void)storeFrame:(Frame *)frame forFrameArray:(NSArray *)frameArray withSyncStatus:(BOOL)syncStatus;
- (void)storeConversation:(Conversation *)conversation fromFrameArray:(NSArray *)frameArray;
- (void)storeCreator:(Creator *)creator fromFrameArray:(NSArray *)frameArray;
- (void)storeMessagesFromConversation:(Conversation *)conversation withConversationsArray:(NSArray *)conversationsArray;
- (void)storeRoll:(Roll *)roll fromFrameArray:(NSArray *)frameArray;
- (void)storeVideo:(Video *)video fromFrameArray:(NSArray *)frameArray;

/// Fetching Methods
- (NSMutableArray *)filterPlayableStreamFrames:(NSArray *)frames;
- (NSMutableArray *)filterPlayableFrames:(NSArray *)frames;
- (NSMutableArray *)removeDuplicateFrames:(NSMutableArray *)frames;
- (void)postNotificationVideoInContext:(NSManagedObjectContext *)context;

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
                    
                case DataRequestType_Fetch:{
                    
                    NSAssert((_requestType == DataRequestType_Fetch), @"DataRequestType_Fetch should not be used when storing data!");
                    
                } break;
                    
                case DataRequestType_StoreUser:{
                    
                    DLog(@"User Data Saved Successfully!");
                    [self.appDelegate userIsAuthorized];
                    
                } break;
                    
                case DataRequestType_BackgroundUpdate:{
                    
                    DLog(@"Background Update Successful");
                    
                } break;
                    
                case DataRequestType_Sync:{
                    
                    DLog(@"Core Data Sync Successful");
                    
                } break;
                    
                case DataRequestType_ActionUpdate:{
                    
                    DLog(@"User Action Update Successful");
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[NSNotificationCenter defaultCenter] postNotificationName:kShelbySPUserDidScrollToUpdate object:nil];
                    });
                    
                } break;
                    
                case DataRequestType_VideoExtracted:{
                    
                    DLog(@"Video Extracted and Data Stored Successfully!");
                    [self postNotificationVideoInContext:context];
                    
                } break;
                    
                case DataRequestType_StoreVideoInCache:{
                    
                    DLog(@"Video Stored in Cache");
                    
                } break;
                    
                default:
                    break;
            }
        }
    }
}

- (void)removeOlderVideoFramesForCategoryType:(CategoryType)categoryType
{

    switch ( categoryType ) {
            
        case CategoryType_Stream:{
            [self removeOlderVideoFramesFromStream];
        } break;
            
        case CategoryType_Likes:{
            [self removeOlderVideoFramesFromLikes];
        } break;
            
        case CategoryType_PersonalRoll:{
            [self removeOlderVideoFramesFromPersonalRoll];
        } break;
            
        default:
            break;
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
    NSArray *resultsArray = resultsDictionary[@"result"];
    
    User *user = [self checkIfEntity:kShelbyCoreDataEntityUser
                         withIDValue:[resultsArray valueForKey:@"id"]
                            forIDKey:kShelbyCoreDataUserID];
    
    NSString *userID = [NSString coreDataNullTest:[resultsArray valueForKey:@"id"]];
    [user setValue:userID forKey:kShelbyCoreDataUserID];
    
    NSString *userImage = [NSString coreDataNullTest:[resultsArray valueForKey:@"user_image"]];
    [user setValue:userImage forKey:kShelbyCoreDataUserImage];
    
    NSString *token = [NSString coreDataNullTest:[resultsArray valueForKey:@"authentication_token"]];
    [user setValue:token forKey:kShelbyCoreDataUserToken];
    
    NSString *nickname = [NSString coreDataNullTest:[resultsArray valueForKey:@"nickname"]];
    [user setValue:nickname forKey:kShelbyCoreDataUserNickname];
    
    NSString *personalRollID = [NSString coreDataNullTest:[resultsArray valueForKey:@"personal_roll_id"]];
    [user setValue:personalRollID forKey:kShelbyCoreDataUserPersonalRollID];
    
    NSString *likesRollID = [NSString coreDataNullTest:[resultsArray valueForKey:@"watch_later_roll_id"]];
    [user setValue:likesRollID forKey:kShelbyCoreDataUserLikesRollID];
    
    BOOL admin = [[resultsArray valueForKey:@"admin"] boolValue];
    [user setValue:@(admin) forKey:kShelbyCoreDataUserAdmin];
    
    [self saveContext:_context];

}

- (void)storeStream:(NSDictionary *)resultsDictionary
{
    NSArray *resultsArray = resultsDictionary[@"result"];
    
    for (NSUInteger i = 0; i < [resultsArray count]; ++i ) {
        
        @autoreleasepool {
            
            // Conditions for saving entires into database
            NSArray *frameArray = [resultsArray[i] valueForKey:@"frame"];
            BOOL frameExists = [frameArray isKindOfClass:([NSNull class])] ? NO : YES;
            
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
                                       withIDValue:[frameArray valueForKey:@"id"]
                                          forIDKey:kShelbyCoreDataFrameID];
                stream.frame = frame;
                
                [self storeFrame:frame forFrameArray:frameArray withSyncStatus:YES];
            }
        }
    }
    
    
    [self saveContext:_context];
    
}

- (void)storeRollFrames:(NSDictionary *)resultsDictionary
{
    NSArray *resultsArray = [resultsDictionary[@"result"] valueForKey:@"frames"];
    
    for ( NSUInteger i = 0; i < [resultsArray count]; ++i ) {
        
        @autoreleasepool {
                            
            Frame *frame = [self checkIfEntity:kShelbyCoreDataEntityFrame
                                   withIDValue:[resultsArray[i] valueForKey:@"id"]
                                      forIDKey:kShelbyCoreDataFrameID];
            
            [self storeFrame:frame forFrameArray:resultsArray[i] withSyncStatus:YES];

        }
    }
    
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
    
    // Search Stream table
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
    
    return deduplicatedFrames;
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
    
    return deduplicatedFrames;
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
    User *user = [self fetchUser];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"rollID == %@", [user likesRollID]];
    [request setPredicate:predicate];
    
    // Execute request that returns array of frames in Queue Roll
    NSArray *requestResults = [NSMutableArray arrayWithArray:[self.context executeFetchRequest:request error:nil]];
    
    // Filter Playable Results (YouTube, Vimeo, DailyMotion)
    NSMutableArray *playableFrames = [self filterPlayableFrames:requestResults];
    
    // Remove Frames that link to the same Video object
    NSMutableArray *deduplicatedFrames = [self removeDuplicateFrames:playableFrames];
    
    return deduplicatedFrames;
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
    // Set Predicate
    
    // Filter by rollID and timestamp
    User *user = [self fetchUser];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"((rollID == %@) AND (timestamp < %@))", [user likesRollID], date];
    [request setPredicate:predicate];
    
    // Execute request that returns array of frames in Queue Roll
    NSArray *requestResults = [NSMutableArray arrayWithArray:[self.context executeFetchRequest:request error:nil]];
    
    // Filter Playable Results (YouTube, Vimeo, DailyMotion)
    NSMutableArray *playableFrames = [self filterPlayableFrames:requestResults];
    
    // Remove Frames that link to the same Video object
    NSMutableArray *deduplicatedFrames = [self removeDuplicateFrames:playableFrames];
    
    return deduplicatedFrames;
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
    
    return deduplicatedFrames;
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
    
    return deduplicatedFrames;
}

- (NSString *)fetchTextFromFirstMessageInConversation:(Conversation *)conversation
{

    // Create fetch request
    NSFetchRequest *messagesRequest = [[NSFetchRequest alloc] init];
    [messagesRequest setReturnsObjectsAsFaults:NO];
    
    // Fetch messages data
    NSManagedObjectContext *context = conversation.managedObjectContext;
    NSEntityDescription *messagesDescription = [NSEntityDescription entityForName:kShelbyCoreDataEntityMessages inManagedObjectContext:context];
    [messagesRequest setEntity:messagesDescription];
    
    // Only include messages that belond to this specific conversation
    NSPredicate *messagesPredicate = [NSPredicate predicateWithFormat:@"conversationID == %@", conversation.conversationID];
    [messagesRequest setPredicate:messagesPredicate];
    
    // Sort by timestamp
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:NO];
    [messagesRequest setSortDescriptors:@[sortDescriptor]];
    
    // Execute request that returns array of dashboardEntrys
    NSArray *messagesArray = [context executeFetchRequest:messagesRequest error:nil];
    
    NSString *messageText;
    
    if ( [messagesArray count] ) {
        
        Messages *message = (Messages *) messagesArray[0];
        messageText = message.text;
    }

    
    return messageText.length ? messageText : @"No information available";
}

#pragma mark - Sync Methods (Public)
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
    
    // Execute request that returns array of streamEntries
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
    
    // Search Queue table
    NSEntityDescription *description = [NSEntityDescription entityForName:kShelbyCoreDataEntityFrame inManagedObjectContext:_context];
    [request setEntity:description];
    
    // Filter by rollID
    User *user = [self fetchUser];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"rollID == %@", [user personalRollID]];
    [request setPredicate:predicate];
    
    // Execute request that returns array of streamEntries
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
    
    // Search Queue table
    NSEntityDescription *description = [NSEntityDescription entityForName:kShelbyCoreDataEntityFrame inManagedObjectContext:_context];
    [request setEntity:description];
    
    // Filter by rollID
    User *user = [self fetchUser];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"rollID == %@", [user likesRollID]];
    [request setPredicate:predicate];
    
    // Execute request that returns array of streamEntries
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
    
    // Search Queue table
    NSEntityDescription *description = [NSEntityDescription entityForName:kShelbyCoreDataEntityFrame inManagedObjectContext:_context];
    [request setEntity:description];
    
    // Filter by rollID
    User *user = [self fetchUser];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"rollID == %@", [user personalRollID]];
    [request setPredicate:predicate];
    
    // Execute request that returns array of streamEntries
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

#pragma mark - Storage Methods (Private) 
- (void)storeFrame:(Frame *)frame forFrameArray:(NSArray *)frameArray withSyncStatus:(BOOL)syncStatus
{
        
    NSString *frameID = [NSString coreDataNullTest:[frameArray valueForKey:@"id"]];
    [frame setValue:frameID forKey:kShelbyCoreDataFrameID];
    
    NSString *conversationID = [NSString coreDataNullTest:[frameArray valueForKey:@"conversation_id"]];
    [frame setValue:conversationID forKey:kShelbyCoreDataFrameConversationID];
    
    NSString *createdAt = [NSString coreDataNullTest:[frameArray valueForKey:@"created_at"]];
    [frame setValue:createdAt forKey:kShelbyCoreDataFrameCreatedAt];
    
    NSString *creatorID = [NSString coreDataNullTest:[frameArray valueForKey:@"creator_id"]];
    [frame setValue:creatorID forKey:kShelbyCoreDataFrameCreatorID];
    
    NSString *rollID = [NSString coreDataNullTest:[frameArray valueForKey:@"roll_id"]];
    [frame setValue:rollID forKey:kShelbyCoreDataFrameRollID];
    
    NSDate *timestamp = [NSDate dataFromBSONObjectID:frameID];
    [frame setValue:timestamp forKey:kShelbyCoreDataFrameTimestamp];
    
    NSString *videoID = [NSString coreDataNullTest:[frameArray valueForKey:@"video_id"]];
    [frame setValue:videoID forKey:kShelbyCoreDataFrameVideoID];
    
    [frame setValue:@(syncStatus) forKey:kShelbyCoreDataFrameIsSynced];
    
    // Store Conversation (and Messages)
    Conversation *conversation = [self checkIfEntity:kShelbyCoreDataEntityConversation
                                         withIDValue:conversationID
                                            forIDKey:kShelbyCoreDataFrameConversationID];
    
    if ( conversation ) {
        
        frame.conversation = conversation;
        conversation.frame = frame;
        [self storeConversation:conversation fromFrameArray:frameArray];
        
    }
    
    // Store Creator
    Creator *creator = [self checkIfEntity:kShelbyCoreDataEntityCreator
                               withIDValue:creatorID
                                  forIDKey:kShelbyCoreDataFrameCreatorID];
    
    if ( creator ) {
    
        frame.creator = creator;
        [creator addFrameObject:frame];
        [self storeCreator:creator fromFrameArray:frameArray];
        
    }
    
    // Store Roll
    Roll *roll = [self checkIfEntity:kShelbyCoreDataEntityRoll
                         withIDValue:rollID
                            forIDKey:kShelbyCoreDataRollID];
    
    if ( roll ) {
    
        frame.roll = roll;
        roll.frame = frame;
        [self storeRoll:roll fromFrameArray:frameArray];
        
    }
    
    // Store Video
    Video *video = [self checkIfEntity:kShelbyCoreDataEntityVideo
                           withIDValue:videoID
                              forIDKey:kShelbyCoreDataFrameVideoID];
    
    if ( video ) {
    
        frame.video = video;
        [video addFrameObject:frame];
        [self storeVideo:video fromFrameArray:frameArray];
        
    }
    
    
}

- (void)storeConversation:(Conversation *)conversation fromFrameArray:(NSArray *)frameArray
{
    
    NSArray *conversationArray = [frameArray valueForKey:@"conversation"];
    
    NSString *conversationID = [NSString coreDataNullTest:[conversationArray valueForKey:@"id"]];
    [conversation setValue:conversationID forKey:kShelbyCoreDataConversationID];
    
    // Store Messages
    [self storeMessagesFromConversation:conversation withConversationsArray:conversationArray];
    
}

- (void)storeMessagesFromConversation:(Conversation *)conversation withConversationsArray:(NSArray *)conversationsArray
{
    
    NSArray *messagesArray = [conversationsArray valueForKey:@"messages"];
    
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

- (void)storeCreator:(Creator *)creator fromFrameArray:(NSArray *)frameArray
{
    NSArray *creatorArray = [frameArray valueForKey:@"creator"];
    
    NSString *creatorID = [NSString coreDataNullTest:[creatorArray valueForKey:@"id"]];
    [creator setValue:creatorID forKey:kShelbyCoreDataCreatorID];
    
    NSString *nickname = [NSString coreDataNullTest:[creatorArray valueForKey:@"nickname"]];
    [creator setValue:nickname forKey:kShelbyCoreDataCreatorNickname];
    
    NSString *userImage = [NSString coreDataNullTest:[creatorArray valueForKey:@"user_image"]];
    [creator setValue:userImage forKey:kShelbyCoreDataCreatorUserImage];
}

- (void)storeRoll:(Roll *)roll fromFrameArray:(NSArray *)frameArray
{
    NSArray *rollArray = [frameArray valueForKey:@"roll"];
    
    NSString *rollID = [NSString coreDataNullTest:[rollArray valueForKey:@"id"]];
    [roll setValue:rollID forKey:kShelbyCoreDataRollID];
    
    NSString *creatorID = [NSString coreDataNullTest:[rollArray valueForKey:@"creator_id"]];
    [roll setValue:creatorID forKey:kShelbyCoreDataRollCreatorID];
    
    NSString *frameCount = [NSString coreDataNullTest:[rollArray valueForKey:@"frame_count"]];
    [roll setValue:@([frameCount integerValue]) forKey:kShelbyCoreDataRollFrameCount];
    
    NSString *thumbnailURL = [NSString coreDataNullTest:[rollArray valueForKey:@"thumbnail_url"]];
    [roll setValue:thumbnailURL forKey:kShelbyCoreDataRollThumbnailURL];

    NSString *title = [NSString coreDataNullTest:[rollArray valueForKey:@"title"]];
    [roll setValue:title forKey:kShelbyCoreDataRollTitle];
    
}

- (void)storeVideo:(Video *)video fromFrameArray:(NSArray *)frameArray
{
    NSArray *videoArray = [frameArray valueForKey:@"video"];
    
    NSString *videoID = [NSString coreDataNullTest:[videoArray valueForKey:@"id"]];
    [video setValue:videoID forKey:kShelbyCoreDataVideoID];
    
    NSString *caption = [NSString coreDataNullTest:[videoArray valueForKey:@"description"]];
    [video setValue:caption forKey:kShelbyCoreDataVideoCaption];
    
    NSString *providerName = [NSString coreDataNullTest:[videoArray valueForKey:@"provider_name"] ];
    [video setValue:providerName forKey:kShelbyCoreDataVideoProviderName];
    
    NSString *thumbnailURL = [NSString coreDataNullTest:[videoArray valueForKey:@"thumbnail_url"]];
    [video setValue:thumbnailURL forKey:kShelbyCoreDataVideoThumbnailURL];
    
    NSString *title = [NSString coreDataNullTest:[videoArray valueForKey:@"title"]];
    [video setValue:title forKey:kShelbyCoreDataVideoTitle];
    
    NSString *providerID = [NSString coreDataNullTest:[videoArray valueForKey:@"provider_id"]];
    [video setValue:providerID forKey:kShelbyCoreDataVideoProviderID];
    
}

#pragma mark - Fetching Methods (Private)
- (NSMutableArray *)filterPlayableStreamFrames:(NSArray *)frames
{
    NSMutableArray *playableFrames = [@[] mutableCopy];
    
    for (NSUInteger i = 0; i < [frames count]; ++i ) {
        
        Stream *stream = (Stream *)frames[i];
        
        NSString *providerName = stream.frame.video.providerName;
        NSString *providerID = stream.frame.video.providerID;
        
        if ( [providerName isEqualToString:@"youtube"] || [providerName isEqualToString:@"dailymotion"] || ([providerName isEqualToString:@"vimeo"] && [providerID length] >= 6) ) {
            
            [playableFrames addObject:stream.frame];
            
        }
        
    }
    
    return playableFrames;
}

- (NSMutableArray *)filterPlayableFrames:(NSArray *)frames
{
    NSMutableArray *playableFrames = [@[] mutableCopy];
    
    for (NSUInteger i = 0; i < [frames count]; ++i ) {
        
        Frame *frame = (Frame *)frames[i];
        
        NSString *providerName = frame.video.providerName;
        NSString *providerID = frame.video.providerID;
        
        if ( [providerName isEqualToString:@"youtube"] || [providerName isEqualToString:@"dailymotion"] || ([providerName isEqualToString:@"vimeo"] && [providerID length] >= 6) ) {
            
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

@end