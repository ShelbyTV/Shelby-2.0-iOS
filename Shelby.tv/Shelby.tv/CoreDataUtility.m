//
//  CoreDataUtility.m
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 10/25/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

#import "CoreDataUtility.h"

@interface CoreDataUtility ()
{
    NSManagedObjectContext *_context;
}

@property (strong ,nonatomic) NSManagedObjectContext *context;
@property (strong, nonatomic) AppDelegate *appDelegate;
@property (assign, nonatomic) DataRequestType requestType;

- (void)mergeChanges:(NSNotification*)notification;

- (id)checkIfEntity:(NSString *)entityName
        withIDValue:(NSString *)entityIDValue
           forIDKey:(NSString *)entityIDKey;

- (void)storeFrame:(Frame*)frame forFrameArray:(NSArray *)frameArray withSyncStatus:(BOOL)syncStatus;
- (void)storeConversation:(Conversation *)conversation fromFrameArray:(NSArray *)frameArray;
- (void)storeMessagesFromConversation:(Conversation *)conversation withConversationsArray:(NSArray *)conversationsArray;
- (void)storeRoll:(Roll*)roll fromFrameArray:(NSArray *)frameArray;
- (void)storeVideo:(Video *)video fromFrameArray:(NSArray *)frameArray;

@end

@implementation CoreDataUtility
@synthesize context = _context;
@synthesize appDelegate = _appDelegate;
@synthesize requestType = _requestType;

#pragma mark - Memory Management
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextDidSaveNotification object:_context];
}

#pragma mark - Initialization Methods
- (id)initWithRequestType:(DataRequestType)requestType
{
    if ( self = [super init] ) {
        self.appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
        self.requestType = requestType;
    }
    
    return self;
}

#pragma mark - Public Methods (Persistance)
- (void)saveContext:(NSManagedObjectContext *)context
{
    
        if ( context ) {
            
            NSError *error = nil;
            
            if( ![context save:&error] ) { // Error
                
                DLog(@"Failed to save to data store: %@", [error localizedDescription]);
                
                NSArray *detailedErrors = [[error userInfo] objectForKey:NSDetailedErrorsKey];
                
                if( detailedErrors != nil && [detailedErrors count] > 0 ) {
                    
                    for(NSError* detailedError in detailedErrors) {
                        DLog(@"  Detailed Error: %@", [detailedError userInfo]);
                    }
                
                } else {
                
                    DLog(@"%@", [error userInfo]);
                
                }
                
            } else { // Success
                
                switch (_requestType) {
                        
                    case DataRequestType_None:{
                        
                        DLog(@"General Data Saved Successfully!");
                        
                    } break;
                    
                    case DataRequestType_User:{
                        
                        DLog(@"User Data Saved Successfully!");
                        
                        [self.appDelegate userIsAuthorized];
                        
                    } break;
                    
                    case DataRequestType_Stream:{
                        
                        DLog(@"Stream Data Saved Successfully!");
                        
                    } break;
                        
                    case DataRequestType_QueueRoll:{
                        
                        DLog(@"Queue Roll Data Saved Successfully!");
                        
                    } break;
                        
                    case DataRequestType_PersonalRoll:{
                        
                        DLog(@"Personal Roll Data Saved Successfully!");
                        
                    } break;
                        
                    case DataRequestType_CategoryRoll:{
                        
                        DLog(@"Catogory Roll Data Saved Successfully!");
                        
                    } break;
                        
                    default:
                        break;
                }
            }
        }
}

- (void)dumpAllData
{ 
    NSPersistentStoreCoordinator *coordinator =  [self.appDelegate persistentStoreCoordinator];
    NSPersistentStore *store = [[coordinator persistentStores] objectAtIndex:0];
    [[NSFileManager defaultManager] removeItemAtURL:store.URL error:nil];
    [coordinator removePersistentStore:store error:nil];
}

#pragma mark - Public Methods (Store)
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
    
    [self saveContext:_context];

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
                
                NSString *provider = [[[[resultsArray objectAtIndex:i] valueForKey:@"frame"] valueForKey:@"video"] valueForKey:@"provider_name"];
                BOOL sourceURL = [[[[[resultsArray objectAtIndex:i] valueForKey:@"frame"] valueForKey:@"video"] valueForKey:@"source_url"] isEqual:[NSNull null]] ? NO : YES;
                BOOL embedURL = [[[[[resultsArray objectAtIndex:i] valueForKey:@"frame"] valueForKey:@"video"] valueForKey:@"emebd_url"] isEqual:[NSNull null]] ? NO : YES;
                
                if ( ([provider isEqualToString:@"youtube"] && sourceURL) || ([provider isEqualToString:@"vimeo"] && embedURL) ) {
                    
                    Stream *stream = [self checkIfEntity:kCoreDataEntityStream
                                             withIDValue:[[resultsArray objectAtIndex:i] valueForKey:@"id"]
                                                forIDKey:kCoreDataStreamID];
                    
                    NSString *streamID = [NSString coreDataNullTest:[[resultsArray objectAtIndex:i] valueForKey:@"id"]];
                    [stream setValue:streamID forKey:kCoreDataStreamID];
                    
                    NSDate *timestamp = [NSDate dataFromBSONstring:streamID];
                    [stream setValue:timestamp forKey:kCoreDataStreamTimestamp];
                    
                    Frame *frame = [self checkIfEntity:kCoreDataEntityFrame
                                           withIDValue:[frameArray valueForKey:@"id"]
                                              forIDKey:kCoreDataFrameID];
                    stream.frame = frame;
                    
                    [self storeFrame:frame forFrameArray:frameArray withSyncStatus:YES];
                    
                }
            }
        }
    }
    
    [self saveContext:_context];
    
}

- (void)storeRollFrames:(NSDictionary *)resultsDictionary
{
    NSArray *resultsArray = [[resultsDictionary objectForKey:@"result"] valueForKey:@"frames"];
    
    for (NSUInteger i = 0; i < [resultsArray count]; i++ ) {
        
        @autoreleasepool {
                
                NSString *provider = [[[resultsArray objectAtIndex:i] valueForKey:@"video"] valueForKey:@"provider_name"];
                BOOL sourceURL = [[[[resultsArray objectAtIndex:i] valueForKey:@"video"] valueForKey:@"source_url"] isEqual:[NSNull null]] ? NO : YES;
                BOOL embedURL = [[[[resultsArray objectAtIndex:i]valueForKey:@"video"] valueForKey:@"emebd_url"] isEqual:[NSNull null]] ? NO : YES;
                
                if ( ([provider isEqualToString:@"youtube"] && sourceURL) || ([provider isEqualToString:@"vimeo"] && embedURL) ) {
                    
                    Frame *frame = [self checkIfEntity:kCoreDataEntityFrame
                                           withIDValue:[[resultsArray objectAtIndex:i] valueForKey:@"id"]
                                              forIDKey:kCoreDataFrameID];
                    
                    [self storeFrame:frame forFrameArray:[resultsArray objectAtIndex:i] withSyncStatus:YES];
                    
                    
                }
            }
        }
    
    [self saveContext:_context];
}

#pragma mark - Public Methods (Fetch)
- (User *)fetchUser
{
    // Create fetch request
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setReturnsObjectsAsFaults:NO];
    
    // Search dashboardEntry data
    NSEntityDescription *description = [NSEntityDescription entityForName:kCoreDataEntityUser inManagedObjectContext:self.context];
    [request setEntity:description];
    
    // Execute request that returns array of Users
    NSArray *resultsArray = [self.context executeFetchRequest:request error:nil];
    
    return [resultsArray objectAtIndex:0];
    
}

- (NSMutableArray*)fetchStreamEntries
{
    
    // Create fetch request
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setReturnsObjectsAsFaults:NO];
    
    // Search dashboardEntry data
    NSEntityDescription *description = [NSEntityDescription entityForName:kCoreDataEntityStream inManagedObjectContext:self.context];
    [request setEntity:description];
    
    // Sort by timestamp
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:NO];
    [request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    
    // Execute request that returns array of dashboardEntrys
    NSArray *streamEntries = [self.context executeFetchRequest:request error:nil];
    
    // Extract Frames
    NSMutableArray *frames = [[NSMutableArray alloc] init];
    for (NSUInteger i = 0; i < [streamEntries count]; i++ ) {
        
        Stream *stream = (Stream*)[streamEntries objectAtIndex:0];
        [frames addObject:stream.frame];
        
    }
    
    return frames;
}

- (NSArray*)fetchQueueRollEntries
{
    
    // Create fetch request
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setReturnsObjectsAsFaults:NO];
    
    // Search dashboardEntry data
    NSEntityDescription *description = [NSEntityDescription entityForName:kCoreDataEntityFrame inManagedObjectContext:self.context];
    [request setEntity:description];
    
    // Filter by rollID
    User *user = [self fetchUser];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"rollID == %@", [user queueRollID]];
    [request setPredicate:predicate];
    
    // Execute request that returns array of dashboardEntrys
    return [self.context executeFetchRequest:request error:nil];
    
}

- (NSArray*)fetchPersonalRollEntries
{
    
    // Create fetch request
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setReturnsObjectsAsFaults:NO];
    
    // Search dashboardEntry data
    NSEntityDescription *description = [NSEntityDescription entityForName:kCoreDataEntityFrame inManagedObjectContext:self.context];
    [request setEntity:description];
    
    // Filter by rollID
    User *user = [self fetchUser];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"rollID == %@", [user personalRollID]];
    [request setPredicate:predicate];
    
    // Execute request that returns array of dashboardEntrys
    return [self.context executeFetchRequest:request error:nil];
    
}

#pragma mark - Private Methods
- (void)mergeChanges:(NSNotification *)notification
{
    
    // Merge changes into the main context on the main thread
    [self.context performSelectorOnMainThread:@selector(mergeChangesFromContextDidSaveNotification:)
                                   withObject:notification
                                waitUntilDone:YES];
    
    DLog(@"Data Merged!");
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

- (void)storeFrame:(Frame *)frame forFrameArray:(NSArray *)frameArray withSyncStatus:(BOOL)syncStatus
{
    
    NSString *frameID = [NSString coreDataNullTest:[frameArray valueForKey:@"id"]];
    [frame setValue:frameID forKey:kCoreDataFrameID ];
    
    NSString *conversationID = [NSString coreDataNullTest:[frameArray valueForKey:@"conversation_id"]];
    [frame setValue:conversationID forKey:kCoreDataFrameConversationID];
    
    NSString *createdAt = [NSString coreDataNullTest:[frameArray valueForKey:@"created_at"]];
    [frame setValue:createdAt forKey:kCoreDataFrameCreatedAt ];
    
    NSString *rollID = [NSString coreDataNullTest:[frameArray valueForKey:@"roll_id"]];
    [frame setValue:rollID forKey:kCoreDataFrameRollID];
    
    NSDate *timestamp = [NSDate dataFromBSONstring:frameID];
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
    
    
    // Store Roll
    Roll *roll = [self checkIfEntity:kCoreDataEntityRoll
                         withIDValue:rollID
                            forIDKey:kCoreDataRollID];
    
    frame.roll = roll;
    [roll addFrameObject:frame];
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
    
    // Store dashboard.frame.conversation.messages attributes
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
        
        NSDate *timestamp = [NSDate dataFromBSONstring:messageID];
        [messages setValue:timestamp forKey:kCoreDataMessagesTimestamp];
        
        NSString *text = [NSString coreDataNullTest:[[messagesArray objectAtIndex:i]  valueForKey:@"text"]];
        [messages setValue:text forKey:kCoreDataMessagesText];
        
        NSString *userImage = [NSString coreDataNullTest:[[messagesArray objectAtIndex:i]  valueForKey:@"user_image_url"]];
        [messages setValue:userImage forKey:kCoreDataMessagesUserImage];
        
    }
    
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
    
    
    if ( [providerName isEqualToString:@"youtube"] ) {
        
        NSString *sourceURL = [NSString coreDataNullTest:[videoArray valueForKey:@"source_url"]];
        [video setValue:sourceURL forKey:kCoreDataVideoSourceURL];
        
        NSString *providerID;
        NSScanner *providerIDScanner = [NSScanner scannerWithString:sourceURL];
        [providerIDScanner scanUpToString:@"=" intoString:nil];
        [providerIDScanner scanUpToString:@"&" intoString:&providerID];
        providerID = [providerID stringByReplacingOccurrencesOfString:@"=" withString:@""];
        
        [video setValue:providerID forKey:kCoreDataVideoProviderID];
        
    } else if ( [providerName isEqualToString:@"vimeo"] ) {
        
        NSString *embedURL = [NSString coreDataNullTest:[videoArray valueForKey:@"embed_url"]];
        NSString *sourceURL;
        NSScanner *scanner = [NSScanner scannerWithString:embedURL];
        [scanner scanUpToString:@"http://" intoString:nil];
        [scanner scanUpToString:@"\"" intoString:&sourceURL];
        sourceURL = [sourceURL stringByReplacingOccurrencesOfString:@"=" withString:@""];
        [video setValue:sourceURL forKey:kCoreDataVideoSourceURL];
        
        NSString *providerID;
        NSScanner *providerIDScanner = [NSScanner scannerWithString:sourceURL];
        [providerIDScanner scanUpToString:@"/video/" intoString:nil];
        [providerIDScanner scanUpToString:@"\"" intoString:&providerID];
        providerID = [providerID stringByReplacingOccurrencesOfString:@"/video/" withString:@""];
        
        [video setValue:providerID forKey:kCoreDataVideoProviderID];
        
    } else {
        
        // Do nothing
        
    }
    
}

#pragma mark - Accessor Methods
- (NSManagedObjectContext*)context;
{

    if ( _context ) { // If context is already initialized, return it.
        
        return _context;
        
    } else { // Initialize context iVar (should only be called once)

        NSPersistentStoreCoordinator *coordinator = [self.appDelegate persistentStoreCoordinator];
        
        _context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        [_context setUndoManager:nil];
        [_context setPersistentStoreCoordinator:coordinator];
        [_context setRetainsRegisteredObjects:YES];
        
        // Set context with appropriate merge policy (depending on context's execution thread)
        if ( [NSThread isMainThread] ) {

            [_context setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
//            DLog(@"Main Thread");
        
        } else {
            
            [_context setMergePolicy:NSMergeByPropertyStoreTrumpMergePolicy];
//            DLog(@"Background Thread");
        
        }
    
    }
    
    // Add observer for mergining contexts
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mergeChanges:) name:NSManagedObjectContextDidSaveNotification object:_context];
    
    return _context;

}

@end