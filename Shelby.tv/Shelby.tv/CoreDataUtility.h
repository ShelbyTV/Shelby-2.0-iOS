//
//  CoreDataUtility.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 10/25/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CoreDataUtility : NSObject

// Public Methods
+ (NSManagedObjectContext*)createContext;
+ (void)saveContext:(NSManagedObjectContext *)context;
+ (void)dumpAllData;
+ (void)storeStream:(NSDictionary *)resultsDictionary;

// Singleton Methods
+ (CoreDataUtility*)sharedInstance;

@end