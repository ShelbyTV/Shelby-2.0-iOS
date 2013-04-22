//
//  CoreDataUtility.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 10/25/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

extern NSString * const kShelbyNotificationChannelsFinishedSync;
extern NSString * const kShelbyNotificationChannelDataFetched;

@interface CoreDataUtility : NSObject

@property (copy, nonatomic) NSString *videoID;

/// Initialization Methods
- (id)initWithRequestType:(DataRequestType)requestType;

/// Persistance Methods
- (void)saveContext:(NSManagedObjectContext *)context;
- (void)removeOlderVideoFramesForGroupType:(GroupType)groupType andChannelID:(NSString *)channelID;
- (void)removeAllVideoExtractionURLReferences;

/// Storage Methods
- (void)storeUser:(NSDictionary *)resultsDictionary;
- (void)storeStreamEntries:(NSDictionary *)resultsDictionary;
- (void)storeRollFrames:(NSDictionary *)resultsDictionary forGroupType:(GroupType)groupType;
- (void)storeChannels:(NSDictionary *)resultsDictionary;
- (void)storeDashboardEntries:(NSDictionary *)resultsDictionary forDashboard:(NSString *)dashboardID;
- (void)storeFrames:(NSDictionary *)resultsDictionary forChannelRoll:(NSString *)rollID;
- (void)storeFrameInLoggedOutLikes:(Frame *)frame;

/// Fetching Methods
- (User *)fetchUser;
- (NSUInteger)fetchStreamEntryCount;
- (NSUInteger)fetchLikesCount;
- (NSUInteger)fetchPersonalRollCount;
- (NSUInteger)fetchCountForChannelDashboard:(NSString *)channelID;
- (NSUInteger)fetchCountForChannelRoll:(NSString *)rollID;
- (NSMutableArray *)fetchStreamEntries;
- (NSMutableArray *)fetchMoreStreamEntriesAfterDate:(NSDate *)date;
- (NSMutableArray *)fetchLikesEntries;
- (NSMutableArray *)fetchMoreLikesEntriesAfterDate:(NSDate *)date;
- (NSMutableArray *)fetchPersonalRollEntries;
- (NSMutableArray *)fetchMorePersonalRollEntriesAfterDate:(NSDate *)date;
- (NSMutableArray *)fetchDashboardEntriesInDashboard:(NSString *)dashboardID;
- (NSMutableArray *)fetchMoreDashboardEntriesInDashboard:(NSString *)dashboardID afterDate:(NSDate *)date;
- (NSMutableArray *)fetchFramesInChannelRoll:(NSString *)rollID;
- (NSMutableArray *)fetchMoreFramesInChannelRoll:(NSString *)rollID afterDate:(NSDate *)date;
- (NSString *)fetchTextFromFirstMessageInConversation:(Conversation *)conversation;
- (NSMutableArray *)fetchAllChannels;

/// Sync Methods
- (void)syncLoggedOutLikes;
- (void)syncLikes:(NSDictionary *)webResultsDictionary;
- (void)syncPersonalRoll:(NSDictionary *)webResultsDictionary;

@end
