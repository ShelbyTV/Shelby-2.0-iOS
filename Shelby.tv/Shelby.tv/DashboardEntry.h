//
//  DashboardEntry.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 4/22/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Dashboard, Frame;

@interface DashboardEntry : NSManagedObject

@property (nonatomic, retain) NSString * dashboardEntryID;
@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) Frame *frame;
@property (nonatomic, retain) Dashboard *dashboard;

@end
