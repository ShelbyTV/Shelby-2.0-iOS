//
//  Messages+Helper.h
//  Shelby.tv
//
//  Created by Daniel Spinosa on 5/2/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "Messages.h"

@interface Messages (Helper)

+ (Messages *)messageForDictionary:(NSDictionary *)dict
                         inContext:(NSManagedObjectContext *)context;


@end
