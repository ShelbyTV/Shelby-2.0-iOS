//
//  Dashboard.h
//  Shelby.tv
//
//  Created by Daniel Spinosa on 5/2/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class DashboardEntry, DisplayChannel;

@interface Dashboard : NSManagedObject

@property (nonatomic, retain) NSString * dashboardID;
@property (nonatomic, retain) NSString * displayColor;
@property (nonatomic, retain) NSString * displayDescription;
@property (nonatomic, retain) NSNumber * displayTag;
@property (nonatomic, retain) NSString * displayThumbnailURL;
@property (nonatomic, retain) NSString * displayTitle;
@property (nonatomic, retain) NSNumber * isChannel;
@property (nonatomic, retain) NSSet *dashboardEntry;
@property (nonatomic, retain) DisplayChannel *displayChannel;
@end

@interface Dashboard (CoreDataGeneratedAccessors)

- (void)addDashboardEntryObject:(DashboardEntry *)value;
- (void)removeDashboardEntryObject:(DashboardEntry *)value;
- (void)addDashboardEntry:(NSSet *)values;
- (void)removeDashboardEntry:(NSSet *)values;

@end
