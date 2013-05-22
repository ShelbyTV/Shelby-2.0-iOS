//
//  DisplayChannel+Helper.m
//  Shelby.tv
//
//  Created by Daniel Spinosa on 5/1/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "DisplayChannel+Helper.h"

#import "Dashboard+Helper.h"
#import "NSManagedObject+Helper.h"
#import "Roll+Helper.h"
#import "ShelbyDataMediator.h"
#import "UIColor+ColorWithHexAndAlpha.h"

NSString * const kShelbyCoreDataEntityDisplayChannel = @"DisplayChannel";
NSString * const kShelbyCoreDataEntityDisplayChannelViaRollIDPredicate = @"roll.rollID == %@";
NSString * const kShelbyCoreDataEntityDisplayChannelViaDashboardIDPredicate = @"dashboard.dashboardID == %@";

@implementation DisplayChannel (Helper)

+ (NSArray *)allChannelsInContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:kShelbyCoreDataEntityDisplayChannel];
    NSSortDescriptor *sortByOrder = [NSSortDescriptor sortDescriptorWithKey:@"order" ascending:YES];
    request.sortDescriptors = @[sortByOrder];
    return [context executeFetchRequest:request error:nil];
}

+ (DisplayChannel *)channelForRollDictionary:(NSDictionary *)rollDict withOrder:(NSInteger)order inContext:(NSManagedObjectContext *)context
{
    //look for existing DisplayChannel
    NSString *rollID = rollDict[@"id"];
    DisplayChannel *displayChannel = [self fetchOneEntityNamed:kShelbyCoreDataEntityDisplayChannel
                                               withIDPredicate:kShelbyCoreDataEntityDisplayChannelViaRollIDPredicate
                                                         andID:rollID
                                                     inContext:context];
    
    if (!displayChannel) {
        displayChannel = [NSEntityDescription insertNewObjectForEntityForName:kShelbyCoreDataEntityDisplayChannel
                                                       inManagedObjectContext:context];
    }
    
    //this will mege new roll attributes
    Roll *roll = [Roll rollForDictionary:rollDict inContext:context];
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
    NSString *dashboardID = dashboardDict[@"user_id"];
    DisplayChannel *displayChannel = [self fetchOneEntityNamed:kShelbyCoreDataEntityDisplayChannel
                                               withIDPredicate:kShelbyCoreDataEntityDisplayChannelViaDashboardIDPredicate
                                                         andID:dashboardID
                                                     inContext:context];
    
    if (!displayChannel) {
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


+ (DisplayChannel *)channelForOfflineLikesWithOrder:(NSInteger)order
                                          inContext:(NSManagedObjectContext *)context
{
    NSString *rollID = kShelbyOfflineLikesID;
    DisplayChannel *displayChannel = [self fetchOneEntityNamed:kShelbyCoreDataEntityDisplayChannel
                                               withIDPredicate:kShelbyCoreDataEntityDisplayChannelViaRollIDPredicate
                                                         andID:rollID
                                                     inContext:context];
    
    if (!displayChannel) {
        displayChannel = [NSEntityDescription insertNewObjectForEntityForName:kShelbyCoreDataEntityDisplayChannel
                                                       inManagedObjectContext:context];
    }
    
    Roll *likesRoll = [Roll fetchLikesRollInContext:context];
    displayChannel.roll = likesRoll;
    
    return displayChannel;
}

- (BOOL) canFetchRemoteEntries
{
    //only offline Likes cannot refresh
    return !(self.roll && [self.roll.rollID isEqualToString:kShelbyOfflineLikesID]);
}

- (UIColor *)displayColor
{
    if(self.roll){
        return [UIColor colorWithHex:self.roll.displayColor andAlpha:1.0];
    } else if(self.dashboard){
        return [UIColor colorWithHex:self.dashboard.displayColor andAlpha:1.0];
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

- (BOOL)hasEntityAtIndex:(NSInteger)idx
{
    if(self.roll){
        return [self.roll.frame count] > idx;
    } else if(self.dashboard){
        return [self.dashboard.dashboardEntry count] > idx;
    } else {
        return NO;
    }
}

@end
