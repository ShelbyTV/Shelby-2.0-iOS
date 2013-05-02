//
//  Dashboard+Helper.h
//  Shelby.tv
//
//  Created by Daniel Spinosa on 5/2/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "Dashboard.h"

@interface Dashboard (Helper)

//find or create a Dashboard
//return nil on error
//NB: does not save context
+ (Dashboard *)dashboardForDashboardDictionary:(NSDictionary *)dashboardDict
                                     inContext:(NSManagedObjectContext *)context;

@end
