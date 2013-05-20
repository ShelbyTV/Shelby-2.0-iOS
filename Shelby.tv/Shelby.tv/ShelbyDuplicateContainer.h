//
//  ShelbyDuplicateContainer.h
//  Shelby.tv
//
//  Created by Daniel Spinosa on 5/14/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//
//  Models may conform to this protocol to indicate that they can be a duplicate and/or have child duplicates.
//  Where "duplicate" means another model of the same class referencing the same video.
//
//  Currently Frame and DashboardEntry implement this prototcol using transient CoreData attributes.

#import <Foundation/Foundation.h>

// copied directly from the NSManagedObjected generated code (changing class pointers to id)
@protocol ShelbyDuplicateContainer <NSObject>

@property (nonatomic, retain) id duplicateOf;
@property (nonatomic, retain) NSOrderedSet *duplicates;

- (void)insertObject:(id)value inDuplicatesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromDuplicatesAtIndex:(NSUInteger)idx;
- (void)insertDuplicates:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeDuplicatesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInDuplicatesAtIndex:(NSUInteger)idx withObject:(id)value;
- (void)replaceDuplicatesAtIndexes:(NSIndexSet *)indexes withDuplicates:(NSArray *)values;
- (void)addDuplicatesObject:(id)value;
- (void)removeDuplicatesObject:(id)value;
- (void)addDuplicates:(NSOrderedSet *)values;
- (void)removeDuplicates:(NSOrderedSet *)values;

@end
