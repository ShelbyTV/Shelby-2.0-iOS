//
//  User+Helper.h
//  Shelby.tv
//
//  Created by Daniel Spinosa on 4/30/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "User.h"

@interface User (Helper)

+ (User *)userForDictionary:(NSDictionary *)dict
                    inContext:(NSManagedObjectContext *)context;

//return the current, authenticated User, or nil if user isn't logged in
+(User *)currentAuthenticatedUserInContext:(NSManagedObjectContext *)moc;
+(User *)currentAuthenticatedUserInContext:(NSManagedObjectContext *)moc forceRefresh:(BOOL)forceRefresh;

+ (User *)updateUserWithFacebookUser:(NSDictionary *)facebookUser inContext:(NSManagedObjectContext *)moc;
// KP KP: TODO: once we move twitter handler stuff to data mediator, we can pass a context. For now, we'll just ask for a private context.
+ (User *)updateUserWithTwitterUsername:(NSString *)username andTwitterID:(NSString *)twitterID;

+ (NSMutableArray *)channelsForUserInContext:(NSManagedObjectContext *)moc;

- (BOOL)isTwitterConnected;
- (BOOL)isFacebookConnected;

@end
