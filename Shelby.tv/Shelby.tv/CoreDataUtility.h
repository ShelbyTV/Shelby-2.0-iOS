//
//  CoreDataUtility.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 10/25/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

extern NSString * const kShelbyNotificationCategoriesFinishedSync;
extern NSString * const kShelbyNotificationCategoryFramesFetched;

@interface CoreDataUtility : NSObject

@property (copy, nonatomic) NSString *videoID;

/// Initialization Methods
- (id)initWithRequestType:(DataRequestType)requestType;

/// Persistance Methods
- (void)saveContext:(NSManagedObjectContext *)context;
- (void)removeOlderVideoFramesForGroupType:(GroupType)groupType andCategoryID:(NSString *)categoryID;
- (void)removeAllVideoExtractionURLReferences;

/// Storage Methods
// User
- (void)storeUser:(NSDictionary *)resultsDictionary;

// Stream
- (void)storeStreamEntries:(NSDictionary *)resultsDictionary;

// Rolls
- (void)storeRollFrames:(NSDictionary *)resultsDictionary forGroupType:(GroupType)groupType;

// Channels
- (void)storeCategories:(NSDictionary *)resultsDictionary;
- (void)storeDashboardEntries:(NSDictionary *)resultsDictionary forDashboard:(NSString *)dashboardID;
- (void)storeFrames:(NSDictionary *)resultsDictionary forCategoryRoll:(NSString *)rollID;

// Logged-Out Likes
- (void)storeFrameInLoggedOutLikes:(Frame *)frame;

/// Fetching Methods
- (User *)fetchUser;

- (NSUInteger)fetchStreamEntryCount;
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

- (NSMutableArray *)fetchDashboardEntriesInDashboard:(NSString *)dashboardID;
- (NSMutableArray *)fetchMoreDashboardEntriesInDashboard:(NSString *)dashboardID afterDate:(NSDate *)date;
- (NSMutableArray *)fetchFramesInCategoryRoll:(NSString *)rollID;
- (NSMutableArray *)fetchMoreFramesInCategoryRoll:(NSString *)rollID afterDate:(NSDate *)date;

- (NSString *)fetchTextFromFirstMessageInConversation:(Conversation *)conversation;
- (NSMutableArray *)fetchAllChannels;

/// Sync Methods
- (void)syncLoggedOutLikes;
- (void)syncLikes:(NSDictionary *)webResuhanneltsDictionary;
- (void)syncPersonalRoll:(NSDictionary *)webResultsDictionary;

@end
