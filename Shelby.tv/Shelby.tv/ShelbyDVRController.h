//
//  ShelbyDVRController.h
//  Shelby.tv
//
//  Created by Daniel Spinosa on 6/4/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//
//  Manages all DVR interactions, from saving a video for later to the handling
//  of the generated local notification.
//
//  Currently stores everything local to the device, but could be updated to
//  sync with the Shelby API in the future.

#import <Foundation/Foundation.h>
#import "DVREntry+Helper.h"
#import "ShelbyVideoContainer.h"

@interface ShelbyDVRController : NSObject

// Add a Frame or DashboardEntry to the DVR for reminder at the given time.
//
// Will set a local notification at the given time.  Removes any previously
// set local notifications at the given time.  Removes any previously set local
// notifications for the original entry (ie. if you're moving this from a future
// DVR time to a different future DVR time)
- (void)setDVRFor:(id<ShelbyVideoContainer>)frameOrDashboardEntry
       toRemindAt:(NSDate *)date;

// Removes the entry from DVR and removes any associated local notifications.
// If there are other entries at the same time, will recreate a notification
// based on them.
- (void)removeFromDVR:(id<ShelbyVideoContainer>)frameOrDashboardEntry;

// Returns the DVREntries that should have already been reminded.
// Can be ordered with the most-recently-added first (YES) or the oldest
// (ie. first-to-be-added-to-DVR) first (NO).
- (NSArray *)currentDVREntriesOrderedLIFO:(BOOL)newestFirst
                                inContext:(NSManagedObjectContext *)moc;

// Given a UILocalNotification (which is received as an option by
// application:didFinishLaunchingWithOptions: when app is in background, and
// received by application:didReceiveLocalNotification: when in foreground)
// returns the specifically associated DVREntry.
// NB: There may be other DVREntries with the same remind time.  They should be
// retrieved via DVREntry+Helper.
- (DVREntry *)dvrEntryForLocalNotification:(UILocalNotification *)notification
                                 inContext:(NSManagedObjectContext *)moc;

@end
