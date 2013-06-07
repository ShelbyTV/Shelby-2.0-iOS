//
//  DVREntry+Helper.m
//  Shelby.tv
//
//  Created by Daniel Spinosa on 6/4/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "DVREntry+Helper.h"
#import "DashboardEntry+Helper.h"
#import "Frame+Helper.h"
#import "NSManagedObject+Helper.h"
#import "User+Helper.h"

NSString * const kShelbyCoreDataEntityDVREntry = @"DVREntry";
NSString * const kShelbyCoreDataEntityDVREntryWithFrameIDPredicate = @"frame.frameID == %@";
NSString * const kShelbyCoreDataEntityDVREntryWithDashboardEntryIDPredicate = @"dashboardEntry.dashboardEntryID == %@";

@implementation DVREntry (Helper)

+ (DVREntry *)dvrEntryFor:(id<ShelbyVideoContainer>)frameOrDashboardEntry
                inContext:(NSManagedObjectContext *)moc
{
    DVREntry *entry;
    Frame *frame;
    DashboardEntry *dbe;
    if ([frameOrDashboardEntry isKindOfClass:[Frame class]]) {
        frame = (Frame *)frameOrDashboardEntry;
        entry = [self fetchOneEntityNamed:kShelbyCoreDataEntityDVREntry
                          withIDPredicate:kShelbyCoreDataEntityDVREntryWithFrameIDPredicate
                                    andID:frame.frameID
                                inContext:moc];
    } else if ([frameOrDashboardEntry isKindOfClass:[DashboardEntry class]]) {
        dbe = (DashboardEntry *)frameOrDashboardEntry;
        entry = [self fetchOneEntityNamed:kShelbyCoreDataEntityDVREntry
                          withIDPredicate:kShelbyCoreDataEntityDVREntryWithDashboardEntryIDPredicate
                                    andID:dbe.dashboardEntryID
                                inContext:moc];
    } else {
        STVAssert(NO, @"expected a Frame or DashboardEntry");
    }
    
    if (!entry) {
        entry = [NSEntityDescription insertNewObjectForEntityForName:kShelbyCoreDataEntityDVREntry
                                              inManagedObjectContext:moc];
        entry.frame = frame;
        entry.dashboardEntry = dbe;
    }
    entry.updatedAt = [NSDate date];

    return entry;
}

+ (NSArray *)allCurrentOrderedLIFO:(BOOL)newestFirst
                         inContext:(NSManagedObjectContext *)moc
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:kShelbyCoreDataEntityDVREntry];
    NSPredicate *currentEntries = [NSPredicate predicateWithFormat:@"remindAt <= %@", [NSDate date]];
    request.predicate = currentEntries;
    NSSortDescriptor *order = [NSSortDescriptor sortDescriptorWithKey:@"updatedAt" ascending:!newestFirst];
    request.sortDescriptors = @[order];
    
    NSError *err;
    NSArray *results = [moc executeFetchRequest:request error:&err];
    STVAssert(!err, @"couldn't fetch DVR Entries");
    return results;
}

+ (NSArray *)allAt:(NSDate *)date
       orderedLIFO:(BOOL)newestFirst
         inContext:(NSManagedObjectContext *)moc
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:kShelbyCoreDataEntityDVREntry];
    NSPredicate *currentEntries = [NSPredicate predicateWithFormat:@"remindAt == %@", date];
    request.predicate = currentEntries;
    NSSortDescriptor *order = [NSSortDescriptor sortDescriptorWithKey:@"updatedAt" ascending:!newestFirst];
    request.sortDescriptors = @[order];
    
    NSError *err;
    NSArray *results = [moc executeFetchRequest:request error:&err];
    STVAssert(!err, @"couldn't fetch DVR Entries");
    return results;
}

- (NSString *)objectIDAsString
{
    return [[self.objectID URIRepresentation] absoluteString];
}

- (Frame *)childFrame
{
    if (self.frame) {
        return self.frame;
    } else if (self.dashboardEntry) {
        return self.dashboardEntry.frame;
    } else {
        STVAssert(NO, @"expected Frame or DashboardEntry");
    }
}

- (NSString *)entityCreatorsNickname
{
    if (self.frame) {
        return self.frame.creator.nickname;
    } else if (self.dashboardEntry) {
        return self.dashboardEntry.frame.creator.nickname;
    } else {
        STVAssert(NO, @"expected Frame or DashboardEntry");
    }
}

- (BOOL)isPlayable
{
    if (self.frame) {
        return self.frame.isPlayable;
    } else if (self.dashboardEntry) {
        return self.dashboardEntry.isPlayable;
    } else {
        //you could make that argument that we should assert here
        //but this is technically correct:
        return NO;
    }
}

@end
