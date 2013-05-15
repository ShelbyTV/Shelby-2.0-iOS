//
//  Roll+Helper.m
//  Shelby.tv
//
//  Created by Daniel Spinosa on 5/2/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "Roll+Helper.h"
//djs XXX remove this and add the const
#import "CoreDataConstants.h"
#import "Frame+Helper.h"
#import "ShelbyDataMediator.h"

//NSString * const kShelbyCoreDataEntityRoll = @"Roll";

@implementation Roll (Helper)

+ (Roll *)rollForDictionary:(NSDictionary *)rollDict inContext:(NSManagedObjectContext *)context
{
    //look for existing Roll
    NSString *rollID = rollDict[@"id"];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:kShelbyCoreDataEntityRoll];
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"rollID == %@", rollID];
    request.predicate = pred;
    request.fetchLimit = 1;
    NSError *error;
    NSArray *fetchedRolls = [context executeFetchRequest:request error:&error];
    if(error || !fetchedRolls){
        return nil;
    }
    
    Roll *roll = nil;
    if([fetchedRolls count] == 1){
        roll = fetchedRolls[0];
    } else {
        roll = [NSEntityDescription insertNewObjectForEntityForName:kShelbyCoreDataEntityRoll
                                               inManagedObjectContext:context];
        roll.rollID = rollID;
    }
    roll.displayColor = rollDict[@"display_channel_color"];
    roll.displayDescription = rollDict[@"display_description"];
    roll.frameCount = rollDict[@"frame_count"];
    roll.thumbnailURL = [NSString stringWithFormat:@"http://shelby.tv%@", rollDict[@"display_thumbnail_ipad_src"]];
    roll.displayTitle = rollDict[@"display_title"];
    roll.title = rollDict[@"title"];
    
    return roll;
}

+ (Roll *)fetchLikesRollInContext:(NSManagedObjectContext *)context
{
    NSString *rollID = kShelbyOfflineLikesID;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:kShelbyCoreDataEntityRoll];
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"rollID == %@", rollID];
    request.predicate = pred;
    request.fetchLimit = 1;
    NSError *error;
    NSArray *fetchedRolls = [context executeFetchRequest:request error:&error];
    if(error || !fetchedRolls){
        return nil;
    }
    
    Roll *roll = nil;
    if([fetchedRolls count] == 1){
        roll = fetchedRolls[0];
    } else {
        roll = [NSEntityDescription insertNewObjectForEntityForName:kShelbyCoreDataEntityRoll
                                             inManagedObjectContext:context];
        roll.rollID = rollID;
    }
    
    NSArray *likes = [Frame fetchAllLikesInContext:context];
    
    roll.frameCount = @([likes count]);
    roll.thumbnailURL = nil;
    roll.displayColor = kShelbyColorLikesRedString;
    roll.displayTitle = @"My Likes";
    roll.title = @"My Likes";
    
    NSSet *frames = [[NSSet alloc] initWithArray:likes];
    roll.frame = frames;
    
    return roll;

}

@end
