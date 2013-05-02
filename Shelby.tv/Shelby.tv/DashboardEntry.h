//
//  DashboardEntry.h
//  Shelby.tv
//
//  Created by Daniel Spinosa on 5/2/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Dashboard, Frame;

@interface DashboardEntry : NSManagedObject

@property (nonatomic, retain) NSString * dashboardEntryID;
@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) Dashboard *dashboard;
@property (nonatomic, retain) Frame *frame;

@end
