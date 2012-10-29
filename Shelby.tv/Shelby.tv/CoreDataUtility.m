//
//  CoreDataUtility.m
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 10/25/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

#import "CoreDataUtility.h"
#import "CoreDataSingleton.h"

@interface CoreDataUtility ()

- (id)checkIfEntity:(NSString *)entityName
        withIDValue:(NSString *)entityIDValue
           forIDKey:(NSString *)entityIDKey
        withContext:(NSManagedObjectContext*)context;

- (void)storeFrame:(Frame*)frame forFrameArray:(NSArray *)frameArray;
- (void)storeConversation:(Conversation *)conversation fromFrameArray:(NSArray *)frameArray;
- (void)storeMessagesFromConversation:(Conversation *)conversation withConversationsArray:(NSArray *)conversationsArray;
- (void)storeVideo:(Video *)video fromFrameArray:(NSArray *)frameArray;

@end

@implementation CoreDataUtility

#pragma mark - Public Methods
- (NSManagedObjectContext*)createContext;
{
    
    NSPersistentStoreCoordinator *coordinator = [[CoreDataSingleton sharedInstance] persistentStoreCoordinator];
    
    NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [context setUndoManager:nil];
    [context setPersistentStoreCoordinator:coordinator];
    
    if ( [NSThread isMainThread] ) {
        [context setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
        NSLog(@"Main Thread");
    } else {
        [context setMergePolicy:NSMergeByPropertyStoreTrumpMergePolicy];
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"Background Thread");
        });
    }


    return context;
}


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
                DLog(@"Core Data Updated!");
            }
        }

}

- (void)dumpAllData
{
    
    NSPersistentStoreCoordinator *coordinator =  [[CoreDataSingleton sharedInstance] persistentStoreCoordinator];
    NSPersistentStore *store = [[coordinator persistentStores] objectAtIndex:0];
    [[NSFileManager defaultManager] removeItemAtURL:store.URL error:nil];
    [coordinator removePersistentStore:store error:nil];
    
}

- (void)storeStream:(NSDictionary *)resultsDictionary
{
    NSArray *resultsArray = [resultsDictionary objectForKey:@"result"];
    
    NSManagedObjectContext *context = [self createContext];
    
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
                                                forIDKey:kCoreDataStreamID
                                             withContext:context];
                    
                    NSString *streamID = [NSString coreDataNullTest:[[resultsArray objectAtIndex:i] valueForKey:@"id"]];
                    [stream setValue:streamID forKey:kCoreDataStreamID];
                    
                    NSDate *timestamp = [NSDate dataFromBSONstring:streamID];
                    [stream setValue:timestamp forKey:kCoreDataStreamTimestamp];
                    
                    Frame *frame = [self checkIfEntity:kCoreDataEntityFrame
                                           withIDValue:[frameArray valueForKey:@"id"]
                                              forIDKey:kCoreDataFrameID
                                        withContext:[stream managedObjectContext]];
                    stream.frame = frame;
                    
                    // Check to make sure messages exist
                    [self storeFrame:frame forFrameArray:frameArray];
                    
                    [context refreshObject:stream mergeChanges:YES];
                }
            }
        }
    }
    
    [self saveContext:context];
    
}

#pragma mark - Private Methods
- (id)checkIfEntity:(NSString *)entityName
        withIDValue:(NSString *)entityIDValue
           forIDKey:(NSString *)entityIDKey
        withContext:(NSManagedObjectContext *)context
{
    
    // Create fetch request
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setReturnsObjectsAsFaults:NO];
    
    // Fetch messages data
    if ( !context ) {
        context = [self createContext];
    }
    
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


- (void)storeFrame:(Frame *)frame forFrameArray:(NSArray *)frameArray
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
                                            forIDKey:kCoreDataFrameConversationID
                                         withContext:[frame managedObjectContext]];
    
    frame.conversation = conversation;
    [conversation addFrameObject:frame];
    [self storeConversation:conversation fromFrameArray:frameArray];
    
    Video *video = [self checkIfEntity:kCoreDataEntityVideo
                           withIDValue:videoID
                              forIDKey:kCoreDataFrameVideoID
                           withContext:[frame managedObjectContext]];
    
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
                                        forIDKey:kCoreDataMessagesID
                              withContext:[conversation managedObjectContext]];
        
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

@end