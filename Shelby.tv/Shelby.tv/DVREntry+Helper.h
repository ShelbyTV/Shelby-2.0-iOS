//
//  DVREntry+Helper.h
//  Shelby.tv
//
//  Created by Daniel Spinosa on 6/4/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "DVREntry.h"
#import "ShelbyVideoContainer.h"

@interface DVREntry (Helper)

// Find or create a DVREntry for the given Frame or DashboardEntry.
// NB: does not save the context.
+ (DVREntry *)dvrEntryFor:(id<ShelbyVideoContainer>)frameOrDashboardEntry
                inContext:(NSManagedObjectContext *)moc;

// Returns the DVREntries that should have already been reminded.
// Can be ordered with the most-recently-added first (YES) or the oldest
// (ie. first-to-be-added-to-DVR) first (NO).
+ (NSArray *)allCurrentOrderedLIFO:(BOOL)newestFirst
                         inContext:(NSManagedObjectContext *)moc;

// Returns the DVREntries that should remind exactly at the given date.
// Can be ordered with the most-recently-added first (YES) or the oldest
// (ie. first-to-be-added-to-DVR) first (NO).
+ (NSArray *)allAt:(NSDate *)date
       orderedLIFO:(BOOL)newestFirst
         inContext:(NSManagedObjectContext *)moc;

- (NSString *)objectIDAsString;

// Then nickname of the user that created the Frame or DashboardEntry's Frame.
- (NSString *)entityCreatorsNickname;

@end
