//
//  DashboardEntry+Helper.m
//  Shelby.tv
//
//  Created by Daniel Spinosa on 5/2/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "DashboardEntry+Helper.h"
#import "Frame+Helper.h"

NSString * const kShelbyCoreDataEntityDashboardEntry = @"DashboardEntry";

@implementation DashboardEntry (Helper)

@dynamic duplicateOf;
@dynamic duplicates;

+ (DashboardEntry *)dashboardEntryForDictionary:(NSDictionary *)dict
                                  withDashboard:(Dashboard *)dashboard
                                      inContext:(NSManagedObjectContext *)context
{
    //look for existing DashboardEntry
    NSString *dashboardEntryID = dict[@"id"];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:kShelbyCoreDataEntityDashboardEntry];
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"dashboardEntryID == %@", dashboardEntryID];
    request.predicate = pred;
    request.fetchLimit = 1;
    NSError *error;
    NSArray *fetchedDashboardEntries = [context executeFetchRequest:request error:&error];
    if(error || !fetchedDashboardEntries){
        return nil;
    }
    
    DashboardEntry *dashboardEntry = nil;
    if([fetchedDashboardEntries count] == 1){
        dashboardEntry = fetchedDashboardEntries[0];
    } else {
        dashboardEntry = [NSEntityDescription insertNewObjectForEntityForName:kShelbyCoreDataEntityDashboardEntry
                                                       inManagedObjectContext:context];
        dashboardEntry.dashboardEntryID = dashboardEntryID;
        dashboardEntry.dashboard = dashboard;
    }

    //NB: intentionally not duplicating timestamp out of BSON id
    NSDictionary *frameDict = dict[@"frame"];
    if(![frameDict isKindOfClass:[NSDictionary class]]){
        return nil;
    }
    dashboardEntry.frame = [Frame frameForDictionary:frameDict inContext:context];
    
    return dashboardEntry;
}

+ (NSArray *)entriesForDashboard:(Dashboard *)dashboard inContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:kShelbyCoreDataEntityDashboardEntry];
    NSPredicate *entriesInDashboard = [NSPredicate predicateWithFormat:@"dashboard == %@", dashboard];
    request.predicate = entriesInDashboard;
    //Mongo IDs are prefixed with timestamp, so this gives us reverse-chron
    NSSortDescriptor *sortById = [NSSortDescriptor sortDescriptorWithKey:@"dashboardEntryID" ascending:NO];
    request.sortDescriptors = @[sortById];
    
    NSError *err;
    NSArray *results = [context executeFetchRequest:request error:&err];
    STVAssert(!err, @"couldn't fetch dashboard entries!");
    return results;
}

- (BOOL)isPlayable
{
    if (self.frame) {
        return [self.frame isPlayable];
    }
    
    return NO;
}

- (NSString *)shelbyID
{
    return self.dashboardEntryID;
}

- (Video *)containedVideo
{
    return self.frame.video;
}

@end
