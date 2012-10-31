//
//  CoreDataUtility.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 10/25/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CoreDataUtility : NSObject

@property (strong, nonatomic, readonly) NSManagedObjectContext *context;

// Public Methods
- (void)saveContext:(NSManagedObjectContext *)context;
- (void)dumpAllData;
- (void)storeStream:(NSDictionary *)resultsDictionary;
- (NSArray*)fetchStreamEntries;

@end