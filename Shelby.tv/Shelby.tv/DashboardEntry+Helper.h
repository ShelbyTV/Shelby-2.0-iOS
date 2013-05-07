//
//  DashboardEntry+Helper.h
//  Shelby.tv
//
//  Created by Daniel Spinosa on 5/2/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "DashboardEntry.h"
#import "ShelbyModel.h"

@interface DashboardEntry (Helper) <ShelbyModel>

+ (DashboardEntry *)dashboardEntryForDictionary:(NSDictionary *)dict
                                  withDashboard:(Dashboard *)dashboard
                                      inContext:(NSManagedObjectContext *)context;

+ (NSArray *)entriesForDashboard:(Dashboard *)dashboard
                     inContext:(NSManagedObjectContext *)context;

- (BOOL)isPlayable;

@end
