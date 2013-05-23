//
//  DeduplicationUtility.m
//  Shelby.tv
//
//  Created by Daniel Spinosa on 5/13/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "DeduplicationUtility.h"
#import "ShelbyDuplicateContainer.h"
#import "ShelbyVideoContainer.h"

@implementation DeduplicationUtility

+ (NSArray *)deduplicatedCopy:(NSArray *)entries
{
    //this is the same as appending to en empty array
    //b/c "append" takes into account possible duplicates in the newEntries array
    NSMutableArray *indexPathsForInsert, *indexPathsForDelete, *indexPathsForReload;
    NSArray *results = [DeduplicationUtility deduplicatedArrayByAppending:entries
                                                           toDedupedArray:@[]
                                                                didInsert:&indexPathsForInsert
                                                                didDelete:&indexPathsForDelete
                                                                didUpdate:&indexPathsForReload];
    return results;
}

+ (NSArray *)deduplicatedArrayByAppending:(NSArray *)newEntries
                           toDedupedArray:(NSArray *)baseArray
                                didInsert:(NSArray *__autoreleasing *)insertedIndexPaths
                                didDelete:(NSArray *__autoreleasing *)deletedIndexPaths
                                didUpdate:(NSArray *__autoreleasing *)updatedIndexPaths
{
    NSMutableArray *resultArray = [baseArray mutableCopy];
    NSMutableArray *inserted = [@[] mutableCopy];
    NSMutableArray *updated = [@[] mutableCopy];
    NSMutableSet *updatedDupeParents = [NSMutableSet set];
    id<ShelbyDuplicateContainer> dupeParent;
    NSInteger indexOfUpdatedEntryInBaseArray;
    
    // For newEntries, in order, find first dupe-parent in the resultArray and add the new entry as a duplicate child
    // (NB: searching resultArray b/c the newEntries could have dupes within them)
    // If no dupe-parent is found, simply append to the result array
    for (id<ShelbyDuplicateContainer, ShelbyVideoContainer> newEntry in newEntries) {
        dupeParent = [DeduplicationUtility firstObjectInArray:resultArray
                                        containingSameVideoAs:newEntry];
        if(dupeParent){
            [DeduplicationUtility addDuplicateChild:newEntry toParent:dupeParent flatteningHierarchy:NO];
            indexOfUpdatedEntryInBaseArray = [baseArray indexOfObject:dupeParent];
            if(indexOfUpdatedEntryInBaseArray != NSNotFound && ![updatedDupeParents containsObject:dupeParent]){
                [updatedDupeParents addObject:dupeParent];
                [updated addObject:[NSIndexPath indexPathForItem:indexOfUpdatedEntryInBaseArray inSection:0]];
            }
        } else {
            [resultArray addObject:newEntry];
            [inserted addObject:[NSIndexPath indexPathForItem:[resultArray count]-1 inSection:0]];
        }
    }
    
    *insertedIndexPaths = inserted;
    *deletedIndexPaths = @[];
    *updatedIndexPaths = updated;
    return resultArray;
}

+ (NSArray *)deduplicatedArrayByPrepending:(NSArray *)newEntries
                            toDedupedArray:(NSArray *)baseArray
                                 didInsert:(NSArray *__autoreleasing *)insertedIndexPaths
                                 didDelete:(NSArray *__autoreleasing *)deletedIndexPaths
                                 didUpdate:(NSArray *__autoreleasing *)updatedIndexPaths
{
    NSMutableArray *resultArray = [baseArray mutableCopy];
    NSMutableArray *inserted = [@[] mutableCopy];
    NSMutableArray *deleted = [@[] mutableCopy];
    id<ShelbyDuplicateContainer> dupeChild;
    NSInteger indexOfRemovedEntryInBaseArray;
    
    // 0) pre-Deduplicate newEntries to simplify insert/delete index paths
    newEntries = [DeduplicationUtility deduplicatedCopy:newEntries];
    
    // For newEntries, in reverse order...
    for(id<ShelbyDuplicateContainer, ShelbyVideoContainer> newEntry in [newEntries reverseObjectEnumerator]){
        dupeChild = [DeduplicationUtility firstObjectInArray:resultArray
                                       containingSameVideoAs:newEntry];
        // 1) Prepend newEntry to results array and create an inserted index path
        [resultArray insertObject:newEntry atIndex:0];
        [inserted addObject:[NSIndexPath indexPathForItem:[inserted count] inSection:0]];
        // 2) If we found a dupe-child in the resultArray, add it to the newEntry's duplicates (flattening hierarchy)
        //    remove it from the resultArray, and create a deleted index path based on index in baseArray
        if(dupeChild){
            [DeduplicationUtility addDuplicateChild:dupeChild toParent:newEntry flatteningHierarchy:YES];
            
            NSUInteger idxToRemove = [resultArray indexOfObject:dupeChild];
            STVAssert(idxToRemove != NSNotFound, @"didn't expect dupeChild to dissapear since it was found a few lines ago!");
            [resultArray removeObjectAtIndex:idxToRemove];
            
            indexOfRemovedEntryInBaseArray = [baseArray indexOfObject:dupeChild];
            STVAssert(indexOfRemovedEntryInBaseArray != NSNotFound, @"update will fail b/c of imbalance! how isn't dupeChild in baseArray?");
            [deleted addObject:[NSIndexPath indexPathForItem:indexOfRemovedEntryInBaseArray inSection:0]];
        }
    }
    
    *insertedIndexPaths = inserted;
    *deletedIndexPaths = deleted;
    *updatedIndexPaths = @[];
    return resultArray;
}

+ (void) addDuplicateChild:(id<ShelbyDuplicateContainer>)dupeChild
                  toParent:(id<ShelbyDuplicateContainer>)dupeParent
       flatteningHierarchy:(BOOL)flatten
{
    dupeChild.duplicateOf = dupeParent;
    if(flatten && dupeChild.duplicates && [dupeChild.duplicates count]){
        for (id<ShelbyDuplicateContainer> child in dupeChild.duplicates) {
            child.duplicateOf = dupeParent;
        }
    }
}

+ (id<ShelbyDuplicateContainer>) firstObjectInArray:(NSArray *)searchArray
                              containingSameVideoAs:(id<ShelbyVideoContainer>)targetVideoContainer
{
    //there are some array built-ins that could be used, but this seems straightforward enough
    //OPTIMIZE but maybe those array built-ins are quicker?
    Video *targetVideo = [targetVideoContainer containedVideo];
    for (id<ShelbyDuplicateContainer, ShelbyVideoContainer> vc in searchArray) {
        if([[vc containedVideo] isEqual:targetVideo]){
            return vc;
        }
    }
    return nil;
}

@end
