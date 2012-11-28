//
//  CoreDataUtility.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 10/25/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

@interface CoreDataUtility : NSObject

@property (strong, nonatomic, readonly) NSManagedObjectContext *context;

/// Public Methods

// Initialization Methods
- (id)initWithRequestType:(DataRequestType)requestType;

// Persistance Methods
- (void)saveContext:(NSManagedObjectContext*)context;
- (void)dumpAllData;

// Storage Methods
- (void)storeUser:(NSDictionary*)resultsDictionary;
- (void)storeStream:(NSDictionary*)resultsDictionary;
- (void)storeRollFrames:(NSDictionary*)resultsDictionary;

// Fetching Methods
- (User*)fetchUser;
- (NSMutableArray*)fetchStreamEntries;
- (NSArray*)fetchQueueRollEntries;
- (NSArray*)fetchPersonalRollEntries;

@end