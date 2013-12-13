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

+ (void)putSessionVisitForUser:(User *)user
                     withBlock:(shelby_api_request_complete_block_t)completionBlock;

+ (void)uploadUserAvatar:(UIImage *)avatar
                andBlock:(shelby_api_request_complete_block_t)completionBlock;

+ (void)loginUserWithEmail:(NSString *)email
                  password:(NSString *)password
                  andBlock:(shelby_api_request_complete_block_t)completionBlock;

+ (void)putGoogleAnalyticsClientID:(NSString *)clientID forUser:(User *)user;

+ (void)fetchUserForUserID:(NSString *)userID
                  andBlock:(shelby_api_request_complete_block_t)completionBlock;


// -- ABTest
+ (void)fetchABTestWithBlock:(shelby_api_request_complete_block_t)completionBlock;

// -- Video
+ (void)markUnplayableVideo:(NSString *)videoID;
+ (void)fetchAllLikersOfVideo:(NSString *)videoID withBlock:(shelby_api_request_complete_block_t)completionBlock;

// -- Channels
+ (void)fetchGlobalChannelsWithBlock:(shelby_api_request_complete_block_t)completionBlock;

+ (void)fetchDashboardEntriesForDashboardID:(NSString *)dashboardID
                                 sinceEntry:(DashboardEntry *)sinceEntry
                              withAuthToken:(NSString *)authToken
                                   andBlock:(shelby_api_request_complete_block_t)completionBlock;

// -- Rolls
+ (void)fetchRollFollowingsForUser:(User *)user
                     withAuthToken:(NSString *)authToken
                          andBlock:(shelby_api_request_complete_block_t)completionBlock;

+ (void)followRoll:(NSString *)rollID
     withAuthToken:(NSString *)authToken
          andBlock:(shelby_api_request_complete_block_t)completionBlock;

+ (void)unfollowRoll:(NSString *)rollID
       withAuthToken:(NSString *)authToken
            andBlock:(shelby_api_request_complete_block_t)completionBlock;

// -- Frame
+ (void)fetchFrameForFrameID:(NSString *)frameID
                   withBlock:(shelby_api_request_complete_block_t)completionBlock;

// -- DashboardEntry
+ (void)fetchDashboardEntryForDashboardID:(NSString *)dashboardID
                                 withBlock:(shelby_api_request_complete_block_t)completionBlock;

// -- Frames
+ (void)fetchFramesForRollID:(NSString *)rollID
                  sinceEntry:(Frame *)sinceFrame
                   withBlock:(shelby_api_request_complete_block_t)completionBlock;

+ (void)postUserLikedFrame:(NSString *)frameID
             withAuthToken:(NSString *)authToken
                  andBlock:(shelby_api_request_complete_block_t)completionBlock;

//Authentication is not required for this route,
//will be added automatically if user is logged in.
//Send compeleteWatch YES and/or include from/to times.
+ (void)postUserWatchedFrame:(NSString *)frameID
                  completely:(BOOL)completeWatch
                        from:(NSString *)fromTimeInSeconds
                          to:(NSString *)toTimeInSeconds;

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

+ (void)LoginWithFacebookAccountID:(NSString *)accountID
                        oauthToken:(NSString *)token
                          andBlock:(shelby_api_request_complete_block_t)completionBlock;

+ (void)signupWithFacebookAccountID:(NSString *)accountID
                         oauthToken:(NSString *)token
                           andBlock:(shelby_api_request_complete_block_t)completionBlock;

// -- OAuth
+ (void)postThirdPartyToken:(NSString *)provider
              withAccountID:(NSString *)accountID
                 oauthToken:(NSString *)token
                oauthSecret:(NSString *)secret
            shelbyAuthToken:(NSString *)authToken
                   andBlock:(shelby_api_request_complete_block_t)completionBlock;

@end
