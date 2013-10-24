//
//  DeduplicationUtility.m
//  Shelby.tv
//
//  Created by Daniel Spinosa on 5/13/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "DeduplicationUtility.h"
#import "ShelbyDuplicateContainer.h"
#import "ShelbyModel.h"
#import "ShelbyVideoContainer.h"

@implementation DeduplicationUtility

+ (NSArray *)deduplicatedCopy:(NSArray *)entries
{
    NSMutableArray *indexPathsForInsert, *indexPathsForDelete, *indexPathsForReload;
    NSArray *results = [DeduplicationUtility deduplicatedArrayByMerging:entries intoDeduped:@[]
                                                              didInsert:&indexPathsForInsert
                                                              didDelete:&indexPathsForDelete
                                                              didUpdate:&indexPathsForReload];
    return results;
}

+ (NSArray *)combineAndSort:(NSArray *)arr1 with:(NSArray *)arr2
{
    NSArray *combinedEntities = [arr1 arrayByAddingObjectsFromArray:arr2];
    NSArray *sortedCombinedEntities = [combinedEntities sortedArrayUsingComparator:^NSComparisonResult(id<ShelbyModel> obj1, id<ShelbyModel> obj2) {
        //reverse order to get descending (ie. newest to oldest)
        return [[obj2 shelbyID] compare:[obj1 shelbyID]];
    }];
    return sortedCombinedEntities;
}

+ (NSArray *)deduplicatedArrayByMerging:(NSArray *)flatNewEntities 
                            intoDeduped:(NSArray *)dedupedBaseEntities 
                              didInsert:(NSArray *__autoreleasing *)insertedIndexPaths 
                              didDelete:(NSArray *__autoreleasing *)deletedIndexPaths 
                              didUpdate:(NSArray *__autoreleasing *)updatedIndexPaths
{
    NSMutableArray *mergedDeduplicatedEntities = [@[] mutableCopy];

    // combine everything into one giant array (do not flatten base) and sort that giant array by ShelbyID descending
    NSArray *sortedCombinedEntities = [DeduplicationUtility combineAndSort:flatNewEntities with:dedupedBaseEntities];

    //create results array
    for (id<ShelbyDuplicateContainer, ShelbyVideoContainer>entity in sortedCombinedEntities) {
        //should it just be added as a dupe child of a newer (ie. already in result set) entity?
        id<ShelbyDuplicateContainer>dupeParent = [self firstObjectInArray:mergedDeduplicatedEntities containingSameVideoAs:entity];
        if (dupeParent) {
            //yes: it's just a dupe child
            [DeduplicationUtility addDuplicateChild:entity toParent:dupeParent flatteningHierarchy:YES];
        } else {
            //no: it stands alone (tho it may dupe children of its own, later); add to results
            [mergedDeduplicatedEntities addObject:entity];
        }
    }

    // results are done, now we use that to to figure out the insert/delete/update crap...

    NSMutableArray *inserted = [@[] mutableCopy];
    NSMutableArray *updated = [@[] mutableCopy];
    NSMutableArray *deleted = [@[] mutableCopy];
    for (id<ShelbyDuplicateContainer, ShelbyVideoContainer>entity in mergedDeduplicatedEntities) {
        if ([dedupedBaseEntities containsObject:entity]) {
            if (entity.duplicates && [entity.duplicates count]) {
                //this was in the original array it and has duplicates
                //may have been updated (or may not)... telling caller to update just to be safe
                [updated addObject:[NSIndexPath indexPathForItem:[dedupedBaseEntities indexOfObject:entity] inSection:0]];
            }
        } else {
            //this was not in the original array, it's an insert
            //index path is "where you would like it to appear" in new array, relative to original array
            //if original array was [C E F] and I add [A B D] resulting in [A B C D E F], I am inserting at 0, 1 and 3
            [inserted addObject:[NSIndexPath indexPathForItem:[mergedDeduplicatedEntities indexOfObject:entity] inSection:0]];

            //if this insert has dupe children, may need to account for them
            for (id<ShelbyDuplicateContainer, ShelbyVideoContainer>dupeChild in entity.duplicates) {
                if ([dedupedBaseEntities containsObject:dupeChild]) {
                    //this dupe child was in the original array, it's now a dupe of an inserted element... need to "delete" the original
                    [deleted addObject:[NSIndexPath indexPathForItem:[dedupedBaseEntities indexOfObject:dupeChild] inSection:0]];
                }
            }
        }
    }

    *insertedIndexPaths = inserted;
    *updatedIndexPaths = updated;
    *deletedIndexPaths = deleted;
    return mergedDeduplicatedEntities;
}

+ (void) addDuplicateChild:(id<ShelbyDuplicateContainer>)dupeChild
                  toParent:(id<ShelbyDuplicateContainer>)dupeParent
       flatteningHierarchy:(BOOL)flatten
{
    //TODO: figure out how an entity can be set as a duplicate of itself and fix that.
    STVDebugAssert(dupeChild != dupeParent, @"BUG: dupeChild == dupeParent: %@", dupeParent);
    dupeChild.duplicateOf = dupeParent;
    if(flatten && dupeChild.duplicates && [dupeChild.duplicates count]){
        NSArray *duplicatesArray = [[dupeChild.duplicates array] copy];
        for (NSUInteger i = 0; i < [duplicatesArray count]; i++) {
            id<ShelbyDuplicateContainer> child = duplicatesArray[i];
            STVDebugAssert(child != dupeParent, @"BUG: child == dupeParent: %@", dupeParent);
            child.duplicateOf = dupeParent;
        }
    }
}

+ (id<ShelbyDuplicateContainer>) firstObjectInArray:(NSArray *)searchArray
                              containingSameVideoAs:(id<ShelbyVideoContainer>)targetVideoContainer
{
    //there are some array built-ins that could be used, but this seems straightforward enough
    Video *targetVideo = [targetVideoContainer containedVideo];
    for (id<ShelbyDuplicateContainer, ShelbyVideoContainer> vc in searchArray) {
        if([[vc containedVideo] isEqual:targetVideo]){
            return vc;
        }
    }
    return nil;
}

@end
