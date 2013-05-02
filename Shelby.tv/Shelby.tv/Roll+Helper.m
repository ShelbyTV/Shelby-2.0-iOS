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

//NSString * const kShelbyCoreDataEntityRoll = @"Roll";

@implementation Roll (Helper)

+ (Roll *)rollForRollDictionary:(NSDictionary *)rollDict inContext:(NSManagedObjectContext *)context
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
    roll.thumbnailURL = [NSString stringWithFormat:@"http://shelby.tv%@", rollDict[@"display_thumbnail_ipad_src"]];
    roll.displayTitle = rollDict[@"display_title"];
    
    return roll;
}

@end
