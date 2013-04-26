//
//  Dashboard.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 4/22/13.
//  Copyright (c) 2013 Shelby TV. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class DashboardEntry;

@interface Dashboard : NSManagedObject

@property (nonatomic, retain) NSString * dashboardID;
@property (nonatomic, retain) NSString * displayColor;
@property (nonatomic, retain) NSString * displayDescription;
@property (nonatomic, retain) NSNumber * displayTag;
@property (nonatomic, retain) NSString * displayThumbnailURL;
@property (nonatomic, retain) NSString * displayTitle;
@property (nonatomic, retain) NSNumber * isChannel;
@property (nonatomic, retain) DashboardEntry *dashboardEntry;

@end
