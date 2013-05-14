//
//  DeduplicationUtility.h
//  Shelby.tv
//
//  Created by Daniel Spinosa on 5/13/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//
//  Works on arrays of ShelbyDeduplicatableModel that are ShelbyVideoContainer
//  (ie. Frame or DashboardEntry).
//
//  Returns adjusted arrays where only the first appearance of an entity
//  with a given video is present.  Subsequent appearances of entities
//  with that same video are added to the duplicates array of the first
//  (ie. lower array index) entity.
//
//  These algorithms have NOT been optimized.
//  They were written for clarity and maintainability.
//  So far, performance seems acceptable.

#import <Foundation/Foundation.h>

@interface DeduplicationUtility : NSObject

+ (NSArray *)deduplicatedCopy:(NSArray *)entries;

//  All index paths are relative to the original, baseArray
//
//  You should therefore use performBathUpdates:completion: to apply these udpates.
+ (NSArray *)deduplicatedArrayByAppending:(NSArray *)newEntries
                           toDedupedArray:(NSArray *)baseArray
                                didInsert:(NSArray **)insertedIndexPaths
                                didDelete:(NSArray **)deletedIndexPaths
                                didUpdate:(NSArray **)updatedIndexPaths;

//  All index paths are relative to the original, baseArray.
//
//  deletedIndexPaths indicate entities that have been subsumed as
//  duplicate-children of a newly prepended entity.
//
//  You should therefore use performBathUpdates:completion: to apply these udpates.
+ (NSArray *)deduplicatedArrayByPrepending:(NSArray *)newEntries
                            toDedupedArray:(NSArray *)baseArray
                                 didInsert:(NSArray **)insertedIndexPaths
                                 didDelete:(NSArray **)deletedIndexPaths
                                 didUpdate:(NSArray **)updatedIndexPaths;

@end
