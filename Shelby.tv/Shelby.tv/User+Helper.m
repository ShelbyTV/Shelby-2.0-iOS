//
//  User+Helper.m
//  Shelby.tv
//
//  Created by Daniel Spinosa on 4/30/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "User+Helper.h"
#import "DisplayChannel+Helper.h"

#import "NSManagedObject+Helper.h"
#import "NSObject+NullHelper.h"

NSString * const kShelbyCoreDataEntityUser = @"User";
NSString * const kShelbyCoreDataEntityUserIDPredicate = @"userID == %@";

@implementation User (Helper)

+ (User *)userForDictionary:(NSDictionary *)dict inContext:(NSManagedObjectContext *)context
{
    NSString *userID = dict[@"id"];
    User *user = [self fetchOneEntityNamed:kShelbyCoreDataEntityUser
                           withIDPredicate:kShelbyCoreDataEntityUserIDPredicate
                                     andID:userID
                                 inContext:context];

    if (!user) {
        user = [NSEntityDescription insertNewObjectForEntityForName:kShelbyCoreDataEntityUser
                                              inManagedObjectContext:context];
        user.userID = userID;
        user.userImage = [dict[@"user_image"] nilOrSelfWhenNotNull];
        user.userType = [dict[@"user_type"] nilOrSelfWhenNotNull];
    }
    
    NSString *publicRollID = dict[@"personal_roll_id"];
    if (publicRollID) {
        user.publicRollID = publicRollID;
    }
    
    NSString *likesRollID = dict[@"watch_later_roll_id"];
    if (likesRollID) {
        user.likesRollID = likesRollID;
    }
    
    user.nickname = dict[@"nickname"];
    user.name = [dict[@"name"] nilOrSelfWhenNotNull];
    
    NSString *token = dict[@"authentication_token"];
    if (token) {
        user.token = token;
    }
    
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
                user.twitterNickname = [authDict[@"nickname"] nilOrSelfWhenNotNull];
                user.twitterUID = [authDict[@"uid"] nilOrSelfWhenNotNull];
            } else if([provider isEqualToString:@"facebook"]){
                user.facebookNickname = [authDict[@"nickname"] nilOrSelfWhenNotNull];
                user.facebookUID = [authDict[@"uid"] nilOrSelfWhenNotNull];
            } else if([provider isEqualToString:@"tumblr"]){
                user.tumblrNickname = [authDict[@"nickname"] nilOrSelfWhenNotNull];
                user.tumblrUID = [authDict[@"uid"] nilOrSelfWhenNotNull];
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

+ (NSDictionary *)dictionaryForUserChannel:(NSString *)channelID withIDKey:(NSString *)idKey displayTitle:(NSString *)displayTitle displayColor:(NSString *)displayColor
{
    if (!(idKey && channelID && displayColor && displayTitle)) {
        return nil;
    }
    
    return @{idKey : channelID, @"display_channel_color" : displayColor, @"display_description" :displayTitle, @"display_title" : displayTitle};
}

+ (NSMutableArray *)channelsForUserInContext:(NSManagedObjectContext *)moc
{
    User *loggedInUser = [self currentAuthenticatedUserInContext:moc];
    if (!loggedInUser) {
        return [@[] mutableCopy];
    }
    
    NSMutableArray *channels = [@[] mutableCopy];

    NSDictionary *streamDict = [User dictionaryForUserChannel:loggedInUser.userID withIDKey:@"user_id" displayTitle:@"My Stream" displayColor:kShelbyColorMyStreamColor];
    if (streamDict) {
        DisplayChannel *myStreamChannel = [DisplayChannel channelForDashboardDictionary:streamDict withOrder:0 inContext:moc];
        if (myStreamChannel) {
            [channels addObject:myStreamChannel];
        }
    }
    
    NSDictionary *rollDict = [User dictionaryForUserChannel:loggedInUser.publicRollID withIDKey:@"id" displayTitle:@"My Roll" displayColor:kShelbyColorMyRollColor];
    if (streamDict) {
        DisplayChannel *myRollChannel = [DisplayChannel channelForRollDictionary:rollDict withOrder:1 inContext:moc];
        if (myRollChannel) {
            [channels addObject:myRollChannel];
        }
    }

    NSDictionary *likeDict = [User dictionaryForUserChannel:loggedInUser.likesRollID withIDKey:@"id"  displayTitle:@"My Likes" displayColor:kShelbyColorLikesRedString];
    if (likeDict) {
        DisplayChannel *myLikesChannel = [DisplayChannel channelForRollDictionary:likeDict withOrder:1 inContext:moc];
        if (myLikesChannel) {
            [channels addObject:myLikesChannel];
        }
    }
    
    NSError *error;
    [moc save:&error];
    STVAssert(!error, @"context save saving user channels...");
    
    return channels;
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
