//
//  DisplayChannel+Helper.h
//  Shelby.tv
//
//  Created by Daniel Spinosa on 5/1/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "DisplayChannel.h"

@interface DisplayChannel (Helper)

//sorted by order
//return nil on error
+ (NSArray *)allChannelsInContext:(NSManagedObjectContext *)context;

//find or create DisplayChannel, will find or create underlying Roll
//return nil on error
//NB: does not save context
+ (DisplayChannel *)channelForRollDictionary:(NSDictionary *)rollDict
                                   withOrder:(NSInteger)order
                                   inContext:(NSManagedObjectContext *)context;

//find or create DisplayChannel, will find or create underlying Dashboard
//return nil on error
//NB: does not save context
+ (DisplayChannel *)channelForDashboardDictionary:(NSDictionary *)dashboardDict
                                        withOrder:(NSInteger)order
                                        inContext:(NSManagedObjectContext *)context;

+ (DisplayChannel *)channelForOfflineLikesWithOrder:(NSInteger)order
                                          inContext:(NSManagedObjectContext *)context;

+ (DisplayChannel *)userChannelForDashboardDictionary:(NSDictionary *)dictionary
                                               withID:(NSString *)channelID
                                                withOrder:(NSInteger)order
                                                inContext:(NSManagedObjectContext *)context;

+ (DisplayChannel *)userChannelForRollDictionary:(NSDictionary *)dictionary
                                          withID:(NSString *)channelID
                                       withOrder:(NSInteger)order
                                       inContext:(NSManagedObjectContext *)context;

+ (DisplayChannel *)channelForRollID:(NSString *)channelID
                           inContext:(NSManagedObjectContext *)context;
+ (DisplayChannel *)channelForDashboardID:(NSString *)dashboardID
                                inContext:(NSManagedObjectContext *)context;

@property (nonatomic, readonly) BOOL canFetchRemoteEntries;

- (BOOL)canRoll;
- (UIColor *)displayColor;
- (NSString *)displayTitle;

- (BOOL)hasEntityAtIndex:(NSUInteger)idx;

// refreshes this object and it's children, in the current context
- (void)deepRefreshMergeChanges:(BOOL)flag;

@end
