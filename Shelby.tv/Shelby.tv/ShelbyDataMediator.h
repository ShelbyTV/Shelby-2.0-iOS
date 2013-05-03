//
//  ShelbyDataMediator.h
//  Shelby.tv
//
//  Created by Daniel Spinosa on 4/29/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//
//  You want Shelby Data?  You come here.  Nowhere else.

#import <Foundation/Foundation.h>

//NB: delegate methods always called on the main thread
@protocol ShelbyDataMediatorProtocol <NSObject>
// channels
-(void)fetchChannelsDidCompleteWith:(NSArray *)channels fromCache:(BOOL)cached;
-(void)fetchChannelsDidCompleteWithError:(NSError *)error;
// channel entries
-(void)fetchEntriesDidCompleteForChannel:(DisplayChannel *)channel
                                    with:(NSArray *)channelEntries fromCache:(BOOL)cached;
-(void)fetchEntriesDidCompleteForChannel:(DisplayChannel *)channel
                               withError:(NSError *)error;
@end

@interface ShelbyDataMediator : NSObject

@property (nonatomic, weak) id<ShelbyDataMediatorProtocol> delegate;

+(ShelbyDataMediator *)sharedInstance;

//fetching
- (void)fetchChannels;
- (void)fetchEntriesInChannel:(DisplayChannel *)channel sinceEntry:(NSManagedObject *)entry;


//XXX: This is not the final method signature, just a placeholder for important api removed from elsewhere
-(void)logout;

//do whatever it takes to get us to a clean state, guaranteed
-(void)nuclearCleanup;

//the single, shared context for use on the main thread
//we're using Thread Confinement for CoreData concurrency
//that is, each thread has it's own ManagedObjectContext, all sharing a single PersistentStoreCoordinator
-(NSManagedObjectContext *)mainThreadContext;

// use this when operating on background threads
// kick back to main thread where you can use mainThreadContext
-(NSManagedObjectContext *)createPrivateQueueContext;

@end
