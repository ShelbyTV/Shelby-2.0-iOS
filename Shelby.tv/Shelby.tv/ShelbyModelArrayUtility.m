//
//  ShelbyModelArrayUtility.m
//  Shelby.tv
//
//  Created by Daniel Spinosa on 9/3/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyModelArrayUtility.h"
#import "ShelbyModel.h"

@interface ShelbyModelArrayUtility()
//internal data structures (given during initialization)
@property (nonatomic, strong) NSArray *possiblyNewEntities;
@property (nonatomic, strong) NSArray *existingEntities;
//external API with results of computation
@property (nonatomic, strong) NSArray *actuallyNewEntities;
@property (nonatomic, assign) BOOL actuallyNewEntitiesShouldBeAppended;
@property (nonatomic, assign) BOOL gapAfterNewEntitiesBeforeExistingEntities;
@end

@implementation ShelbyModelArrayUtility

+ (id)determineHowToMergePossiblyNew:(NSArray *)possiblyNewEntities intoExisting:(NSArray *)existingEntities
{
    STVAssert(possiblyNewEntities && existingEntities, @"arguments must be two NSArray (may be empty, not nil)");
    ShelbyModelArrayUtility *util = [[ShelbyModelArrayUtility alloc] init];
    util.possiblyNewEntities = possiblyNewEntities;
    util.existingEntities = existingEntities;
    [util determineWhatsActuallyNew];
    return util;
}

- (void)determineWhatsActuallyNew
{
    //gap can only possibly be true in non-trival merge (and then only in one case as described below)
    self.gapAfterNewEntitiesBeforeExistingEntities = NO;

    //no new entries
    if ([self.possiblyNewEntities count] == 0) {
        self.actuallyNewEntities = @[];
        return;
    }

    //only new entries
    if ([self.existingEntities count] == 0) {
        self.actuallyNewEntities = self.possiblyNewEntities;
        self.actuallyNewEntitiesShouldBeAppended = NO;
        return;
    }

    // non-trivial merge...
    // 1) find subset of possibly new entities that are actually NEW
    self.actuallyNewEntities = [self orderedElementsOf:self.possiblyNewEntities notFoundIn:self.existingEntities];

    if ([self.actuallyNewEntities count] == 0) {
        return;
    }

    // 2) if we have any new entities with an ID > smallest exisitng entity ID, that's a pre-pend
    //    (IDs start with timestamp, so newer entries have a bigger ID)
    NSString *leastExistingEntityShelbyID = [self leastShelbyIDIn:self.existingEntities];
    for (id<ShelbyModel> entity in self.actuallyNewEntities) {
        if ([[entity shelbyID] compare:leastExistingEntityShelbyID] == NSOrderedDescending) {
            self.actuallyNewEntitiesShouldBeAppended = NO;
            //if all entities are new & there's no overlap with existing entities, there is a gap between them
            self.gapAfterNewEntitiesBeforeExistingEntities = ([self.actuallyNewEntities count] == [self.possiblyNewEntities count]);
            return;
        }
    }

    // 3) must be an append
    self.actuallyNewEntitiesShouldBeAppended = YES;
}

- (NSArray *)orderedElementsOf:(NSArray *)arr1 notFoundIn:(NSArray *)arr2
{
    NSMutableArray *result = [@[] mutableCopy];
    for (id<ShelbyModel>entity in arr1) {
        if (![arr2 containsObject:entity]) {
            //objects have the same objectID (since that's what -[NSManagedObject isEqual:] uses)
            [result addObject:entity];
        }
    }
    return result;
}

- (NSString *)leastShelbyIDIn:(NSArray *)arr
{
    NSString *leastID;
    for (id<ShelbyModel> entity in arr) {
        if (!leastID || [[entity shelbyID] compare:leastID] == NSOrderedAscending) {
            leastID = [entity shelbyID];
        }
    }
    return leastID;
}

@end
