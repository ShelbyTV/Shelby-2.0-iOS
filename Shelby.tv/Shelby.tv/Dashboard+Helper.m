//
//  Dashboard+Helper.m
//  Shelby.tv
//
//  Created by Daniel Spinosa on 5/2/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "Dashboard+Helper.h"
//djs XXX remove this and add the const
#import "CoreDataConstants.h"

//NSString * const kShelbyCoreDataEntityDashboard = @"Dashboard";

@implementation Dashboard (Helper)

+ (Dashboard *)dashboardForDashboardDictionary:(NSDictionary *)dashboardDict
                                     inContext:(NSManagedObjectContext *)context
{
    //look for existing Dashboard
    NSString *dashboardID = dashboardDict[@"user_id"];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:kShelbyCoreDataEntityDashboard];
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"dashboardID == %@", dashboardID];
    request.predicate = pred;
    request.fetchLimit = 1;
    NSError *error;
    NSArray *fetchedDashboards = [context executeFetchRequest:request error:&error];
    if(error || !fetchedDashboards){
        return nil;
    }
    
    Dashboard *dashboard = nil;
    if([fetchedDashboards count] == 1){
        dashboard = fetchedDashboards[0];
    } else {
        dashboard = [NSEntityDescription insertNewObjectForEntityForName:kShelbyCoreDataEntityDashboard
                                                  inManagedObjectContext:context];
        dashboard.dashboardID = dashboardID;
    }
    dashboard.displayColor = dashboardDict[@"display_channel_color"];
    dashboard.displayDescription = dashboardDict[@"display_description"];
    dashboard.displayThumbnailURL = [NSString stringWithFormat:@"http://shelby.tv%@", dashboardDict[@"display_thumbnail_ipad_src"]];
    dashboard.displayTitle = dashboardDict[@"display_title"];
    
    return dashboard;
}

@end
