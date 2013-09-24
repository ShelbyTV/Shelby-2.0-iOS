//
//  User+Helper.h
//  Shelby.tv
//
//  Created by Daniel Spinosa on 4/30/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "User.h"
#import "DisplayChannel+Helper.h"

#define USER_CHANNEL_STREAM_IDX 0
#define USER_CHANNEL_ROLL_IDX 1
#define USER_CHANNEL_LIKE_IDX 2

@interface User (Helper)

+ (User *)userForDictionary:(NSDictionary *)dict
                    inContext:(NSManagedObjectContext *)context;
// returns existing user with that ID or nil if one is not found
+ (User *)findUserWithID:(NSString *)userID
               inContext:(NSManagedObjectContext *)context;

//return the current, authenticated User, or nil if user isn't logged in
+ (User *)currentAuthenticatedUserInContext:(NSManagedObjectContext *)moc;
+ (User *)currentAuthenticatedUserInContext:(NSManagedObjectContext *)moc forceRefresh:(BOOL)forceRefresh;

//intelligently track session count via API
+ (void)sessionDidBecomeActive;
+ (void)sessionDidPause;

- (void)updateWithFacebookUser:(NSDictionary *)facebookUser;
// KP KP: TODO: once we move twitter handler stuff to data mediator, we can pass a context. For now, we'll just ask for a private context.
+ (User *)updateUserWithTwitterUsername:(NSString *)username andTwitterID:(NSString *)twitterID;

//use the USER_CHANNEL_*_IDX defines to make sense of this array
+ (NSMutableArray *)channelsForUserInContext:(NSManagedObjectContext *)moc;

- (BOOL)isTwitterConnected;
- (BOOL)isFacebookConnected;
- (BOOL)isNonShelbyFacebookUser;

- (BOOL)hasLikedVideoOfFrame:(Frame *)frame;
- (Frame *)likedFrameWithVideoOfFrame:(Frame *)frame;

- (DisplayChannel *)displayChannelForLikesRoll;
- (DisplayChannel *)displayChannelForSharesRoll;

- (NSURL *)avatarURL;

@end
