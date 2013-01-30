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

// Private Persistance Methods
- (void)mergeChanges:(NSNotification*)notification;

- (id)checkIfEntity:(NSString *)entityName
        withIDValue:(NSString *)entityIDValue
           forIDKey:(NSString *)entityIDKey;

// Private Storage Methods
- (void)storeFrame:(Frame*)frame forFrameArray:(NSArray *)frameArray withSyncStatus:(BOOL)syncStatus;
- (void)storeConversation:(Conversation *)conversation fromFrameArray:(NSArray *)frameArray;
- (void)storeCreator:(Creator*)creator fromFrameArray:(NSArray*)frameArray;
- (void)storeMessagesFromConversation:(Conversation *)conversation withConversationsArray:(NSArray *)conversationsArray;
- (void)storeRoll:(Roll*)roll fromFrameArray:(NSArray *)frameArray;
- (void)storeVideo:(Video *)video fromFrameArray:(NSArray *)frameArray;

// Private Fetching Methods
- (NSMutableArray*)filterPlayableStreamFrames:(NSArray*)frames;
- (NSMutableArray*)filterPlayableFrames:(NSArray*)frames;
- (NSMutableArray*)removeDuplicateFrames:(NSMutableArray*)frames;
- (void)postNotificationVideoInContext:(NSManagedObjectContext*)context;

@end

@implementation CoreDataUtility
@synthesize videoID = _videoID;
@synthesize appDelegate = _appDelegate;
@synthesize requestType = _requestType;
@synthesize context = _context;

#pragma mark - Initialization Methods
- (id)initWithRequestType:(DataRequestType)requestType
{
    if ( self = [super init] ) {
   
        self.appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
        self.context = [self.appDelegate context];
        self.requestType = requestType;
        
        // Add observer for mergining contexts
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(mergeChanges:)
                                                     name:NSManagedObjectContextDidSaveNotification
                                                   object:self.context];
        
    }
    
    return self;
}

#pragma mark - Public Persistance Methods
- (void)removeAllVideoExtractionURLReferences
{
//    // Create fetch request
//    NSFetchRequest *request = [[NSFetchRequest alloc] init];
//    [request setReturnsObjectsAsFaults:NO];
//    
//    // Search Stream table
//    NSEntityDescription *description = [NSEntityDescription entityForName:kCoreDataEntityVideo inManagedObjectContext:self.context];
//    [request setEntity:description];
//    
//    // Execute request that returns array of stream entries
//    NSMutableArray *entries = [[NSMutableArray alloc] initWithArray:[self.context executeFetchRequest:request error:nil]];
//    
//    for (NSUInteger i = 0; i < [entries count]; i++ ) {
//        
//        Video *video = (Video*)[entries objectAtIndex:i];
//        [video setExtractedURL:[NSString coreDataNullTest:nil]];
//        
//    }
//    
//    DLog(@"All video extractedURLs removed");

}

- (void)saveContext:(NSManagedObjectContext *)context
{
    if ( context ) {
        
        NSError *error = nil;
        
        if( ![context save:&error] ) { // Error
            
            DLog(@"Failed to save to data store: %@", [error localizedDescription]);
            DLog(@"Error for Data_Request: %d", self.requestType);
            
            NSArray *detailedErrors = [[error userInfo] objectForKey:NSDetailedErrorsKey];
            
            if( detailedErrors != nil && [detailedErrors count] > 0 ) {
                
                for(NSError* detailedError in detailedErrors) {
                    DLog(@"Detailed Error: %@", [detailedError userInfo]);
                }
                
            } else {
                
                DLog(@"%@", [error userInfo]);
                
            }
            
        } else { // Success
            
            switch (_requestType) {
                    
                case DataRequestType_Fetch:{
                    
                    NSAssert((_requestType == DataRequestType_Fetch), @"DataRequestType_Fetch should not be used when storing data!");
                    
                } break;
                    
                case DataRequestType_StoreUser:{
                    
                    DLog(@"User Data Saved Successfully!");
                    [self.appDelegate userIsAuthorized];
                    
                } break;
                    
                case DataRequestType_BackgroundUpdate:{
                    
                    // DLog(@"Background Update Successful");
                    
                } break;
                    
                case DataRequestType_Sync:{
                    
                    DLog(@"Core Data Sync Successful");
                    
                } break;
                    
                case DataRequestType_ActionUpdate:{
                    
                    DLog(@"User Action Update Successful");
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[NSNotificationCenter defaultCenter] postNotificationName:kSPUserDidScrollToUpdate object:nil];
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

#pragma mark - Public Storage Methods
- (void)storeUser:(NSDictionary *)resultsDictionary
{
    NSArray *resultsArray = [resultsDictionary objectForKey:@"result"];
    
    User *user = [self checkIfEntity:kCoreDataEntityUser
                         withIDValue:[resultsArray valueForKey:@"id"]
                            forIDKey:kCoreDataUserID];
    
    NSString *userID = [NSString coreDataNullTest:[resultsArray valueForKey:@"id"]];
    [user setValue:userID forKey:kCoreDataUserID];
    
    NSString *userImage = [NSString coreDataNullTest:[resultsArray valueForKey:@"user_image"]];
    [user setValue:userImage forKey:kCoreDataUserImage];
    
    NSString *token = [NSString coreDataNullTest:[resultsArray valueForKey:@"authentication_token"]];
    [user setValue:token forKey:kCoreDataUserToken];
    
    NSString *nickname = [NSString coreDataNullTest:[resultsArray valueForKey:@"nickname"]];
    [user setValue:nickname forKey:kCoreDataUserNickname];
    
    NSString *personalRollID = [NSString coreDataNullTest:[resultsArray valueForKey:@"personal_roll_id"]];
    [user setValue:personalRollID forKey:kCoreDataUserPersonalRollID];
    
    NSString *queueRollID = [NSString coreDataNullTest:[resultsArray valueForKey:@"watch_later_roll_id"]];
    [user setValue:queueRollID forKey:kCoreDataUserQueueRollID];
    
    BOOL admin = [[resultsArray valueForKey:@"admin"] boolValue];
    [user setValue:[NSNumber numberWithBool:admin] forKey:kCoreDataUserAdmin];
    
    [self saveContext:self.context];

}

- (void)storeStream:(NSDictionary *)resultsDictionary
{
    NSArray *resultsArray = [resultsDictionary objectForKey:@"result"];
    
    for (NSUInteger i = 0; i < [resultsArray count]; i++ ) {
        
        @autoreleasepool {
            
            // Conditions for saving entires into database
            NSArray *frameArray = [[resultsArray objectAtIndex:i] valueForKey:@"frame"];
            BOOL frameExists = [frameArray isKindOfClass:([NSNull class])] ? NO : YES;
            
            if ( !frameExists ) {
                
                // Do nothing (e.g., don't store this frame in core data)
                
            } else {
                
                Stream *stream = [self checkIfEntity:kCoreDataEntityStream
                                         withIDValue:[[resultsArray objectAtIndex:i] valueForKey:@"id"]
                                            forIDKey:kCoreDataStreamID];
                
                NSString *streamID = [NSString coreDataNullTest:[[resultsArray objectAtIndex:i] valueForKey:@"id"]];
                [stream setValue:streamID forKey:kCoreDataStreamID];
                
                NSDate *timestamp = [NSDate dataFromBSONObjectID:streamID];
                [stream setValue:timestamp forKey:kCoreDataStreamTimestamp];
                
                Frame *frame = [self checkIfEntity:kCoreDataEntityFrame
                                       withIDValue:[frameArray valueForKey:@"id"]
                                          forIDKey:kCoreDataFrameID];
                stream.frame = frame;
                
                [self storeFrame:frame forFrameArray:frameArray withSyncStatus:YES];
                
                [self saveContext:self.context];
            }
        }
    }
}

- (void)storeRollFrames:(NSDictionary *)resultsDictionary
{
    NSArray *resultsArray = [[resultsDictionary objectForKey:@"result"] valueForKey:@"frames"];
    
    for (NSUInteger i = 0; i < [resultsArray count]; i++ ) {
        
        @autoreleasepool {
                            
            Frame *frame = [self checkIfEntity:kCoreDataEntityFrame
                                   withIDValue:[[resultsArray objectAtIndex:i] valueForKey:@"id"]
                                      forIDKey:kCoreDataFrameID];
            
            [self storeFrame:frame forFrameArray:[resultsArray objectAtIndex:i] withSyncStatus:YES];
            
            [self saveContext:self.context];

        }
    }
}

#pragma mark - Public Fetch Methods
- (User *)fetchUser
{
    // Create fetch request
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setReturnsObjectsAsFaults:NO];
    
    // Search User table
    NSEntityDescription *description = [NSEntityDescription entityForName:kCoreDataEntityUser inManagedObjectContext:self.context];
    [request setEntity:description];
    
    // Execute request that returns array of Users
    NSArray *resultsArray = [self.context executeFetchRequest:request error:nil];
    
    return [resultsArray objectAtIndex:0]; 
}

- (NSUInteger)fetchStreamCount
{
    // Create fetch request
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setReturnsObjectsAsFaults:NO];
    
    // Search Stream table
    NSEntityDescription *description = [NSEntityDescription entityForName:kCoreDataEntityStream inManagedObjectContext:self.context];
    [request setEntity:description];
    
    // Execute request that returns array of Stream entries
    NSArray *streamEntries = [self.context executeFetchRequest:request error:nil];
    
    return [streamEntries count];
}

- (NSUInteger)fetchQueueRollCount
{
    // Create fetch request
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setReturnsObjectsAsFaults:NO];
    
    // Search Queue table
    NSEntityDescription *description = [NSEntityDescription entityForName:kCoreDataEntityFrame inManagedObjectContext:self.context];
    [request setEntity:description];
    
    // Filter by rollID
    User *user = [self fetchUser];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"rollID == %@", [user queueRollID]];
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
    NSEntityDescription *description = [NSEntityDescription entityForName:kCoreDataEntityFrame inManagedObjectContext:self.context];
    [request setEntity:description];
    
    // Filter by rollID
    User *user = [self fetchUser];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"rollID == %@", [user personalRollID]];
    [request setPredicate:predicate];
    
    // Execute request that returns array of frames
    NSArray *frameResults = [self.context executeFetchRequest:request error:nil];
    
    return [frameResults count];
}

- (NSMutableArray*)fetchStreamEntries
{
    
    // Create fetch request
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setReturnsObjectsAsFaults:NO];
    
    // Search Stream table
    NSEntityDescription *description = [NSEntityDescription entityForName:kCoreDataEntityStream inManagedObjectContext:self.context];
    [request setEntity:description];
    
    // Sort by timestamp
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:NO];
    [request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    
    // Execute request that returns array of Stream entries
    NSArray *requestResults = [self.context executeFetchRequest:request error:nil];
    
    // Filter Playable Results (YouTube, Vimeo, DailyMotion)
    NSMutableArray *playableFrames = [self filterPlayableStreamFrames:requestResults];
    
    // Remove Frames that link to the same Video object
    NSMutableArray *deduplicatedFrames = [self removeDuplicateFrames:playableFrames];
    
    return deduplicatedFrames;
}

- (NSMutableArray*)fetchMoreStreamEntriesAfterDate:(NSDate *)date
{
    
    // Create fetch request
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setReturnsObjectsAsFaults:NO];
    
    // Search Stream table
    NSEntityDescription *description = [NSEntityDescription entityForName:kCoreDataEntityStream inManagedObjectContext:self.context];
    [request setEntity:description];
    
    // Sort by timestamp
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:NO];
    [request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    
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

- (NSMutableArray*)fetchQueueRollEntries
{
    
    // Create fetch request
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setReturnsObjectsAsFaults:NO];
    
    // Search Frame table
    NSEntityDescription *description = [NSEntityDescription entityForName:kCoreDataEntityFrame inManagedObjectContext:self.context];
    [request setEntity:description];
    
    // Sort by timestamp
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:NO];
    [request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    
    // Filter by rollID
    User *user = [self fetchUser];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"rollID == %@", [user queueRollID]];
    [request setPredicate:predicate];
    
    // Execute request that returns array of frames in Queue Roll
    NSArray *requestResults = [NSMutableArray arrayWithArray:[self.context executeFetchRequest:request error:nil]];
    
    // Filter Playable Results (YouTube, Vimeo, DailyMotion)
    NSMutableArray *playableFrames = [self filterPlayableFrames:requestResults];
    
    // Remove Frames that link to the same Video object
    NSMutableArray *deduplicatedFrames = [self removeDuplicateFrames:playableFrames];
    
    return deduplicatedFrames;
}

- (NSMutableArray*)fetchMoreQueueRollEntriesAfterDate:(NSDate *)date
{
    
    // Create fetch request
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setReturnsObjectsAsFaults:NO];
    
    // Search Frame table
    NSEntityDescription *description = [NSEntityDescription entityForName:kCoreDataEntityFrame inManagedObjectContext:self.context];
    [request setEntity:description];
    
    // Sort by timestamp
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:NO];
    [request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    // Set Predicate
    
    // Filter by rollID and timestamp
    User *user = [self fetchUser];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"((rollID == %@) AND (timestamp < %@))", [user queueRollID], date];
    [request setPredicate:predicate];
    
    // Execute request that returns array of frames in Queue Roll
    NSArray *requestResults = [NSMutableArray arrayWithArray:[self.context executeFetchRequest:request error:nil]];
    
    // Filter Playable Results (YouTube, Vimeo, DailyMotion)
    NSMutableArray *playableFrames = [self filterPlayableFrames:requestResults];
    
    // Remove Frames that link to the same Video object
    NSMutableArray *deduplicatedFrames = [self removeDuplicateFrames:playableFrames];
    
    return deduplicatedFrames;
}

- (NSMutableArray*)fetchPersonalRollEntries
{
    
    // Create fetch request
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setReturnsObjectsAsFaults:NO];
    
    // Search Frame table
    NSEntityDescription *description = [NSEntityDescription entityForName:kCoreDataEntityFrame inManagedObjectContext:self.context];
    [request setEntity:description];
    
    // Sort by timestamp
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:NO];
    [request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    
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

- (NSMutableArray*)fetchMorePersonalRollEntriesAfterDate:(NSDate *)date
{
    
    // Create fetch request
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setReturnsObjectsAsFaults:NO];
    
    // Search Frame table
    NSEntityDescription *description = [NSEntityDescription entityForName:kCoreDataEntityFrame inManagedObjectContext:self.context];
    [request setEntity:description];
    
    // Sort by timestamp
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:NO];
    [request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
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
    NSEntityDescription *messagesDescription = [NSEntityDescription entityForName:kCoreDataEntityMessages inManagedObjectContext:context];
    [messagesRequest setEntity:messagesDescription];
    
    // Only include messages that belond to this specific conversation
    NSPredicate *messagesPredicate = [NSPredicate predicateWithFormat:@"conversationID == %@", conversation.conversationID];
    [messagesRequest setPredicate:messagesPredicate];
    
    // Sort by timestamp
    NSSortDescriptor *messagesTimestampSorter = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:NO];
    [messagesRequest setSortDescriptors:[NSArray arrayWithObject:messagesTimestampSorter]];
    
    // Execute request that returns array of dashboardEntrys
    NSArray *messagesArray = [context executeFetchRequest:messagesRequest error:nil];
    
    Messages *message = (Messages*) [messagesArray objectAtIndex:0];
    NSString *messageText = message.text;
    
    return messageText;
}

#pragma mark - Public Sync Methods
- (void)syncQueueRoll:(NSDictionary *)webResultsDictionary
{
    // Create fetch request
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setReturnsObjectsAsFaults:NO];
    
    // Search Queue table
    NSEntityDescription *description = [NSEntityDescription entityForName:kCoreDataEntityFrame inManagedObjectContext:self.context];
    [request setEntity:description];
    
    // Filter by rollID
    User *user = [self fetchUser];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"rollID == %@", [user queueRollID]];
    [request setPredicate:predicate];
    
    // Execute request that returns array of streamEntries
    NSArray *frameResults = [self.context executeFetchRequest:request error:nil];

    // Extract frameIDs from results from Shelby's Web Database
    NSArray *webResultsArray = [[webResultsDictionary objectForKey:@"result"] valueForKey:@"frames"];
    NSMutableArray *webFrameIdentifiersInQueue = [[NSMutableArray alloc] init];
    for (NSUInteger i = 0; i < [webResultsArray count]; i++) {
        
        NSString *frameID = [[webResultsArray objectAtIndex:i] valueForKey:@"id"];
        [webFrameIdentifiersInQueue addObject:frameID];
    }

    // Perform Core Data vs. Shelby Database comparison and remove objects that don't exist
    for ( NSUInteger i = 0; i < [frameResults count]; i++ ) {
        
        Frame *frame = (Frame*)[frameResults objectAtIndex:i];
        NSString *frameID = frame.frameID;
        
        // Delete object if it doesn't exist on web any more
        if ( ![webFrameIdentifiersInQueue containsObject:frameID] ) {
        
            DLog(@"FrameID doesn't exist on web: %@", frameID);
            
            [self.context deleteObject:frame];
            [self saveContext:self.context];
        }
        
    }
}

#pragma mark - Private Persistance Methods
- (void)mergeChanges:(NSNotification *)notification
{
    
    // Merge changes into the main context on the main thread
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSManagedObjectContext *mainThreadContext = [self.appDelegate context];
        [mainThreadContext performBlock:^{
            [mainThreadContext mergeChangesFromContextDidSaveNotification:notification];
        }];

    });

}

- (id)checkIfEntity:(NSString *)entityName
        withIDValue:(NSString *)entityIDValue
           forIDKey:(NSString *)entityIDKey
{
    
    // Create fetch request
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setReturnsObjectsAsFaults:NO];
    
    NSEntityDescription *description = [NSEntityDescription entityForName:entityName inManagedObjectContext:self.context];
    [request setEntity:description];
    
    // Only include objects that exist (i.e. entityIDKey and entityIDValue's must exist)
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", entityIDKey, entityIDValue];
    [request setPredicate:predicate];
    
    // Execute request that returns array with one object, the requested entity
    NSArray *array = [self.context executeFetchRequest:request error:nil];
    
    if ( [array count] ) {
        return [array objectAtIndex:0];
    }
    
    return [NSEntityDescription insertNewObjectForEntityForName:entityName inManagedObjectContext:self.context];
}

#pragma mark - Private Storage mMthods
- (void)storeFrame:(Frame *)frame forFrameArray:(NSArray *)frameArray withSyncStatus:(BOOL)syncStatus
{
    
    NSString *frameID = [NSString coreDataNullTest:[frameArray valueForKey:@"id"]];
    [frame setValue:frameID forKey:kCoreDataFrameID];
    
    NSString *conversationID = [NSString coreDataNullTest:[frameArray valueForKey:@"conversation_id"]];
    [frame setValue:conversationID forKey:kCoreDataFrameConversationID];
    
    NSString *createdAt = [NSString coreDataNullTest:[frameArray valueForKey:@"created_at"]];
    [frame setValue:createdAt forKey:kCoreDataFrameCreatedAt];
    
    NSString *creatorID = [NSString coreDataNullTest:[frameArray valueForKey:@"creator_id"]];
    [frame setValue:creatorID forKey:kCoreDataFrameCreatorID];
    
    NSString *rollID = [NSString coreDataNullTest:[frameArray valueForKey:@"roll_id"]];
    [frame setValue:rollID forKey:kCoreDataFrameRollID];
    
    NSDate *timestamp = [NSDate dataFromBSONObjectID:frameID];
    [frame setValue:timestamp forKey:kCoreDataFrameTimestamp];
    
    NSString *videoID = [NSString coreDataNullTest:[frameArray valueForKey:@"video_id"]];
    [frame setValue:videoID forKey:kCoreDataFrameVideoID];
    
    [frame setValue:[NSNumber numberWithBool:syncStatus] forKey:kCoreDataFrameIsSynced];
    
    // Store Conversation (and Messages)
    Conversation *conversation = [self checkIfEntity:kCoreDataEntityConversation
                                         withIDValue:conversationID
                                            forIDKey:kCoreDataFrameConversationID];
    frame.conversation = conversation;
    [conversation addFrameObject:frame];
    [self storeConversation:conversation fromFrameArray:frameArray];
    
    // Store Creator
    Creator *creator = [self checkIfEntity:kCoreDataEntityCreator
                               withIDValue:creatorID
                                  forIDKey:kCoreDataFrameCreatorID];
    frame.creator = creator;
    [creator addFrameObject:frame];
    [self storeCreator:creator fromFrameArray:frameArray];
    
    // Store Roll
    Roll *roll = [self checkIfEntity:kCoreDataEntityRoll
                         withIDValue:rollID
                            forIDKey:kCoreDataRollID];
    frame.roll = roll;
    roll.frame = frame;
    [self storeRoll:roll fromFrameArray:frameArray];
    
    // Store Video
    Video *video = [self checkIfEntity:kCoreDataEntityVideo
                           withIDValue:videoID
                              forIDKey:kCoreDataFrameVideoID];
    frame.video = video;
    [video addFrameObject:frame];
    [self storeVideo:video fromFrameArray:frameArray];
    
}

- (void)storeConversation:(Conversation *)conversation fromFrameArray:(NSArray *)frameArray
{
    
    NSArray *conversationArray = [frameArray valueForKey:@"conversation"];
    
    NSString *conversationID = [NSString coreDataNullTest:[conversationArray valueForKey:@"id"]];
    [conversation setValue:conversationID forKey:kCoreDataConversationID];
    
    // Store Messages
    [self storeMessagesFromConversation:conversation withConversationsArray:conversationArray];
    
}

- (void)storeMessagesFromConversation:(Conversation *)conversation withConversationsArray:(NSArray *)conversationsArray
{
    
    NSArray *messagesArray = [conversationsArray valueForKey:@"messages"];
    
    [conversation setValue:[NSNumber numberWithInt:[messagesArray count]] forKey:kCoreDataConversationMessageCount];
    
    for ( NSUInteger i = 0; i < [messagesArray count]; i++ ) {
        
        Messages *messages = [self checkIfEntity:kCoreDataEntityMessages
                                     withIDValue:[[messagesArray objectAtIndex:i] valueForKey:@"id"]
                                        forIDKey:kCoreDataMessagesID];
        
        [conversation addMessagesObject:messages];
        
        // Hold reference to parent conversationID
        [messages setValue:conversation.conversationID forKey:kCoreDataConversationID];
        
        NSString *messageID = [NSString coreDataNullTest:[[messagesArray objectAtIndex:i] valueForKey:@"id"]];
        [messages setValue:messageID forKey:kCoreDataMessagesID];
        
        NSString *createdAt = [NSString coreDataNullTest:[[messagesArray objectAtIndex:i]  valueForKey:@"created_at"]];
        [messages setValue:createdAt forKey:kCoreDataMessagesCreatedAt];
        
        NSString *nickname = [NSString coreDataNullTest:[[messagesArray objectAtIndex:i]  valueForKey:@"nickname"]];
        [messages setValue:nickname forKey:kCoreDataMessagesNickname];
        
        NSString *originNetwork = [NSString coreDataNullTest:[[messagesArray objectAtIndex:i] valueForKey:@"origin_network"]];
        [messages setValue:originNetwork forKey:kCoreDataMessagesOriginNetwork];
        
        NSDate *timestamp = [NSDate dataFromBSONObjectID:messageID];
        [messages setValue:timestamp forKey:kCoreDataMessagesTimestamp];
        
        NSString *text = [NSString coreDataNullTest:[[messagesArray objectAtIndex:i]  valueForKey:@"text"]];
        [messages setValue:text forKey:kCoreDataMessagesText];
        
        NSString *userImage = [NSString coreDataNullTest:[[messagesArray objectAtIndex:i]  valueForKey:@"user_image_url"]];
        [messages setValue:userImage forKey:kCoreDataMessagesUserImage];
        
    }
    
}

- (void)storeCreator:(Creator *)creator fromFrameArray:(NSArray *)frameArray
{
    NSArray *creatorArray = [frameArray valueForKey:@"creator"];
    
    NSString *creatorID = [NSString coreDataNullTest:[creatorArray valueForKey:@"id"]];
    [creator setValue:creatorID forKey:kCoreDataCreatorID];
    
    NSString *nickname = [NSString coreDataNullTest:[creatorArray valueForKey:@"nickname"]];
    [creator setValue:nickname forKey:kCoreDataCreatorNickname];
    
    NSString *userImage = [NSString coreDataNullTest:[creatorArray valueForKey:@"user_image"]];
    [creator setValue:userImage forKey:kCoreDataCreatorUserImage];
}

- (void)storeRoll:(Roll *)roll fromFrameArray:(NSArray *)frameArray
{
    NSArray *rollArray = [frameArray valueForKey:@"roll"];
    
    NSString *rollID = [NSString coreDataNullTest:[rollArray valueForKey:@"id"]];
    [roll setValue:rollID forKey:kCoreDataRollID];
    
    NSString *creatorID = [NSString coreDataNullTest:[rollArray valueForKey:@"creator_id"]];
    [roll setValue:creatorID forKey:kCoreDataRollCreatorID];
    
    NSString *frameCount = [NSString coreDataNullTest:[rollArray valueForKey:@"frame_count"]];
    [roll setValue:[NSNumber numberWithInteger:[frameCount integerValue]] forKey:kCoreDataRollFrameCount];
    
    NSString *thumbnailURL = [NSString coreDataNullTest:[rollArray valueForKey:@"thumbnail_url"]];
    [roll setValue:thumbnailURL forKey:kCoreDataRollThumbnailURL];

    NSString *title = [NSString coreDataNullTest:[rollArray valueForKey:@"title"]];
    [roll setValue:title forKey:kCoreDataRollTitle];
    
}

- (void)storeVideo:(Video *)video fromFrameArray:(NSArray *)frameArray
{
    NSArray *videoArray = [frameArray valueForKey:@"video"];
    
    NSString *videoID = [NSString coreDataNullTest:[videoArray valueForKey:@"id"]];
    [video setValue:videoID forKey:kCoreDataVideoID];
    
    NSString *caption = [NSString coreDataNullTest:[videoArray valueForKey:@"description"]];
    [video setValue:caption forKey:kCoreDataVideoCaption];
    
    NSString *providerName = [NSString coreDataNullTest:[videoArray valueForKey:@"provider_name"] ];
    [video setValue:providerName forKey:kCoreDataVideoProviderName];
    
    NSString *thumbnailURL = [NSString coreDataNullTest:[videoArray valueForKey:@"thumbnail_url"]];
    [video setValue:thumbnailURL forKey:kCoreDataVideoThumbnailURL];
    
    NSString *title = [NSString coreDataNullTest:[videoArray valueForKey:@"title"]];
    [video setValue:title forKey:kCoreDataVideoTitle];
    
    NSString *providerID = [NSString coreDataNullTest:[videoArray valueForKey:@"provider_id"]];
    [video setValue:providerID forKey:kCoreDataVideoProviderID];
    
}

#pragma mark - Private Fetching Methods
- (NSMutableArray *)filterPlayableStreamFrames:(NSArray *)frames
{
    NSMutableArray *playableFrames = [[NSMutableArray alloc] init];
    
    for (NSUInteger i = 0; i < [frames count]; i++ ) {
        
        Stream *stream = (Stream*)[frames objectAtIndex:i];
        
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
    NSMutableArray *playableFrames = [[NSMutableArray alloc] init];
    
    for (NSUInteger i = 0; i < [frames count]; i++ ) {
        
        Frame *frame = (Frame*)[frames objectAtIndex:i];
        
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
    NSMutableArray *tempFrames = [[NSMutableArray alloc] initWithArray:frames];
    
    for (NSUInteger i = 0; i < [tempFrames count]; i++) {
        
        Frame *frame = (Frame*)[tempFrames objectAtIndex:i];
        NSString *videoID = frame.video.videoID;
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"videoID == %@", videoID];
        NSMutableArray *filteredArray = [NSMutableArray arrayWithArray:[frames filteredArrayUsingPredicate:predicate]];
        
        if ( [filteredArray count] > 1 ) {
            
            for (NSUInteger j = 1; j < [filteredArray count]; j++ ) {
                
                [frames removeObjectIdenticalTo:[filteredArray objectAtIndex:j]];
                
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
        NSEntityDescription *description = [NSEntityDescription entityForName:kCoreDataEntityVideo inManagedObjectContext:context];
        [request setEntity:description];
        
        // Filter by videoID
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"videoID == %@", [self videoID]];
        [request setPredicate:predicate];
        
        // Execute request that returns array of Videos (should only have one object)
        NSArray *videoArray = [self.context executeFetchRequest:request error:nil];
        
        // Extract video from videoArray
        Video *video = (Video*)[videoArray objectAtIndex:0];
        
        // Post notification if SPVideoReel object is available
        NSDictionary *videoDictionary = [NSDictionary dictionaryWithObjectsAndKeys:video, kSPCurrentVideo, nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:kSPVideoExtracted
                                                            object:nil
                                                          userInfo:videoDictionary];
    }
}

@end