//
//  DashboardEntry+Helper.m
//  Shelby.tv
//
//  Created by Daniel Spinosa on 5/2/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "DashboardEntry+Helper.h"

#import "Frame+Helper.h"
#import "NSManagedObject+Helper.h"

NSString * const kShelbyCoreDataEntityDashboardEntry = @"DashboardEntry";
NSString * const kShelbyCoreDataEntityDashboardEntryIDPredicate = @"dashboardEntryID == %@";

@implementation DashboardEntry (Helper)

@dynamic duplicateOf;
@dynamic duplicates;

+ (DashboardEntry *)dashboardEntryForDictionary:(NSDictionary *)dict
                                  withDashboard:(Dashboard *)dashboard
                                      inContext:(NSManagedObjectContext *)context
{
    NSString *dashboardEntryID = dict[@"id"];
    DashboardEntry *dashboardEntry = [self fetchOneEntityNamed:kShelbyCoreDataEntityDashboardEntry
                                               withIDPredicate:kShelbyCoreDataEntityDashboardEntryIDPredicate
                                                         andID:dashboardEntryID
                                                     inContext:context];
    
    if (!dashboardEntry) {
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
