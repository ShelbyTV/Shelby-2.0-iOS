//
//  ShelbyDataMediator.h
//  Shelby.tv
//
//  Created by Daniel Spinosa on 4/29/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//
//  You want Shelby Data?  You come here.  Nowhere else.

#import <Foundation/Foundation.h>

@interface ShelbyDataMediator : NSObject

+(ShelbyDataMediator *)sharedInstance;

//XXX: This is not the final method signature, just a placeholder for important api removed from elsewhere
-(void)logout;

//do whatever it takes to get us to a clean state, guaranteed
-(void)nuclearCleanup;

//the single, shared context for use on the main thread
//we're using Thread Confinement for CoreData concurrency
//that is, each thread has it's own ManagedObjectContext, all sharing a single PersistentStoreCoordinator
-(NSManagedObjectContext *)mainThreadContext;

@end
