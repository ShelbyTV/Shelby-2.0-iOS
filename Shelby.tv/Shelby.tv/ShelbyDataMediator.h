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
- (void)fetchChannelsDidCompleteWith:(NSArray *)channels fromCache:(BOOL)cached;
- (void)fetchChannelsDidCompleteWithError:(NSError *)error;
// channel entries
- (void)fetchEntriesDidCompleteForChannel:(DisplayChannel *)channel
                                     with:(NSArray *)channelEntries fromCache:(BOOL)cached;
- (void)fetchEntriesDidCompleteForChannel:(DisplayChannel *)channel
                                withError:(NSError *)error;
- (void)fetchOfflineLikesDidCompleteForChannel:(DisplayChannel *)channel
                                          with:(NSArray *)channelEntries;

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
- (void)fetchChannels;
- (void)fetchEntriesInChannel:(DisplayChannel *)channel sinceEntry:(NSManagedObject *)entry;
- (User *)fetchAuthenticatedUserOnMainThreadContext;
- (User *)fetchAuthenticatedUserOnMainThreadContextWithForceRefresh:(BOOL)forceRefresh;
- (void)fetchAllUnsyncedLikes;
- (DisplayChannel *)fetchDisplayChannelOnMainThreadContextForRollID:(NSString *)rollID;
- (DisplayChannel *)fetchDisplayChannelOnMainThreadContextForDashboardID:(NSString *)dashboardID;
- (void)fetchUpvoterUser:(NSString *)userID inContect:(NSManagedObjectContext *)context;

-(void)logoutCurrentUser;

- (void)loginUserWithEmail:(NSString *)email password:(NSString *)password;

- (void)syncLikes; // Syncs unsycs likes after user logs in

- (void)userAskForFacebookPublishPermissions;
- (void)openFacebookSessionWithAllowLoginUI:(BOOL)allowLoginUI;
- (void)connectTwitterWithViewController:(UIViewController *)viewController;

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
-(void)nuclearCleanup;

//the single, shared context for use on the main thread
//we're using Thread Confinement for CoreData concurrency
//that is, each thread has it's own ManagedObjectContext, all sharing a single PersistentStoreCoordinator
-(NSManagedObjectContext *)mainThreadContext;

// use this when operating on background threads
// kick back to main thread where you can use mainThreadContext
-(NSManagedObjectContext *)createPrivateQueueContext;

@end
