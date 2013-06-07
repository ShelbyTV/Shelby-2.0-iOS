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

// A channel with entriesAreTransient==YES means it has no child Roll or
//Dashboard.  Entries for this channel are determined some other way, and
//it's not our concern how.
//
// Currently used by the home controller to create a DVR channel; the entries
//are determined by the ShelbyDVRController ad hoc
+ (DisplayChannel *)channelForTransientEntriesWithID:(NSString *)channelID
                                               title:(NSString *)title
                                           inContext:(NSManagedObjectContext *)context;

+ (DisplayChannel *)channelForOfflineLikesWithOrder:(NSInteger)order
                                          inContext:(NSManagedObjectContext *)context;

+ (DisplayChannel *)fetchChannelWithRollID:(NSString *)channelID
                                 inContext:(NSManagedObjectContext *)context;
+ (DisplayChannel *)fetchChannelWithDashboardID:(NSString *)dashboardID
                                      inContext:(NSManagedObjectContext *)context;

@property (nonatomic, readonly) BOOL canFetchRemoteEntries;

- (BOOL)canRoll;
- (UIColor *)displayColor;
- (NSString *)displayTitle;

- (BOOL)hasEntityAtIndex:(NSUInteger)idx;

// refreshes this object and it's children, in the current context
- (void)deepRefreshMergeChanges:(BOOL)flag;

@end
