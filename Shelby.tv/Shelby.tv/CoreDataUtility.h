//
//  CoreDataUtility.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 10/25/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

@interface CoreDataUtility : NSObject

@property (copy, nonatomic) NSString *videoID;

/// Public Methods
// Initialization Methods
- (id)initWithRequestType:(DataRequestType)requestType;

// Public Persistance Methods
- (void)removeAllVideoExtractionURLReferences;
- (void)saveContext:(NSManagedObjectContext *)context;

// Public Storage Methods
- (void)storeUser:(NSDictionary *)resultsDictionary;
- (void)storeStream:(NSDictionary *)resultsDictionary;
- (void)storeRollFrames:(NSDictionary *)resultsDictionary;
- (void)storeGroupsAndGroupRolls:(NSDictionary *)resultsDictionary;

// Public Fetching Methods
- (User *)fetchUser;
- (NSUInteger)fetchStreamCount;
- (NSUInteger)fetchLikesCount;
- (NSUInteger)fetchPersonalRollCount;
- (NSMutableArray *)fetchStreamEntries;
- (NSMutableArray *)fetchMoreStreamEntriesAfterDate:(NSDate *)date;
- (NSMutableArray *)fetchLikesEntries;
- (NSMutableArray *)fetchMoreLikesEntriesAfterDate:(NSDate *)date;
- (NSMutableArray *)fetchPersonalRollEntries;
- (NSMutableArray *)fetchMorePersonalRollEntriesAfterDate:(NSDate *)date;
- (NSString *)fetchTextFromFirstMessageInConversation:(Conversation *)conversation;

// Sync Methods
- (void)syncLikes:(NSDictionary *)webResultsDictionary;
- (void)syncPersonalRoll:(NSDictionary *)webResultsDictionary;


@end
