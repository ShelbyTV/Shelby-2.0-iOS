//
//  ShelbyAPIClient.h
//  Shelby.tv
//
//  Created by Daniel Spinosa on 6/5/13.
//  Copyright (c) 2013 Shelby TV. All rights reserved.
//

#import "DashboardEntry+Helper.h"
#import "User+Helper.h"

extern NSString * const kShelbyAPIParamNickname;
extern NSString * const kShelbyAPIParamEmail;
extern NSString * const kShelbyAPIParamPassword;
extern NSString * const kShelbyAPIParamPasswordConfirmation;
extern NSString * const kShelbyAPIParamName;
extern NSString * const kShelbyAPIParamAvatar;

typedef void (^shelby_api_request_complete_block_t)(id JSON, NSError *error);
typedef void (^shelby_api_shortlink_request_complete_block_t)(NSString *link, BOOL shortlinkDidFail);

@interface ShelbyAPIClient : NSObject

// -- User
+ (void)postSignupWithName:(NSString *)name
                  nickname:(NSString *)nickname
                  password:(NSString *)password
                  email:(NSString *)email
                  andBlock:(shelby_api_request_complete_block_t)completionBlock;

+ (void)postSignupWithName:(NSString *)name
                  email:(NSString *)email
                  andBlock:(shelby_api_request_complete_block_t)completionBlock;

+ (void)putUserWithParams:(NSDictionary *)params
                 andBlock:(shelby_api_request_complete_block_t)completionBlock;

+ (void)uploadUserAvatar:(UIImage *)avatar
                andBlock:(shelby_api_request_complete_block_t)completionBlock;

+ (void)loginUserWithEmail:(NSString *)email
                  password:(NSString *)password
                  andBlock:(shelby_api_request_complete_block_t)completionBlock;

+ (void)putGoogleAnalyticsClientID:(NSString *)clientID forUser:(User *)user;

+ (void)fetchUserForUserID:(NSString *)userID
                  andBlock:(shelby_api_request_complete_block_t)completionBlock;

// -- Video
+ (void)markUnplayableVideo:(NSString *)videoID;

// -- Channels
+ (void)fetchChannelsWithBlock:(shelby_api_request_complete_block_t)completionBlock;

+ (void)fetchDashboardEntriesForDashboardID:(NSString *)dashboardID
                                 sinceEntry:(DashboardEntry *)sinceEntry
                              withAuthToken:(NSString *)authToken
                                   andBlock:(shelby_api_request_complete_block_t)completionBlock;

// -- Rolls
+ (void)followRoll:(NSString *)rollID
     withAuthToken:(NSString *)authToken
          andBlock:(shelby_api_request_complete_block_t)completionBlock;

+ (void)unfollowRoll:(NSString *)rollID
       withAuthToken:(NSString *)authToken
            andBlock:(shelby_api_request_complete_block_t)completionBlock;

// -- Frames
+ (void)fetchFramesForRollID:(NSString *)rollID
                  sinceEntry:(Frame *)sinceFrame
                   withBlock:(shelby_api_request_complete_block_t)completionBlock;

+ (void)postUserLikedFrame:(NSString *)frameID
             withAuthToken:(NSString *)authToken
                  andBlock:(shelby_api_request_complete_block_t)completionBlock;

+ (void)postUserWatchedFrame:(NSString *)frameID
               withAuthToken:(NSString *)authToken;

// NB: deleting frame == unliking
+ (void)deleteFrame:(NSString *)frameID
      withAuthToken:(NSString *)authToken
           andBlock:(shelby_api_request_complete_block_t)completionBlock;

+ (void)getShortlinkForFrame:(Frame *)frame
               allowFallback:(BOOL)shouldFallbackToLongLink
                   withBlock:(shelby_api_shortlink_request_complete_block_t)completionBlock;

+ (void)rollFrame:(NSString *)frameID
         onToRoll:(NSString *)rollID
      withMessage:(NSString *)message
        authToken:(NSString *)authToken
         andBlock:(shelby_api_request_complete_block_t)completionBlock;

+ (void)shareFrame:(NSString *)frameID
toExternalDestinations:(NSArray *)destinations
       withMessage:(NSString *)message
      andAuthToken:(NSString *)authToken;

// -- OAuth
+ (void)postThirdPartyToken:(NSString *)provider
              withAccountID:(NSString *)accountID
                 oauthToken:(NSString *)token
                oauthSecret:(NSString *)secret
            shelbyAuthToken:(NSString *)authToken
                   andBlock:(shelby_api_request_complete_block_t)completionBlock;

@end
