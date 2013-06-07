//
//  DVREntry.h
//  Shelby.tv
//
//  Created by Daniel Spinosa on 6/4/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class DashboardEntry, Frame;

@interface DVREntry : NSManagedObject

@property (nonatomic, retain) NSDate * remindAt;
@property (nonatomic, retain) NSDate * updatedAt;
@property (nonatomic, retain) Frame *frame;
@property (nonatomic, retain) DashboardEntry *dashboardEntry;

@end
