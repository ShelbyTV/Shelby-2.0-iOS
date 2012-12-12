//
//  CoreDataUtility.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 10/25/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

@interface CoreDataUtility : NSObject

@property (strong, nonatomic, readonly) NSManagedObjectContext *context;
@property (copy, nonatomic) NSString *videoID;

/// Public Methods
// Initialization Methods
- (id)initWithRequestType:(DataRequestType)requestType;

// Persistance Methods
- (void)saveContext:(NSManagedObjectContext*)context;
- (void)dumpAllData;

// Public Storage Methods
- (void)storeUser:(NSDictionary*)resultsDictionary;
- (void)storeStream:(NSDictionary*)resultsDictionary;
- (void)storeRollFrames:(NSDictionary*)resultsDictionary;

// Public Fetching Methods
- (User*)fetchUser;
- (NSMutableArray*)fetchStreamEntries;
- (NSMutableArray*)fetchQueueRollEntries;
- (NSMutableArray*)fetchPersonalRollEntries;

@end