//
//  CoreDataUtility.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 10/25/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CoreDataUtility : NSObject

@property (strong, nonatomic, readonly) NSManagedObjectModel *managedObjectModel;
@property (strong, nonatomic, readonly) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

// Public Methods
+ (void)saveContext:(NSManagedObjectContext *)context;
+ (void)dumpAllData;
+ (void)storeStream:(NSDictionary *)resultsDictionary;
+ (void)storeFrame:(Frame*)frame forFrameArray:(NSArray *)frameArray;
+ (void)storeConversation:(Conversation *)conversation fromFrameArray:(NSArray *)frameArray;
+ (void)storeMessagesFromConversation:(Conversation *)conversation withConversationsArray:(NSArray *)conversationsArray;
+ (void)storeVideo:(Video *)video fromFrameArray:(NSArray *)frameArray;

// Singleton Methods
+ (CoreDataUtility*)sharedInstance;

@end