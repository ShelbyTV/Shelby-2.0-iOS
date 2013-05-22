//
//  NSManagedObject+Helper.m
//  Shelby.tv
//
//  Created by Daniel Spinosa on 5/22/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "NSManagedObject+Helper.h"

@implementation NSManagedObject (Helper)

+ (id)fetchOneEntityNamed:(NSString *)entityName
          withIDPredicate:(NSString *)idPred
                    andID:(NSString *)idVal
                inContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:entityName];
    NSPredicate *pred = [NSPredicate predicateWithFormat:idPred, idVal];
    request.predicate = pred;
    request.fetchLimit = 1;
    NSError *error;
    NSArray *fetchedEntities = [context executeFetchRequest:request error:&error];
    if(!error && fetchedEntities && [fetchedEntities count] == 1){
        return fetchedEntities[0];
    } else {
        return nil;
    }
}

@end
