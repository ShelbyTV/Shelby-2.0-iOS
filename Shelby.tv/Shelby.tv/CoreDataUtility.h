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
- (void)removeOlderVideoFramesForCategoryType:(CategoryType)categoryType;
- (void)removeAllVideoExtractionURLReferences;

/// Storage Methods
- (void)storeUser:(NSDictionary *)resultsDictionary;
- (void)storeStream:(NSDictionary *)resultsDictionary;
- (void)storeRollFrames:(NSDictionary *)resultsDictionary;
- (void)storeChannels:(NSDictionary *)resultsDictionary;
- (void)storeRollFrames:(NSDictionary *)resultsDictionary forChannel:(NSString*)channelID;

/// Fetching Methods
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
- (NSMutableArray *)fetchAllChannels;
- (NSMutableArray *)fetchFramesInChannel:(NSString *)channelID;


/// Sync Methods
- (void)syncLikes:(NSDictionary *)webResuhanneltsDictionary;
- (void)syncPersonalRoll:(NSDictionary *)webResultsDictionary;


@end
