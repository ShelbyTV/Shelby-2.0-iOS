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
    NSManagedObjectModel *_managedObjectModel;
    NSManagedObjectContext *_managedObjectContext;
    NSPersistentStoreCoordinator *_persistentStoreCoordinator;
}

@property (strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

+ (id)checkIfEntity:(NSString *)entityName
        withIDValue:(NSString *)entityIDValue
           forIDKey:(NSString *)entityIDKey;

+ (void)storeFrame:(Frame*)frame forFrameArray:(NSArray *)frameArray;
+ (void)storeConversation:(Conversation *)conversation fromFrameArray:(NSArray *)frameArray;
+ (void)storeMessagesFromConversation:(Conversation *)conversation withConversationsArray:(NSArray *)conversationsArray;
+ (void)storeVideo:(Video *)video fromFrameArray:(NSArray *)frameArray;

@end

@implementation CoreDataUtility
@synthesize managedObjectModel = _managedObjectModel;
@synthesize managedObjectContext = _managedObjectContext;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

static CoreDataUtility *sharedInstance = nil;

#pragma mark - Singleton Methods
+ (CoreDataUtility*)sharedInstance
{
    if ( nil == sharedInstance) {
        sharedInstance = [[super allocWithZone:NULL] init];
    }
    return sharedInstance;
}

+ (id)allocWithZone:(NSZone *)zone
{
    return [self sharedInstance];
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

#pragma mark - Public Methods
+ (NSManagedObjectContext*)createContext;
{
    
    NSPersistentStoreCoordinator *coordinator = [[self sharedInstance] persistentStoreCoordinator];
    
    NSManagedObjectContext *context = [[NSManagedObjectContext alloc] init];
    [context setUndoManager:nil];
    [context setPersistentStoreCoordinator:coordinator];
    [context setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
    return context;

}


+ (void)saveContext:(NSManagedObjectContext *)context
{

    if ( context ) {

        NSError *error = nil;
        
        if( ![context save:&error] ) { // Error
            
            DLog(@"Failed to save to data store: %@", [error localizedDescription]);
          
            NSArray* detailedErrors = [[error userInfo] objectForKey:NSDetailedErrorsKey];
            if(detailedErrors != nil && [detailedErrors count] > 0) {
                for(NSError* detailedError in detailedErrors) {
                    DLog(@"  DetailedError: %@", [detailedError userInfo]);
                }
            } else {
                DLog(@"%@", [error userInfo]);
            }
            
        } else { // Success
            DLog(@"Core Data Updated!");
        }
    }
}

+ (void)dumpAllData
{
    
    NSPersistentStoreCoordinator *coordinator =  [[self sharedInstance] persistentStoreCoordinator];
    NSPersistentStore *store = [[coordinator persistentStores] objectAtIndex:0];
    [[NSFileManager defaultManager] removeItemAtURL:store.URL error:nil];
    [coordinator removePersistentStore:store error:nil];
    [[self sharedInstance] setPersistentStoreCoordinator:nil];
    
}

+ (void)storeStream:(NSDictionary *)resultsDictionary
{
    NSArray *resultsArray = [resultsDictionary objectForKey:@"result"];
    
    for (NSUInteger i = 0; i < [resultsArray count]; i++ ) {
        
        @autoreleasepool {
            
            // Conditions for saving entires into database
            BOOL sourceURLExists = [[[[[resultsArray objectAtIndex:i] valueForKey:@"frame"] valueForKey:@"video"] valueForKey:@"source_url"] isKindOfClass:[NSNull class]] ? NO : YES;
            BOOL embedURLExists = [[[[[resultsArray objectAtIndex:i] valueForKey:@"frame"] valueForKey:@"video"] valueForKey:@"embed_url"] isKindOfClass:[NSNull class]] ? NO : YES;
            NSArray *frameArray = [[resultsArray objectAtIndex:i] valueForKey:@"frame"];
            BOOL frameExists = [frameArray isKindOfClass:([NSNull class])] ? NO : YES;
            
            
            if ( !frameExists ) {
                
                // Do Nothing
                
            } else {
                
                if ( sourceURLExists || embedURLExists ) {
                    
                    // Store dashboardEntry attirubutes
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
                    
                    // Check to make sure messages exist
                    [self storeFrame:frame forFrameArray:frameArray];
                    
                }
            }
        }
    }
    
    // Save changes
    [self saveContext:[CoreDataUtility sharedInstance].managedObjectContext];

}

#pragma mark - Private Methods
+ (id)checkIfEntity:(NSString *)entityName
        withIDValue:(NSString *)entityIDValue
           forIDKey:(NSString *)entityIDKey
{
    
    // Create fetch request
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setReturnsObjectsAsFaults:NO];
    
    // Fetch messages data
    NSManagedObjectContext *context = [[CoreDataUtility sharedInstance] managedObjectContext];
    NSEntityDescription *description = [NSEntityDescription entityForName:entityName inManagedObjectContext:context];
    [request setEntity:description];
    
    // Only include objects that exist (i.e. entityIDKey and entityIDValue's must exist)
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", entityIDKey, entityIDValue];
    [request setPredicate:predicate];
    
    // Execute request that returns array with one object, the requested entity
    NSArray *array = [context executeFetchRequest:request error:nil];
    
    if ( [array count] ) {
        return [array objectAtIndex:0];
    }
    
    return [NSEntityDescription insertNewObjectForEntityForName:entityName inManagedObjectContext:context];
}


+ (void)storeFrame:(Frame *)frame forFrameArray:(NSArray *)frameArray
{
    
    NSString *frameID = [NSString coreDataNullTest:[frameArray valueForKey:@"id"]];
    [frame setValue:frameID forKey:kCoreDataFrameID ];
    
    NSString *conversationID = [NSString coreDataNullTest:[frameArray valueForKey:@"conversation_id"]];
    [frame setValue:conversationID forKey:kCoreDataFrameConversationID];
    
    NSString *createdAt = [NSString coreDataNullTest:[frameArray valueForKey:@"created_at"]];
    [frame setValue:createdAt forKey:kCoreDataFrameCreatedAt ];
    
    NSDate *timestamp = [NSDate dataFromBSONstring:frameID];
    [frame setValue:timestamp forKey:kCoreDataFrameTimestamp];
    
    NSString *videoID = [NSString coreDataNullTest:[frameArray valueForKey:@"video_id"]];
    [frame setValue:videoID forKey:kCoreDataFrameVideoID ];
    
    Conversation *conversation = [self checkIfEntity:kCoreDataEntityConversation
                                         withIDValue:conversationID
                                            forIDKey:kCoreDataFrameConversationID];
    
    frame.conversation = conversation;
    [conversation addFrameObject:frame];
    [self storeConversation:conversation fromFrameArray:frameArray];
    
    Video *video = [self checkIfEntity:kCoreDataEntityVideo
                           withIDValue:videoID
                              forIDKey:kCoreDataFrameVideoID];
    
    frame.video = video;
    [video addFrameObject:frame];
    [self storeVideo:video fromFrameArray:frameArray];
    
}

+ (void)storeConversation:(Conversation *)conversation fromFrameArray:(NSArray *)frameArray
{
    
    NSArray *conversationArray = [frameArray valueForKey:@"conversation"];
    
    NSString *conversationID = [NSString coreDataNullTest:[conversationArray valueForKey:@"id"]];
    [conversation setValue:conversationID forKey:kCoreDataConversationID];
    
    // Store dashboard.frame.conversation.messages attributes
    [self storeMessagesFromConversation:conversation withConversationsArray:conversationArray];
    
}

+ (void)storeMessagesFromConversation:(Conversation *)conversation withConversationsArray:(NSArray *)conversationsArray
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

+ (void)storeVideo:(Video *)video fromFrameArray:(NSArray *)frameArray
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
        
        NSLog(@"url: %@", embedURL);
        
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
- (NSManagedObjectModel *)managedObjectModel
{
    
    if ( _managedObjectModel ) {
        return _managedObjectModel;
    }
    
    _managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
    return _managedObjectModel;
    
}

- (NSManagedObjectContext*)managedObjectContext;
{
    
    if ( _managedObjectContext ) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [[CoreDataUtility sharedInstance] persistentStoreCoordinator];
    
    if ( coordinator ){
        
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setUndoManager:nil];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
        [_managedObjectContext setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
    
    }
    
    return _managedObjectContext;
    
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