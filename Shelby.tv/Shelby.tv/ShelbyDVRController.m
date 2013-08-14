//
//  ShelbyDVRController.m
//  Shelby.tv
//
//  Created by Daniel Spinosa on 6/4/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//
//  On notifications:
//  We schedule a UILocalNotification at the given remind time.  It is linked to the DVREntry and the time via userInfo.
//  The most recently added DVREntry will replace any other notifications

#import "ShelbyDVRController.h"
#import "User+Helper.h"
#import "DashboardEntry+Helper.h"
#import "Frame+Helper.h"

NSString * const NOTIFICATION_OBJECT_ID_KEY = @"objectID";
NSString * const NOTIFICATION_DATE_KEY = @"date";

@implementation ShelbyDVRController

- (void)setDVRFor:(id<ShelbyVideoContainer>)frameOrDashboardEntry
       toRemindAt:(NSDate *)date
{
    STVAssert(([frameOrDashboardEntry isKindOfClass:[Frame class]] ||
               [frameOrDashboardEntry isKindOfClass:[DashboardEntry class]]), @"expected Frame or DashboardEntry");
    
    NSManagedObjectContext *moc = [(NSManagedObject *)frameOrDashboardEntry managedObjectContext];
    DVREntry *dvrEntry = [DVREntry dvrEntryFor:frameOrDashboardEntry inContext:moc];
    
    NSDate *originalRemindAt = dvrEntry.remindAt;
    dvrEntry.remindAt = date;
    
    //save now b/c objectID is temporary until saved, and we use it the in notifications userInfo
    NSError *err;
    [moc save:&err];
    STVDebugAssert(!err, @"failed to save DVREntry in context");
    
    //upate notifications for the previous remind time
    if (originalRemindAt) {
        [self removeLocalNotificationsAt:originalRemindAt];
        [self createLocalNotificationsAt:originalRemindAt inContext:dvrEntry.managedObjectContext];
    }
    //update notifications for the new remind time
    [self removeLocalNotificationsAt:date];
    [self createLocalNotificationFor:dvrEntry at:date];
}

- (void)removeFromDVR:(id<ShelbyVideoContainer>)frameOrDashboardEntry
{
    STVAssert(([frameOrDashboardEntry isKindOfClass:[Frame class]] ||
               [frameOrDashboardEntry isKindOfClass:[DashboardEntry class]]), @"expected Frame or DashboardEntry");

    NSManagedObjectContext *moc = [(NSManagedObject *)frameOrDashboardEntry managedObjectContext];
    DVREntry *dvrEntry = [DVREntry dvrEntryFor:frameOrDashboardEntry inContext:moc];
    STVAssert(dvrEntry, @"could not find DVREntry for %@", frameOrDashboardEntry);
    [moc deleteObject:dvrEntry];
    NSError *err;
    [moc save:&err];
    STVDebugAssert(!err, @"failed to save context when removing DVREntry %@", dvrEntry);
    
    //update notifications at the original remind time
    [self removeLocalNotificationsAt:dvrEntry.remindAt];
    [self createLocalNotificationsAt:dvrEntry.remindAt inContext:dvrEntry.managedObjectContext];
}

- (NSArray *)currentDVREntriesOrderedLIFO:(BOOL)newestFirst
                                inContext:(NSManagedObjectContext *)moc
{
    return [DVREntry allCurrentOrderedLIFO:newestFirst inContext:moc];
}

- (DVREntry *)dvrEntryForLocalNotification:(UILocalNotification *)notification
                                 inContext:(NSManagedObjectContext *)moc
{
    NSString *objectIDAsString = [notification.userInfo valueForKey:NOTIFICATION_OBJECT_ID_KEY];
    STVAssert(objectIDAsString, @"Expected notification to have an objectID");
    NSManagedObjectID *objectID = [moc.persistentStoreCoordinator managedObjectIDForURIRepresentation:[NSURL URLWithString:objectIDAsString]];
    if (!objectID) {
        DLog(@"ERROR? Notification had objectID, but we couldn't get URL");
        return nil;
    }
    return (DVREntry *)[moc objectWithID:objectID];
}

#pragma mark - private helpers

- (void)removeLocalNotificationsAt:(NSDate *)date
{
    for (UILocalNotification *notification in [[UIApplication sharedApplication] scheduledLocalNotifications]) {
        if ([[notification.userInfo valueForKey:NOTIFICATION_DATE_KEY] isEqualToDate:date]) {
            [[UIApplication sharedApplication] cancelLocalNotification:notification];
        }
    }
}

- (void)createLocalNotificationsAt:(NSDate *)date inContext:(NSManagedObjectContext *)moc
{
    NSArray *dvrEntriesForDate = [DVREntry allAt:date orderedLIFO:NO inContext:moc];
    DVREntry *newestDVREntryForDate = [dvrEntriesForDate lastObject];
    if (newestDVREntryForDate) {
        [self createLocalNotificationFor:newestDVREntryForDate at:newestDVREntryForDate.remindAt];
    }
}

- (void)createLocalNotificationFor:(DVREntry *)dvrEntry at:(NSDate *)date
{
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    notification.userInfo = @{NOTIFICATION_OBJECT_ID_KEY: [dvrEntry objectIDAsString],
                              NOTIFICATION_DATE_KEY: date};
    notification.timeZone = [NSTimeZone defaultTimeZone];
    notification.fireDate = date;
    
    notification.applicationIconBadgeNumber = 1;
    notification.alertAction = NSLocalizedString(@"DVR_ALERT_ACTION", @"--DVR Local Notification--");
    notification.alertBody = [NSString stringWithFormat:NSLocalizedString(@"DVR_ALERT_BODY", nil),
                              [self nicknamesForNotificationAt:date
                                                     inContext:dvrEntry.managedObjectContext]];
    [[UIApplication sharedApplication] scheduleLocalNotification:notification];
}

// Using all DVREntries scheduled at the given time, returns a nice string of nicknames like "dan." or "dan, nick, and joe."
// The nicknames used are those of the creator of the underlying Frame.
- (NSString *)nicknamesForNotificationAt:(NSDate *)date inContext:(NSManagedObjectContext *)moc
{
    NSArray *dvrEntries = [DVREntry allAt:date orderedLIFO:YES inContext:moc];
    if (!dvrEntries || [dvrEntries count] == 0) {
        STVAssert(NO, @"expected dvr entries");
        return @"your friends."; //a fallback if we ever decide not to assert
        
    } else if ([dvrEntries count] == 1) {
        return [NSString stringWithFormat:@"%@.", [dvrEntries[0] entityCreatorsNickname]];
        
    } else {
        NSMutableString *nicknames = [NSMutableString string];
        NSUInteger end = MIN([dvrEntries count], (unsigned int)5);
        for (NSUInteger i = 0; i < end-1; ++i) {
            [nicknames appendFormat:@"%@, ", [dvrEntries[i] entityCreatorsNickname]];
        }
        [nicknames appendFormat:@"and %@.", [dvrEntries[end-1] entityCreatorsNickname]];
        return nicknames;
    }
}

@end
