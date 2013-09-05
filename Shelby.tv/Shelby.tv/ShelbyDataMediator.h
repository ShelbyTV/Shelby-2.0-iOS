//
//  ShelbyDataMediator.h
//  Shelby.tv
//
//  Created by Daniel Spinosa on 4/29/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//
//  You want Shelby Data?  You come here.  Nowhere else.

#import <Foundation/Foundation.h>
#import "DisplayChannel+Helper.h"
#import "User+Helper.h"

@class Frame;

extern NSString * const kShelbyOfflineLikesID;
extern NSString * const kShelbyNotificationFacebookConnectCompleted;
extern NSString * const kShelbyNotificationTwitterConnectCompleted;
extern NSString * const kShelbyNotificationUserSignupDidSucceed;
extern NSString * const kShelbyNotificationUserSignupDidFail;
extern NSString * const kShelbyNotificationUserUpdateDidSucceed;
extern NSString * const kShelbyNotificationUserUpdateDidFail;

//NB: delegate methods always called on the main thread
@protocol ShelbyDataMediatorProtocol <NSObject>
// channels
- (void)fetchGlobalChannelsDidCompleteWith:(NSArray *)channels fromCache:(BOOL)cached;
- (void)fetchGlobalChannelsDidCompleteWithError:(NSError *)error;
// channel entries
- (void)fetchEntriesDidCompleteForChannel:(DisplayChannel *)channel
                                     with:(NSArray *)channelEntries fromCache:(BOOL)cached;
- (void)fetchEntriesDidCompleteForChannel:(DisplayChannel *)channel
                                withError:(NSError *)error;
- (void)fetchOfflineLikesDidCompleteForChannel:(DisplayChannel *)channel
                                          with:(NSArray *)channelEntries;
- (void)removeFrame:(Frame *)frame
        fromChannel:(DisplayChannel *)channel;

// User
- (void)userWasUpdated;

// Login
- (void)loginUserDidComplete;
- (void)loginUserDidCompleteWithError:(NSString *)errorMessage;

// Facebook
- (void)facebookConnectDidComplete;
- (void)facebookConnectDidCompleteWithError:(NSString *)errorMessage;

// Twitter
- (void)twitterConnectDidComplete;
- (void)twitterConnectDidCompleteWithError:(NSString *)errorMessage;
@end

@interface ShelbyDataMediator : NSObject

@property (nonatomic, weak) id<ShelbyDataMediatorProtocol> delegate;

+(ShelbyDataMediator *)sharedInstance;

//fetching
- (void)fetchGlobalChannels;
- (void)fetchEntriesInChannel:(DisplayChannel *)channel sinceEntry:(NSManagedObject *)entry;
- (User *)fetchAuthenticatedUserOnMainThreadContext;
- (User *)fetchAuthenticatedUserOnMainThreadContextWithForceRefresh:(BOOL)forceRefresh;
- (void)fetchAllUnsyncedLikes;
- (DisplayChannel *)fetchDisplayChannelOnMainThreadContextForRollID:(NSString *)rollID;
- (DisplayChannel *)fetchDisplayChannelOnMainThreadContextForDashboardID:(NSString *)dashboardID;
//return user if cached, otherwise returns nil and calls completion block async after fetching user remotely
- (User *)fetchUserWithID:(NSString *)userID
                inContext:(NSManagedObjectContext *)context
               completion:(void (^)(User *fetchedUser))completion;

-(void)logoutCurrentUser;

- (void)loginUserWithEmail:(NSString *)email password:(NSString *)password;
- (void)loginUserFacebook;

- (void)syncLikes; // Syncs unsycs likes after user logs in

- (void)userAskForFacebookPublishPermissions;
- (void)openFacebookSessionWithAllowLoginUI:(BOOL)allowLoginUI;
- (void)connectTwitterWithViewController:(UIViewController *)viewController;

// Facebook Invite
- (void)inviteFacebookFriends;

- (void)updateUserName:(NSString *)name
              nickname:(NSString *)nickname
              password:(NSString *)password
                 email:(NSString *)email
                avatar:(UIImage *)avatar
            completion:(void (^)(NSError *error))completion;

// Signup process ONLY
- (void)createUserWithName:(NSString *)name
                  andEmail:(NSString *)email;
- (void)updateUserWithName:(NSString *)name
                  nickname:(NSString *)nickname
                  password:(NSString *)password
                     email:(NSString *)email
                    avatar:(UIImage *)avatar
                     rolls:(NSArray *)followRolls
                completion:(void (^)(NSError *error))completion;

//returns YES if the toggle should result in this frame being liked
//NB: does not guarantee async post will succeed
- (BOOL)toggleLikeForFrame:(Frame *)frame;

//do whatever it takes to get us to a clean state, guaranteed
- (void)nuclearCleanup;

//the single, shared context for use on the main thread
//we're using Thread Confinement for CoreData concurrency
//that is, each thread has it's own ManagedObjectContext, all sharing a single PersistentStoreCoordinator
- (NSManagedObjectContext *)mainThreadContext;

// use the following to operate on a background thread
// kick back to main thread where you can use mainThreadContext
//
// NB: The main thread and private queue contexts are already setup to listen
// for changes in the other context and automatically merge them.
//
// According to http://www.objc.io/issue-2/common-background-practices.html
// when you create a context with NSPrivateQueueConcurrencyType, you must perform all operations on the context
// via the context's -performBlock or -performBlockAndWait to ensure the operation runs on the private thread (b/c the context itself
// is managing it's own operation queue).
- (void)privateContextPerformBlock:(void (^)(NSManagedObjectContext *privateMOC))block;
- (void)privateContextPerformBlockAndWait:(void (^)(NSManagedObjectContext *privateMOC))block;


@end
