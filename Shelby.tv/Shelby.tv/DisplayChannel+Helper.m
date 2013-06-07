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
    DisplayChannel *displayChannel = [DisplayChannel channelForRollID:kShelbyOfflineLikesID inContext:context];
    
    if (!displayChannel) {
        displayChannel = [NSEntityDescription insertNewObjectForEntityForName:kShelbyCoreDataEntityDisplayChannel
                                                       inManagedObjectContext:context];
    }
    
    Roll *likesRoll = [Roll fetchLikesRollInContext:context];
    displayChannel.roll = likesRoll;
    
    return displayChannel;
}

+ (DisplayChannel *)userChannelForDashboardDictionary:(NSDictionary *)dictionary
                                               withID:(NSString *)channelID
                                            withOrder:(NSInteger)order
                                            inContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:kShelbyCoreDataEntityDisplayChannel];
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"dashboard.dashboardID == %@", channelID];
    request.predicate = pred;
    request.fetchLimit = 1;
    NSError *error;
    NSArray *fetchedDisplayChannels = [context executeFetchRequest:request error:&error];
    if(error || !fetchedDisplayChannels){
        return nil;
    }
    
    DisplayChannel *displayChannel;
    if ([fetchedDisplayChannels count] == 1) { 
        displayChannel = fetchedDisplayChannels[0];
    } else {
        displayChannel = [NSEntityDescription insertNewObjectForEntityForName:kShelbyCoreDataEntityDisplayChannel
                                                       inManagedObjectContext:context];
    }
    
    Dashboard *myStreams = [Dashboard dashboardForDashboardDictionary:dictionary inContext:context];
    displayChannel.dashboard = myStreams;
    
    return displayChannel;
}

+ (DisplayChannel *)userChannelForRollDictionary:(NSDictionary *)dictionary
                                          withID:(NSString *)channelID
                                       withOrder:(NSInteger)order
                                       inContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:kShelbyCoreDataEntityDisplayChannel];
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"roll.rollID == %@", channelID];
    request.predicate = pred;
    request.fetchLimit = 1;
    NSError *error;
    NSArray *fetchedDisplayChannels = [context executeFetchRequest:request error:&error];
    if(error || !fetchedDisplayChannels){
        return nil;
    }
    
    DisplayChannel *displayChannel;
    if ([fetchedDisplayChannels count] == 1) {
        displayChannel = fetchedDisplayChannels[0];
    } else {
        displayChannel = [NSEntityDescription insertNewObjectForEntityForName:kShelbyCoreDataEntityDisplayChannel
                                                       inManagedObjectContext:context];
    }
    
    Roll *myStreams = [Roll rollForDictionary:dictionary inContext:context];
    displayChannel.roll = myStreams;
    
    return displayChannel;
}

+ (DisplayChannel *)channelForRollID:(NSString *)rollID
                           inContext:(NSManagedObjectContext *)context
{
    return [self fetchOneEntityNamed:kShelbyCoreDataEntityDisplayChannel
                     withIDPredicate:kShelbyCoreDataEntityDisplayChannelViaRollIDPredicate
                               andID:rollID
                           inContext:context];
    
}

+ (DisplayChannel *)channelForDashboardID:(NSString *)dashboardID
                                inContext:(NSManagedObjectContext *)context
{
    return [self fetchOneEntityNamed:kShelbyCoreDataEntityDisplayChannel
                     withIDPredicate:kShelbyCoreDataEntityDisplayChannelViaDashboardIDPredicate
                               andID:dashboardID
                           inContext:context];
}

- (BOOL) canFetchRemoteEntries
{
    //only offline Likes cannot refresh
    return !(self.roll && [self.roll.rollID isEqualToString:kShelbyOfflineLikesID]);
}

- (BOOL)canRoll
{
    if (self.roll) {
        // TODO: instead of fetching the user, maybe ShelbyDataM should hold on to a logged in user.
        User *currentUser = [[ShelbyDataMediator sharedInstance] fetchAuthenticatedUserOnMainThreadContext];
        if (currentUser && [currentUser.publicRollID isEqualToString:self.roll.rollID]) {
            return NO;
        }
    } 
    
    return YES;
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

- (BOOL)hasEntityAtIndex:(NSUInteger)idx
{
    if(self.roll){
        return [self.roll.frame count] > idx;
    } else if(self.dashboard){
        return [self.dashboard.dashboardEntry count] > idx;
    } else {
        return NO;
    }
}

- (void)deepRefreshMergeChanges:(BOOL)flag
{
    [self.managedObjectContext refreshObject:self mergeChanges:flag];
    if(self.roll){
        [self.managedObjectContext refreshObject:self.roll mergeChanges:flag];
    } else if(self.dashboard){
        [self.managedObjectContext refreshObject:self.dashboard mergeChanges:flag];
    }
}

@end
