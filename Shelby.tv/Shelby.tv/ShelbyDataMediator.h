//
//  ShelbyDataMediator.h
//  Shelby.tv
//
//  Created by Daniel Spinosa on 4/29/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//
//  You want Shelby Data?  You come here.  Nowhere else.

#import <Foundation/Foundation.h>

@protocol ShelbyDataMediatorProtocol <NSObject>
// channels
-(void)fetchChannelsDidCompleteWith:(NSArray *)channels fromCache:(BOOL)cached;
-(void)fetchChannelsDidCompleteWithError;
@end

@interface ShelbyDataMediator : NSObject

@property (nonatomic, weak) id<ShelbyDataMediatorProtocol> delegate;

+(ShelbyDataMediator *)sharedInstance;

//fetching
- (void)fetchChannels;


//XXX: This is not the final method signature, just a placeholder for important api removed from elsewhere
-(void)logout;

//do whatever it takes to get us to a clean state, guaranteed
-(void)nuclearCleanup;

//the single, shared context for use on the main thread
//we're using Thread Confinement for CoreData concurrency
//that is, each thread has it's own ManagedObjectContext, all sharing a single PersistentStoreCoordinator
-(NSManagedObjectContext *)mainThreadContext;

@end
