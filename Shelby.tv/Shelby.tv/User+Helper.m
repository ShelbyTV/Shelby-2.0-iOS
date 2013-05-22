//
//  User+Helper.m
//  Shelby.tv
//
//  Created by Daniel Spinosa on 4/30/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "User+Helper.h"

NSString * const kShelbyCoreDataEntityUser = @"User";

@implementation User (Helper)

+ (User *)userForDictionary:(NSDictionary *)dict inContext:(NSManagedObjectContext *)context
{
    //look for existing User
    NSString *userID = dict[@"id"];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:kShelbyCoreDataEntityUser];
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"userID == %@", userID];
    request.predicate = pred;
    request.fetchLimit = 1;
    NSError *error;
    NSArray *fetchedUsers = [context executeFetchRequest:request error:&error];
    if(error || !fetchedUsers){
        return nil;
    }
    
    User *user = nil;
    if([fetchedUsers count] == 1){
        user = fetchedUsers[0];
    } else {
        user = [NSEntityDescription insertNewObjectForEntityForName:kShelbyCoreDataEntityUser
                                              inManagedObjectContext:context];
        user.userID = userID;
        user.userImage = OBJECT_OR_NIL(dict[@"user_image"]);
        user.userType = OBJECT_OR_NIL(dict[@"user_type"]);
        user.publicRollID = dict[@"public_roll_id"];
        user.likesRollID = dict[@"watch_later_roll_id"];
    }
    
    user.nickname = dict[@"nickname"];
    user.name = OBJECT_OR_NIL(dict[@"name"]);
    user.token = dict[@"authentication_token"];
    
    // Resetting all auths:
    user.twitterNickname = nil;
    user.twitterUID = nil;
    user.facebookNickname = nil;
    user.facebookUID = nil;
    user.tumblrNickname = nil;
    user.tumblrUID = nil;

    //auths
    NSArray *authentications = dict[@"authentications"];
    if([authentications isKindOfClass:[NSArray class]]){
        for (NSDictionary *authDict in authentications) {
            NSString *provider = authDict[@"provider"];
            if([provider isEqualToString:@"twitter"]){
                user.twitterNickname = OBJECT_OR_NIL(authDict[@"nickname"]);
                user.twitterUID = OBJECT_OR_NIL(authDict[@"uid"]);
            } else if([provider isEqualToString:@"facebook"]){
                user.facebookNickname = OBJECT_OR_NIL(authDict[@"nickname"]);
                user.facebookUID = OBJECT_OR_NIL(authDict[@"uid"]);
            } else if([provider isEqualToString:@"tumblr"]){
                user.tumblrNickname = OBJECT_OR_NIL(authDict[@"nickname"]);
                user.tumblrUID = OBJECT_OR_NIL(authDict[@"uid"]);
            }
        }
    }
    
    return user;
}

+ (User *)updateUserWithFacebookUser:(NSDictionary *)facebookUser inContext:(NSManagedObjectContext *)moc
{
    User *user = [User currentAuthenticatedUserInContext:moc];
    user.facebookUID = facebookUser[@"id"];
    user.facebookNickname = facebookUser[@"name"];
  
    return user;
}


+(User *)currentAuthenticatedUserInContext:(NSManagedObjectContext *)moc
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:kShelbyCoreDataEntityUser];
    request.fetchLimit = 1;
  
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"token.length > 0"];
    [request setPredicate:predicate];
    
    NSArray *results = [moc executeFetchRequest:request error:nil];
    
    return [results count] ? results[0] : nil;
}

- (BOOL)isTwitterConnected
{
    return self.twitterNickname != nil;
}

- (BOOL)isFacebookConnected
{
    return self.facebookNickname != nil;
}

@end
