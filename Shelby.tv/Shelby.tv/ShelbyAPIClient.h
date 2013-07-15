//
//  ShelbyAPIClient.h
//  Shelby.tv
//
//  Created by Daniel Spinosa on 6/5/13.
//  Copyright (c) 2013 Shelby TV. All rights reserved.
//

#import "DashboardEntry+Helper.h"

typedef void (^shelby_api_request_complete_block_t)(id JSON, NSError *error);
typedef void (^shelby_api_shortlink_request_complete_block_t)(NSString *link, BOOL shortlinkDidFail);

@interface ShelbyAPIClient : NSObject

// -- User
+ (void)postSignupWithName:(NSString *)name
                  nickname:(NSString *)nickname
                  password:(NSString *)password
                  andEmail:(NSString *)email;

+ (void)loginUserWithEmail:(NSString *)email
                  password:(NSString *)password
                  andBlock:(shelby_api_request_complete_block_t)completionBlock;

+ (void)putGoogleAnalyticsClientID:(NSString *)clientID;

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
