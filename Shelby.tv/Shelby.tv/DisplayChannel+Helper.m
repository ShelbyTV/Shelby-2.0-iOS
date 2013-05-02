//
//  DisplayChannel+Helper.m
//  Shelby.tv
//
//  Created by Daniel Spinosa on 5/1/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "DisplayChannel+Helper.h"
#import "Roll+Helper.h"
#import "Dashboard+Helper.h"

NSString * const kShelbyCoreDataEntityDisplayChannel = @"DisplayChannel";

@implementation DisplayChannel (Helper)

+ (DisplayChannel *)channelForRollDictionary:(NSDictionary *)rollDict withOrder:(NSInteger)order inContext:(NSManagedObjectContext *)context
{
    //look for existing DisplayChannel
    NSString *rollID = rollDict[@"id"];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:kShelbyCoreDataEntityDisplayChannel];
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"roll.rollID == %@", rollID];
    request.predicate = pred;
    request.fetchLimit = 1;
    NSError *error;
    NSArray *fetchedDisplayChannels = [context executeFetchRequest:request error:&error];
    if(error || !fetchedDisplayChannels){
        return nil;
    }
    DisplayChannel *displayChannel;
    if([fetchedDisplayChannels count] == 1){
        displayChannel = fetchedDisplayChannels[0];
    } else {
        displayChannel = [NSEntityDescription insertNewObjectForEntityForName:kShelbyCoreDataEntityDisplayChannel
                                                       inManagedObjectContext:context];
    }
    
    //this will mege new roll attributes
    Roll *roll = [Roll rollForRollDictionary:rollDict inContext:context];
    if(!roll){
        return nil;
    }

    displayChannel.order = [NSNumber numberWithInt:order];
    displayChannel.roll = roll;
    
    return displayChannel;
}

+ (DisplayChannel *)channelForDashboardDictionary:(NSDictionary *)dashboardDict
                                        withOrder:(NSInteger)order
                                        inContext:(NSManagedObjectContext *)context
{
    //look for existing DisplayChannel
    NSString *dashboardID = dashboardDict[@"user_id"];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:kShelbyCoreDataEntityDisplayChannel];
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"dashboard.dashboardID == %@", dashboardID];
    request.predicate = pred;
    request.fetchLimit = 1;
    NSError *error;
    NSArray *fetchedDisplayChannels = [context executeFetchRequest:request error:&error];
    if(error || !fetchedDisplayChannels){
        return nil;
    }
    DisplayChannel *displayChannel;
    if([fetchedDisplayChannels count] == 1){
        displayChannel = fetchedDisplayChannels[0];
    } else {
        displayChannel = [NSEntityDescription insertNewObjectForEntityForName:kShelbyCoreDataEntityDisplayChannel
                                                       inManagedObjectContext:context];
    }
    
    //this will merge new dashboard attributes
    Dashboard *dashboard = [Dashboard dashboardForDashboardDictionary:dashboardDict inContext:context];
    if(!dashboard){
        return nil;
    }
    
    displayChannel.order = [NSNumber numberWithInt:order];
    displayChannel.dashboard = dashboard;
    
    return displayChannel;
}

- (NSString *)displayColor
{
    if(self.roll){
        return self.roll.displayColor;
    } else if(self.dashboard){
        return self.dashboard.displayColor;
    } else {
        return nil;
    }
}

- (NSString *)displayTitle
{
    if(self.roll){
        return self.roll.displayTitle;
    } else if(self.dashboard){
        return self.dashboard.displayTitle;
    } else {
        return nil;
    }
}

@end
