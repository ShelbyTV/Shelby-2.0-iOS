//
//  Roll+Helper.m
//  Shelby.tv
//
//  Created by Daniel Spinosa on 5/2/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "Roll+Helper.h"

#import "Frame+Helper.h"
#import "NSManagedObject+Helper.h"
#import "ShelbyDataMediator.h"

NSString * const kShelbyCoreDataEntityRoll = @"Roll";
NSString * const kShelbyCoreDataEntityRollIDPredicate = @"rollID == %@";

@implementation Roll (Helper)

+ (Roll *)rollForDictionary:(NSDictionary *)rollDict inContext:(NSManagedObjectContext *)context
{
    NSString *rollID = rollDict[@"id"];
    Roll *roll = [self fetchOneEntityNamed:kShelbyCoreDataEntityRoll
                           withIDPredicate:kShelbyCoreDataEntityRollIDPredicate
                                     andID:rollID
                                 inContext:context];
    
    if (!roll) {
        roll = [NSEntityDescription insertNewObjectForEntityForName:kShelbyCoreDataEntityRoll
                                               inManagedObjectContext:context];
        roll.rollID = rollID;
    }
    
    NSString *displayColor = rollDict[@"display_channel_color"];
    if (displayColor) {
        roll.displayColor = displayColor;
    }
    
    NSString *displayDescription = rollDict[@"display_description"];
    if (displayDescription) {
        roll.displayDescription = displayDescription;
    }
    
    NSString *displayTitle = rollDict[@"display_title"];
    if (displayTitle) {
        roll.displayTitle = displayTitle;
    }
    
    roll.frameCount = rollDict[@"frame_count"];
    roll.thumbnailURL = [NSString stringWithFormat:@"http://shelby.tv%@", rollDict[@"display_thumbnail_ipad_src"]];
    roll.title = rollDict[@"title"];
    
    return roll;
}

+ (Roll *)fetchLikesRollInContext:(NSManagedObjectContext *)context
{
    NSString *rollID = kShelbyOfflineLikesID;
    Roll *roll = [self fetchOneEntityNamed:kShelbyCoreDataEntityRoll
                           withIDPredicate:kShelbyCoreDataEntityRollIDPredicate
                                     andID:rollID
                                 inContext:context];
    
    if (!roll) {
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

+ (Roll *)rollWithID:(NSString *)rollID
           inContext:(NSManagedObjectContext *)context
{
    return [self fetchOneEntityNamed:kShelbyCoreDataEntityRoll
                     withIDPredicate:kShelbyCoreDataEntityRollIDPredicate
                               andID:rollID
                           inContext:context];
}

@end
