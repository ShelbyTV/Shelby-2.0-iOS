//
//  DisplayChannel+Helper.h
//  Shelby.tv
//
//  Created by Daniel Spinosa on 5/1/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "DisplayChannel.h"

@interface DisplayChannel (Helper)

//sorted by order
//return nil on error
+ (NSArray *)allChannelsInContext:(NSManagedObjectContext *)context;

//find or create DisplayChannel, will find or create underlying Roll
//return nil on error
//NB: does not save context
+ (DisplayChannel *)channelForRollDictionary:(NSDictionary *)rollDict
                                   withOrder:(NSInteger)order
                                   inContext:(NSManagedObjectContext *)context;

//find or create DisplayChannel, will find or create underlying Dashboard
//return nil on error
//NB: does not save context
+ (DisplayChannel *)channelForDashboardDictionary:(NSDictionary *)dashboardDict
                                        withOrder:(NSInteger)order
                                        inContext:(NSManagedObjectContext *)context;

- (UIColor *)displayColor;
- (NSString *)displayTitle;

@end
