//
//  DisplayChannel.h
//  Shelby.tv
//
//  Created by Daniel Spinosa on 6/7/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Dashboard, Roll;

@interface DisplayChannel : NSManagedObject

@property (nonatomic, retain) NSNumber * order;
@property (nonatomic, retain) NSNumber * entriesAreTransient;
@property (nonatomic, retain) NSString * channelID;
@property (nonatomic, retain) NSString * titleOverride;
@property (nonatomic, retain) Dashboard *dashboard;
@property (nonatomic, retain) Roll *roll;

@end
