//
//  ShelbyDataMediator.h
//  Shelby.tv
//
//  Created by Daniel Spinosa on 4/29/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//
//  You want Shelby Data?  You come here.  Nowhere else.

#import <Foundation/Foundation.h>

extern NSString * const kShelbyOfflineLikesID;

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
-(void)fetchOfflineLikesDidCompleteForChannel:(DisplayChannel *)channel
                                         with:(NSArray *)channelEntries;
// User Channels
- (void)fetchUserChannelDidCompleteWithChannel:(DisplayChannel *)myStreamChannel
                                          with:(NSArray *)channelEntries
                                     fromCache:(BOOL)cached;

// Login
- (void)loginUserDidCompleteWithUser:(User *)user;
- (void)loginUserDidCompleteWithError:(NSString *)errorMessage;

// Facebook
- (void)facebookConnectDidCompleteWithUser:(User *)user;
- (void)facebookConnectDidCompleteWithError:(NSString *)errorMessage;
@end

@interface ShelbyDataMediator : NSObject

@property (nonatomic, weak) id<ShelbyDataMediatorProtocol> delegate;

+(ShelbyDataMediator *)sharedInstance;

//fetching
- (void)fetchChannels;
- (void)fetchEntriesInChannel:(DisplayChannel *)channel sinceEntry:(NSManagedObject *)entry;
- (User *)fetchAuthenticatedUserOnMainThreadContext;
- (void)fetchAllUnsyncedLikes;

// User
- (void)fetchStreamForUser;
- (void)fetchMyRollForUser;

//XXX: This is not the final method signature, just a placeholder for important api removed from elsewhere
-(void)logoutWithUserChannels:(NSArray *)userChannels;

- (void)loginUserWithEmail:(NSString *)email password:(NSString *)password;

- (void)openFacebookSessionWithAllowLoginUI:(BOOL)allowLoginUI;
- (void)connectTwitterWithViewController:(UIViewController *)viewController;

//returns YES if the toggle should result in this frame being liked
//NB: does not guarantee async post will succeed
- (BOOL)toggleLikeForFrame:(Frame *)frame;

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
