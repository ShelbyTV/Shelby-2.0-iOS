//
//  DashboardEntry.h
//  Shelby.tv
//
//  Created by Daniel Spinosa on 6/4/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class DVREntry, Dashboard, DashboardEntry, Frame;

@interface DashboardEntry : NSManagedObject

@property (nonatomic, retain) NSString * dashboardEntryID;
@property (nonatomic, retain) Dashboard *dashboard;
@property (nonatomic, retain) DashboardEntry *duplicateOf;
@property (nonatomic, retain) NSOrderedSet *duplicates;
@property (nonatomic, retain) Frame *frame;
@property (nonatomic, retain) DVREntry *dvrEntry;
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
