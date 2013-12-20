//
//  DisplayChannel.h
//  Shelby.tv
//
//  Created by Dan Spinosa on 12/20/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Dashboard, Roll;

@interface DisplayChannel : NSManagedObject

@property (nonatomic, retain) NSString * channelID;
@property (nonatomic, retain) NSNumber * entriesAreTransient;
@property (nonatomic, retain) NSNumber * order;
@property (nonatomic, retain) NSString * titleOverride;
@property (nonatomic, retain) NSNumber * shouldFetchRemoteEntries;
@property (nonatomic, retain) Dashboard *dashboard;
@property (nonatomic, retain) Roll *roll;

@end
