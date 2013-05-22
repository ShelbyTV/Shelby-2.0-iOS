//
//  NSManagedObject+Helper.h
//  Shelby.tv
//
//  Created by Daniel Spinosa on 5/22/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NSManagedObject (Helper)

//expects idPred to be in a form like @"backendID == %@"
//or compound like @"child.backendID == %@"
+ (id)fetchOneEntityNamed:(NSString *)entityName
          withIDPredicate:(NSString *)idPred
                    andID:(NSString *)idVal
                inContext:(NSManagedObjectContext *)context;

@end
