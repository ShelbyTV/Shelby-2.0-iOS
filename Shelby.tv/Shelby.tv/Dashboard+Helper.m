//
//  Dashboard+Helper.m
//  Shelby.tv
//
//  Created by Daniel Spinosa on 5/2/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "Dashboard+Helper.h"

#import "NSManagedObject+Helper.h"

NSString * const kShelbyCoreDataEntityDashboard = @"Dashboard";
NSString * const kShelbyCoreDataEntityDashboardIDPredicate = @"dashboardID == %@";

@implementation Dashboard (Helper)

+ (Dashboard *)dashboardForDashboardDictionary:(NSDictionary *)dashboardDict
                                     inContext:(NSManagedObjectContext *)context
{
    NSString *dashboardID = dashboardDict[@"user_id"];
    Dashboard *dashboard = [self fetchOneEntityNamed:kShelbyCoreDataEntityDashboard
                                     withIDPredicate:kShelbyCoreDataEntityDashboardIDPredicate
                                               andID:dashboardID
                                           inContext:context];
    
    if (!dashboard) {
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
