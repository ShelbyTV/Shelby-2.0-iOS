//
//  CoreDataUtility.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 10/25/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

@interface CoreDataUtility : NSObject

@property (copy, nonatomic) NSString *videoID;

/// Initialization Methods
- (id)initWithRequestType:(DataRequestType)requestType;

/// Persistance Methods
- (void)saveContext:(NSManagedObjectContext *)context;
- (void)removeOlderVideoFramesForGroupType:(GroupType)groupType andCategoryID:(NSString *)categoryID;
- (void)removeAllVideoExtractionURLReferences;

/// Storage Methods
- (void)storeUser:(NSDictionary *)resultsDictionary;
- (void)storeStream:(NSDictionary *)resultsDictionary;
- (void)storeRollFrames:(NSDictionary *)resultsDictionary forGroupType:(GroupType)groupType;
- (void)storeCategories:(NSDictionary *)resultsDictionary;
- (void)storeFrames:(NSDictionary *)resultsDictionary forCategoryChannel:(NSString *)channelID;
- (void)storeFrames:(NSDictionary *)resultsDictionary forCategoryRoll:(NSString *)rollID;
- (void)storeFrameInLoggedOutLikes:(Frame *)frame;

/// Fetching Methods
- (User *)fetchUser;

- (NSUInteger)fetchStreamCount;
- (NSUInteger)fetchLikesCount;
- (NSUInteger)fetchPersonalRollCount;
- (NSUInteger)fetchCountForCategoryChannel:(NSString *)channelID;
- (NSUInteger)fetchCountForCategoryRoll:(NSString *)rollID;

- (NSMutableArray *)fetchStreamEntries;
- (NSMutableArray *)fetchMoreStreamEntriesAfterDate:(NSDate *)date;

- (NSMutableArray *)fetchLikesEntries;
- (NSMutableArray *)fetchMoreLikesEntriesAfterDate:(NSDate *)date;

- (NSMutableArray *)fetchPersonalRollEntries;
- (NSMutableArray *)fetchMorePersonalRollEntriesAfterDate:(NSDate *)date;

- (NSMutableArray *)fetchFramesInCategoryChannel:(NSString *)channelID;
- (NSMutableArray *)fetchMoreFramesInCategoryChannel:(NSString *)channelID afterDate:(NSDate *)date;
- (NSMutableArray *)fetchFramesInCategoryRoll:(NSString *)rollID;
- (NSMutableArray *)fetchMoreFramesInCategoryRoll:(NSString *)rollID afterDate:(NSDate *)date;

- (NSString *)fetchTextFromFirstMessageInConversation:(Conversation *)conversation;
- (NSMutableArray *)fetchAllCategories;

/// Sync Methods
- (void)syncLoggedOutLikes;
- (void)syncLikes:(NSDictionary *)webResuhanneltsDictionary;
- (void)syncPersonalRoll:(NSDictionary *)webResultsDictionary;

@end
