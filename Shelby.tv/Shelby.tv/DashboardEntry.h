//
//  DashboardEntry.h
//  Shelby.tv
//
//  Created by Daniel Spinosa on 5/14/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Dashboard, DashboardEntry, Frame;

@interface DashboardEntry : NSManagedObject

@property (nonatomic, retain) NSString * dashboardEntryID;
@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) Dashboard *dashboard;
@property (nonatomic, retain) DashboardEntry *duplicateOf;
@property (nonatomic, retain) NSOrderedSet *duplicates;
@property (nonatomic, retain) Frame *frame;
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
