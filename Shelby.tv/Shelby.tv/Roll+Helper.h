//
//  Roll+Helper.h
//  Shelby.tv
//
//  Created by Daniel Spinosa on 5/2/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "Roll.h"

@interface Roll (Helper)

//find or create a Roll
//return nil on error
//NB: does not save context
+ (Roll *)rollForDictionary:(NSDictionary *)rollDict
                      inContext:(NSManagedObjectContext *)context;

+ (Roll *)fetchLikesRollInContext:(NSManagedObjectContext *)context;
@end