//
//  ShelbyAPIClient.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 12/5/12.
//  Copyright (c) 2012 Shelby TV. All rights reserved.
//

#import "DashboardEntry+Helper.h"

typedef void (^shelby_api_request_complete_block_t)(id JSON, NSError *error);

@interface ShelbyAPIClient : NSObject

/// Authentication
+ (void)postAuthenticationWithEmail:(NSString *)email andPassword:(NSString *)password;
+ (void)postSignupWithName:(NSString *)name nickname:(NSString *)nickname password:(NSString *)password andEmail:(NSString *)email;

/// Google Analytics
+ (void)putGoogleAnalyticsClientID:(NSString *)clientID;

/// Stream
+ (void)getMoreFramesInStream:(NSString *)skipParam;

// User
+ (void)fetchRollForUser:(NSString *)rollID withBlock:(shelby_api_request_complete_block_t)completionBlock;

/// Video
+ (void)markUnplayableVideo:(NSString *)videoID;

/// Likes
+ (void)getLikes;
+ (void)getMoreFramesInLikes:(NSString *)skipParam;

/// Personal Roll
+ (void)getPersonalRoll;
+ (void)getMoreFramesInPersonalRoll:(NSString *)skipParam;

// Login
+ (void)loginUserWithEmail:(NSString *)email
                  password:(NSString *)password
                 andBlock:(shelby_api_request_complete_block_t)completionBlock;

/// Channels
+ (void)fetchChannelsWithBlock:(shelby_api_request_complete_block_t)completionBlock;
+ (void)fetchDashboardEntriesForDashboardID:(NSString *)dashboardID
                                 sinceEntry:(DashboardEntry *)sinceEntry
                               andAuthToken:(NSString *)authToken
                                  withBlock:(shelby_api_request_complete_block_t)completionBlock;

+ (void)fetchFramesForRollID:(NSString *)rollID
                  sinceEntry:(Frame *)sinceFrame
                   withBlock:(shelby_api_request_complete_block_t)completionBlock;
/// Liking
+ (void)postUserLikedFrame:(NSString *)frameID userToken:(NSString *)authToken withBlock:(shelby_api_request_complete_block_t)completionBlock;
//+ (void)postFrameToLikes:(NSString *)frameID;

/// Rolling
+ (void)postFrameToPersonalRoll:(NSString*)requestString;

/// Sharing
+ (void)postShareFrameToSocialNetworks:(NSString*)requestString;

/// Send Third Party Token
+ (void)postThirdPartyToken:(NSString *)provider accountID:(NSString *)accountID token:(NSString *)token andSecret:(NSString *)secret;

@end
