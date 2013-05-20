//
//  Frame.h
//  Shelby.tv
//
//  Created by Daniel Spinosa on 5/14/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Conversation, DashboardEntry, Frame, Roll, User, Video;

@interface Frame : NSManagedObject

@property (nonatomic, retain) NSString * channelID;
@property (nonatomic, retain) NSDate * clientLikedAt;
@property (nonatomic, retain) NSNumber * clientUnsyncedLike;
@property (nonatomic, retain) NSString * conversationID;
@property (nonatomic, retain) NSString * createdAt;
@property (nonatomic, retain) NSString * creatorID;
@property (nonatomic, retain) NSString * frameID;
@property (nonatomic, retain) NSNumber * isStoredForLoggedOutUser;
@property (nonatomic, retain) NSString * rollID;
@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) NSString * videoID;
@property (nonatomic, retain) Conversation *conversation;
@property (nonatomic, retain) User *creator;
@property (nonatomic, retain) NSSet *dashboardEntry;
@property (nonatomic, retain) Frame *duplicateOf;
@property (nonatomic, retain) NSOrderedSet *duplicates;
@property (nonatomic, retain) Roll *roll;
@property (nonatomic, retain) Video *video;
@end

@interface Frame (CoreDataGeneratedAccessors)

- (void)addDashboardEntryObject:(DashboardEntry *)value;
- (void)removeDashboardEntryObject:(DashboardEntry *)value;
- (void)addDashboardEntry:(NSSet *)values;
- (void)removeDashboardEntry:(NSSet *)values;

- (void)insertObject:(Frame *)value inDuplicatesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromDuplicatesAtIndex:(NSUInteger)idx;
- (void)insertDuplicates:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeDuplicatesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInDuplicatesAtIndex:(NSUInteger)idx withObject:(Frame *)value;
- (void)replaceDuplicatesAtIndexes:(NSIndexSet *)indexes withDuplicates:(NSArray *)values;
- (void)addDuplicatesObject:(Frame *)value;
- (void)removeDuplicatesObject:(Frame *)value;
- (void)addDuplicates:(NSOrderedSet *)values;
- (void)removeDuplicates:(NSOrderedSet *)values;
@end
