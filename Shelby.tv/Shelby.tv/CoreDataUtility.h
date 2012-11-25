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

/// Public Methods

// Initialization Methods
- (id)initWithRequestType:(APIRequestType)requestType;

// Persistance Methods
- (void)saveContext:(NSManagedObjectContext *)context;
- (void)dumpAllData;

// Storage Methods
- (void)storeUser:(NSDictionary*)resultsDictionary;
- (void)storeStream:(NSDictionary*)resultsDictionary;

// Fetching Methods
- (NSArray*)fetchStreamEntries;

@end