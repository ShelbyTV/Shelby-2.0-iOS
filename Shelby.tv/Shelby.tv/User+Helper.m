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
#import "ShelbyAnalyticsClient.h"
#import "ShelbyAPIClient.h"
#import "ShelbyDataMediator.h"

#define ONE_HOUR_AGO -1*60*60

NSString * const kShelbyCoreDataEntityUser = @"User";
NSString * const kShelbyCoreDataEntityUserIDPredicate = @"userID == %@";

@implementation User (Helper)

+ (User *)userForDictionary:(NSDictionary *)dict inContext:(NSManagedObjectContext *)context
{
    NSString *userID = dict[@"id"];
    User *user = [User findUserWithID:userID inContext:context];

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

    NSString *nick = dict[@"nickname"];
    if (nick){
        user.nickname = nick;
    }
    NSString *name = [dict[@"name"] nilOrSelfWhenNotNull];
    if (name) {
        user.name = name;
    }
    
    NSString *email = [dict[@"primary_email"] nilOrSelfWhenNotNull];
    if (email) {
        user.email = email;
    }
    
    NSString *token = dict[@"authentication_token"];
    if (token) {
        user.token = token;
    }

    if ([[dict allKeys] indexOfObject:@"has_shelby_avatar"] != NSNotFound) {
        user.hasShelbyAvatar = dict[@"has_shelby_avatar"];
    }
    

    //auths
    NSArray *authentications = dict[@"authentications"];
    if([authentications isKindOfClass:[NSArray class]]){
        // Resetting old auths:
        user.twitterNickname = nil;
        user.twitterUID = nil;
        user.facebookNickname = nil;
        user.facebookName = nil;
        user.facebookUID = nil;
        user.tumblrNickname = nil;
        user.tumblrUID = nil;

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

+ (User *)findUserWithID:(NSString *)userID
               inContext:(NSManagedObjectContext *)context
{
    User *user = [self fetchOneEntityNamed:kShelbyCoreDataEntityUser
                           withIDPredicate:kShelbyCoreDataEntityUserIDPredicate
                                     andID:userID
                                 inContext:context];
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
    User *user = [User currentAuthenticatedUserInContext:[[ShelbyDataMediator sharedInstance] mainThreadContext]];
    user.twitterNickname = username;
    user.twitterUID = twitterID;
    
    return user;
}

+ (User *)currentAuthenticatedUserInContext:(NSManagedObjectContext *)moc
{
    return [User currentAuthenticatedUserInContext:moc forceRefresh:NO];
}

+ (User *)currentAuthenticatedUserInContext:(NSManagedObjectContext *)moc forceRefresh:(BOOL)forceRefresh
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

+ (NSDictionary *)streamDictionaryForMyStream:(User *)loggedInUser
{
    if (!loggedInUser) {
        return nil;
    } else {
        return [User dictionaryForUserChannel:loggedInUser.userID withIDKey:@"user_id" displayTitle:@"Stream" displayColor:kShelbyColorMyStreamColorString];
    }
}


+ (DisplayChannel *)displayChannelForMyStream:(User *)loggedInUser withStreamDictionary:(NSDictionary *)streamDict inContext:(NSManagedObjectContext *)moc
{
    if (!loggedInUser) {
        return nil;
    }
    
    DisplayChannel *myStreamChannel = nil;
    if (streamDict) {
        myStreamChannel = [DisplayChannel channelForDashboardDictionary:streamDict withOrder:0 inContext:moc];
    }
    
    return myStreamChannel;
}

// The array returned here corresponds to the defines in the header
+ (NSMutableArray *)channelsForUserInContext:(NSManagedObjectContext *)moc
{
    User *loggedInUser = [self currentAuthenticatedUserInContext:moc];
    if (!loggedInUser) {
        return [@[] mutableCopy];
    }
    
    NSMutableArray *channels = [@[] mutableCopy];

    NSDictionary *streamDict = [User streamDictionaryForMyStream:loggedInUser];
    if (streamDict) {
        DisplayChannel *myStreamChannel = [User displayChannelForMyStream:loggedInUser withStreamDictionary:streamDict inContext:moc];
        if (myStreamChannel) {
            [channels addObject:myStreamChannel];
        } else {
            STVAssert(myStreamChannel, @"failed to create stream channel for user");
        }
    }
    
    NSDictionary *rollDict = [User dictionaryForUserChannel:loggedInUser.publicRollID withIDKey:@"id" displayTitle:@"My Shares" displayColor:kShelbyColorMyRollColorString];
    if (streamDict) {
        DisplayChannel *myRollChannel = [DisplayChannel channelForRollDictionary:rollDict withOrder:1 inContext:moc];
        if (myRollChannel) {
            [channels addObject:myRollChannel];
        } else {
            STVAssert(myRollChannel, @"failed to create roll channel for user");
        }
    }

    NSDictionary *likeDict = [User dictionaryForUserChannel:loggedInUser.likesRollID withIDKey:@"id"  displayTitle:@"My Likes" displayColor:kShelbyColorLikesRedString];
    if (likeDict) {
        DisplayChannel *myLikesChannel = [DisplayChannel channelForRollDictionary:likeDict withOrder:1 inContext:moc];
        if (myLikesChannel) {
            [channels addObject:myLikesChannel];            
        } else {
            STVAssert(myLikesChannel, @"failed to create likes channel for user");
        }
    }
    
    NSError *err;
    [moc save:&err];
    STVDebugAssert(!err, @"context save saving user channels...");
    if (err) {
        [ShelbyAnalyticsClient sendEventWithCategory:kAnalyticsCategoryIssues
                                              action:kAnalyticsIssueContextSaveError
                                               label:[NSString stringWithFormat:@"-[channelsForUserInContext:] error: %@", err]];
    }

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

- (BOOL)isNonShelbyFacebookUser
{
    return [self.userType isEqualToNumber:@1] && self.facebookNickname != nil;
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

- (DisplayChannel *)displayChannelForMyStream
{
    NSManagedObjectContext *moc = [[ShelbyDataMediator sharedInstance] mainThreadContext];
    User *loggedInUser = [User currentAuthenticatedUserInContext:moc];
    return [User displayChannelForMyStream:loggedInUser
                      withStreamDictionary:[User streamDictionaryForMyStream:loggedInUser]
                                 inContext:moc];
}

- (DisplayChannel *)displayChannelForSharesRoll
{
    Roll *sharesRoll = [Roll rollWithID:self.publicRollID inContext:self.managedObjectContext];
    if (sharesRoll) {
        return sharesRoll.displayChannel;
    }
    return nil;
}

-(NSURL *)avatarURL
{
    if ([self.hasShelbyAvatar boolValue]) {
        return [NSURL URLWithString:[NSString stringWithFormat:@"http://s3.amazonaws.com/shelby-gt-user-avatars/sq192x192/%@", self.userID]];
    } else {
        return [NSURL URLWithString:self.userImage];
    }
}

+ (void)sessionDidBecomeActive
{
    User *currentUser = [User currentAuthenticatedUserInContext:[[ShelbyDataMediator sharedInstance] mainThreadContext]];
    if (currentUser) {
        NSDate *sessionPausedAt = [[NSUserDefaults standardUserDefaults] objectForKey:[User userDefaultsSessionKeyFor:currentUser]];
        if (!sessionPausedAt || [sessionPausedAt timeIntervalSinceNow] < ONE_HOUR_AGO) {
            [ShelbyAPIClient putSessionVisitForUser:currentUser withBlock:nil];
        }
    }

}

+ (void)sessionDidPause
{
    User *currentUser = [User currentAuthenticatedUserInContext:[[ShelbyDataMediator sharedInstance] mainThreadContext]];
    if (currentUser) {
        [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:[User userDefaultsSessionKeyFor:currentUser]];
    }
}

+ (NSString *)userDefaultsSessionKeyFor:(User *)user
{
    return [NSString stringWithFormat:@"sessionPausedByUser:%@", user.userID];
}

#pragma mark - Roll Following
- (void)updateRollFollowingsForArray:(NSArray *)rollsArray
{
    self.rollFollowings = @"";
    for (NSDictionary *rollInfo in rollsArray) {
        if (rollInfo[@"id"]) {
            [self didFollowRoll:rollInfo[@"id"]];
        }
    }
}

- (BOOL)isFollowing:(NSString *)rollID
{
    STVAssert(rollID, @"rollID must not be nil");
    return [self.rollFollowings rangeOfString:rollID].location != NSNotFound;
}

- (void)didFollowRoll:(NSString *)rollID
{
    if (![self isFollowing:rollID]) {
        self.rollFollowings = [self.rollFollowings stringByAppendingString:[NSString stringWithFormat:@"%@;", rollID]];
    }
}

- (void)didUnfollowRoll:(NSString *)rollID
{
    if ([self isFollowing:rollID]) {
        self.rollFollowings = [self.rollFollowings stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@;", rollID] withString:@""];
    }
}


@end
