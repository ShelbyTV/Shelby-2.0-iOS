//
//  User+Helper.m
//  Shelby.tv
//
//  Created by Daniel Spinosa on 4/30/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "User+Helper.h"

@implementation User (Helper)

+(User *)currentAuthenticatedUserInContext:(NSManagedObjectContext *)moc
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:kShelbyCoreDataEntityUser];
    request.fetchLimit = 1;
    NSArray *results = [moc executeFetchRequest:request error:nil];
    
    return [results count] ? results[0] : nil;
}

@end
