//
//  DisplayChannel.h
//  Shelby.tv
//
//  Created by Daniel Spinosa on 5/2/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Dashboard, Roll;

@interface DisplayChannel : NSManagedObject

@property (nonatomic, retain) NSNumber * order;
@property (nonatomic, retain) Roll *roll;
@property (nonatomic, retain) Dashboard *dashboard;

@end
