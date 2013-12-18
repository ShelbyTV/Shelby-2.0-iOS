//
//  DashboardEntry.h
//  Shelby.tv
//
//  Created by Keren on 12/18/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class DVREntry, Dashboard, DashboardEntry, Frame, User;

@interface DashboardEntry : NSManagedObject

@property (nonatomic, retain) NSNumber * action;
@property (nonatomic, retain) NSString * dashboardEntryID;
@property (nonatomic, retain) NSString * sourceFrameCreatorNickname;
@property (nonatomic, retain) NSString * sourceVideoTitle;
@property (nonatomic, retain) Dashboard *dashboard;
@property (nonatomic, retain) DashboardEntry *duplicateOf;
@property (nonatomic, retain) NSOrderedSet *duplicates;
@property (nonatomic, retain) DVREntry *dvrEntry;
@property (nonatomic, retain) Frame *frame;
@property (nonatomic, retain) User *actor;
@end

@interface DashboardEntry (CoreDataGeneratedAccessors)

- (void)insertObject:(DashboardEntry *)value inDuplicatesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromDuplicatesAtIndex:(NSUInteger)idx;
- (void)insertDuplicates:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeDuplicatesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInDuplicatesAtIndex:(NSUInteger)idx withObject:(DashboardEntry *)value;
- (void)replaceDuplicatesAtIndexes:(NSIndexSet *)indexes withDuplicates:(NSArray *)values;
- (void)addDuplicatesObject:(DashboardEntry *)value;
- (void)removeDuplicatesObject:(DashboardEntry *)value;
- (void)addDuplicates:(NSOrderedSet *)values;
- (void)removeDuplicates:(NSOrderedSet *)values;
@end
