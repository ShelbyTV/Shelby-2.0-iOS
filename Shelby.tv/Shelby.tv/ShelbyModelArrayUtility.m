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
@property (nonatomic, assign) BOOL newEntitiesShouldBeAppended;
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
    //no new entries
    if ([self.possiblyNewEntities count] == 0) {
        self.actuallyNewEntities = @[];
        return;
    }

    //only new entries
    if ([self.existingEntities count] == 0) {
        self.actuallyNewEntities = self.possiblyNewEntities;
        self.newEntitiesShouldBeAppended = NO;
        return;
    }

    // non-trivial merge...
    // 1) find subset of possibly new entities that are actually NEW
    self.actuallyNewEntities = [self orderedElementsOf:self.possiblyNewEntities notFoundIn:self.existingEntities];

    if ([self.actuallyNewEntities count] == 0) {
        return;
    }

    // 2) if we have any new entities with an ID > last exisitng entity ID, that's a pre-pend
    //    (IDs start with timestamp, so newer entries have a bigger ID)
    NSString *lastKnownShelbyID = [[self.existingEntities lastObject] shelbyID];
    for (id<ShelbyModel> entity in self.actuallyNewEntities) {
        if ([[entity shelbyID] compare:lastKnownShelbyID] == NSOrderedDescending) {
            self.newEntitiesShouldBeAppended = NO;
            return;
        }
    }

    // 3) must be an append
    self.newEntitiesShouldBeAppended = YES;
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

@end
