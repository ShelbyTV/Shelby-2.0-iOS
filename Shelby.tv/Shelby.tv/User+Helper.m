//
//  User+Helper.m
//  Shelby.tv
//
//  Created by Daniel Spinosa on 4/30/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "User+Helper.h"
#import "DisplayChannel+Helper.h"
#import "Frame+Helper.h"
#import "NSManagedObject+Helper.h"
#import "NSObject+NullHelper.h"
#import "Roll+Helper.h"
#import "ShelbyDataMediator.h"

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
    user.facebookName = nil;
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
                user.facebookName = [authDict[@"name"] nilOrSelfWhenNotNull];
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

- (void)updateWithFacebookUser:(NSDictionary *)facebookUser
{
    self.facebookUID = facebookUser[@"id"];
    self.facebookNickname = facebookUser[@"username"];
    self.facebookName = facebookUser[@"name"];
}

+ (User *)updateUserWithTwitterUsername:(NSString *)username andTwitterID:(NSString *)twitterID
{
    User *user = [User currentAuthenticatedUserInContext:[[ShelbyDataMediator sharedInstance] createPrivateQueueContext]];
    user.twitterNickname = username;
    user.twitterUID = twitterID;
    
    return user;
}


+(User *)currentAuthenticatedUserInContext:(NSManagedObjectContext *)moc
{
    return [User currentAuthenticatedUserInContext:moc forceRefresh:NO];
}

+(User *)currentAuthenticatedUserInContext:(NSManagedObjectContext *)moc forceRefresh:(BOOL)forceRefresh
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:kShelbyCoreDataEntityUser];
    request.fetchLimit = 1;
  
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"token.length > 0"];
    [request setPredicate:predicate];
    
    NSArray *results = [moc executeFetchRequest:request error:nil];
    
    User *user = nil;
    if ([results count]) {
        user = results[0];
        
        if (forceRefresh) {
            [user.managedObjectContext refreshObject:user mergeChanges:YES];
        }
    }
    
    return user;
}

+ (NSDictionary *)dictionaryForUserChannel:(NSString *)channelID withIDKey:(NSString *)idKey displayTitle:(NSString *)displayTitle displayColor:(NSString *)displayColor
{
    if (!(idKey && channelID && displayColor && displayTitle)) {
        return nil;
    }
    
    return @{idKey : channelID, @"display_channel_color" : displayColor, @"display_description" :displayTitle, @"display_title" : displayTitle};
}

// The array returned here corresponds to the defines in the header
+ (NSMutableArray *)channelsForUserInContext:(NSManagedObjectContext *)moc
{
    User *loggedInUser = [self currentAuthenticatedUserInContext:moc];
    if (!loggedInUser) {
        return [@[] mutableCopy];
    }
    
    NSMutableArray *channels = [@[] mutableCopy];

    NSDictionary *streamDict = [User dictionaryForUserChannel:loggedInUser.userID withIDKey:@"user_id" displayTitle:@"Stream" displayColor:kShelbyColorMyStreamColorString];
    if (streamDict) {
        DisplayChannel *myStreamChannel = [DisplayChannel channelForDashboardDictionary:streamDict withOrder:0 inContext:moc];
        STVAssert(myStreamChannel, @"failed to create stream channel for user");
        [channels addObject:myStreamChannel];
    }
    
    NSDictionary *rollDict = [User dictionaryForUserChannel:loggedInUser.publicRollID withIDKey:@"id" displayTitle:@"My Shares" displayColor:kShelbyColorMyRollColorString];
    if (streamDict) {
        DisplayChannel *myRollChannel = [DisplayChannel channelForRollDictionary:rollDict withOrder:1 inContext:moc];
        STVAssert(myRollChannel, @"failed to create roll channel for user");
        [channels addObject:myRollChannel];
    }

    NSDictionary *likeDict = [User dictionaryForUserChannel:loggedInUser.likesRollID withIDKey:@"id"  displayTitle:@"My Likes" displayColor:kShelbyColorLikesRedString];
    if (likeDict) {
        DisplayChannel *myLikesChannel = [DisplayChannel channelForRollDictionary:likeDict withOrder:1 inContext:moc];
        STVAssert(myLikesChannel, @"failed to create likes channel for user");
        [channels addObject:myLikesChannel];
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

- (BOOL)hasLikedVideoOfFrame:(Frame *)frame
{
    return !![self likedFrameWithVideoOfFrame:frame];
}

- (Frame *)likedFrameWithVideoOfFrame:(Frame *)frame
{
    Frame *frameOnLikedRoll = [Frame frameWithVideoID:frame.video.videoID
                                         onRollWithID:self.likesRollID
                                            inContext:self.managedObjectContext];
    if (frameOnLikedRoll && ![frameOnLikedRoll.clientUnliked boolValue]) {
        return frameOnLikedRoll;
    }
    return nil;
}

- (DisplayChannel *)displayChannelForLikesRoll
{
    Roll *likesRoll = [Roll rollWithID:self.likesRollID inContext:self.managedObjectContext];
    if (likesRoll) {
        return likesRoll.displayChannel;
    }
    return nil;
}

@end
