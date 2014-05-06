//
//  ShelbyAPIClient.m
//  Shelby.tv
//
//  Created by Daniel Spinosa on 6/5/13.
//  Copyright (c) 2013 Shelby TV. All rights reserved.
//

#import "ShelbyAPIClient.h"
#import "AFNetworking.h"
#import "Frame+Helper.h"
#import "Video+Helper.h"
#import "ShelbyDataMediator.h"
#import "UIImage+Scale.h"
#import "ShelbyAnalyticsClient.h"

#import "Reachability.h"

#ifdef DEBUG
    NSString * const kShelbyAPIBaseURL =                    @"https://api.shelby.tv/";
    //live API: "https://api.shelby.tv/"
    //staging API: "http://api.staging.shelby.tv/"
#else
    NSString * const kShelbyAPIBaseURL =                    @"https://api.shelby.tv/";  // DON'T TOUCH
#endif

NSString * const DELETE =  @"DELETE";
NSString * const kShelbyAPIDeleteFramePath =                @"v1/frame/%@";
NSString * const GET =     @"GET";
NSString * const kShelbyAPIGetShortLinkPath =               @"v1/frame/%@/short_link";
NSString * const kShelbyAPIGetRollFramesPath =              @"v1/roll/%@/frames";
NSString * const kShelbyAPIGetAllChannelsPath =             @"v1/roll/featured";
NSString * const kShelbyAPIGetChannelDashboardEntriesPath = @"v1/user/%@/dashboard";
NSString * const kShelbyAPIGetUserPath =                    @"v1/user/%@";
NSString * const kShelbyAPIGetRollsUserFollows =            @"v1/user/%@/rolls/following";
NSString * const kShelbyAPIGetAllLikersOfVideo =            @"v1/video/%@/likers";
NSString * const kShelbyAPIGetFramePath =                   @"v1/frame/%@?include_children=true";
NSString * const kShelbyAPIGetDashboardPath =               @"v1/dashboard/%@?include_children=true";
NSString * const kShelbyAPIGetSignout =                     @"signout.json";
NSString * const POST =    @"POST";
NSString * const kShelbyAPIPostFrameLikePath =              @"v1/frame/%@/like";
NSString * const kShelbyAPIPostExternalShare =              @"v1/frame/%@/share";
NSString * const kShelbyAPIPostFrameWatchedPath =           @"v1/frame/%@/watched";
NSString * const kShelbyAPIPostFrameToRollPath =            @"v1/roll/%@/frames";
NSString * const kShelbyAPIPostRollFollow =                 @"v1/roll/%@/join";
NSString * const kShelbyAPIPostRollUnfollow =               @"v1/roll/%@/leave";
NSString * const kShelbyAPIPostLoginPath =                  @"v1/token";
NSString * const kShelbyAPIPostThirdPartyTokenPath =        @"v1/token";
NSString * const kShelbyAPIPostSignupPath =                 @"v1/user";
NSString * const kShelbyAPIPostDeviceTokenPath =            @"v1/user/%@/apn_token";
NSString * const PUT =     @"PUT";
NSString * const kShelbyAPIPutUserPath =                    @"v1/user/%@";
NSString * const kShelbyAPIPutUserSessionVisitPath =        @"v1/user/%@/visit";
NSString * const kShelbyAPIPutUnplayableVideoPath =         @"v1/video/%@/unplayable";

NSString * const kShelbyAPIParamAuthToken =                 @"auth_token";
NSString * const kShelbyAPIParamAuthTokenAction =           @"intention";
NSString * const kShelbyAPIParamChannelsSegment =           @"segment";
NSString * const kShelbyAPIParamClientIdentifierKey =       @"client_identifier";
NSString * const kShelbyAPIParamClientIdentifierValue =     @"iOS_iPhone";
//when value for this key is an array of N items, this param is turned into "destination[]" and listed N times
NSString * const kShelbyAPIParamDestinationArray =          @"destination";
NSString * const kShelbyAPIParamFrameId =                   @"frame_id";
NSString * const kShelbyAPIParamGAClientID =                @"google_analytics_client_id";
NSString * const kShelbyAPIParamLimit =                     @"limit";
NSString * const kShelbyAPIParamLoginEmail =                @"email";
NSString * const kShelbyAPIParamLoginPassword =             @"password";
NSString * const kShelbyAPIParamOAuthProviderName =         @"provider_name";
NSString * const kShelbyAPIParamOAuthUid =                  @"uid";
NSString * const kShelbyAPIParamOAuthToken =                @"token";
NSString * const kShelbyAPIParamOAuthSecret =               @"secret";
NSString * const kShelbyAPIParamSinceId =                   @"since_id";
NSString * const kShelbyAPIParamSkip =                      @"skip";
NSString * const kShelbyAPIParamText =                      @"text";
NSString * const kShelbyAPIParamTriggerRecommendations =    @"trigger_recs";
NSString * const kShelbyAPIParamRecommendationsVersion =    @"recs_version";
NSString * const kShelbyAPIParamNickname =                  @"nickname";
NSString * const kShelbyAPIParamEmail =                     @"primary_email";
NSString * const kShelbyAPIParamBio =                       @"dot_tv_description";
NSString * const kShelbyAPIParamPassword =                  @"password";
NSString * const kShelbyAPIParamPasswordConfirmation =      @"password_confirmation";
NSString * const kShelbyAPIParamName =                      @"name";
NSString * const kShelbyAPIParamAvatar =                    @"avatar";
NSString * const kShelbyAPIMultivariateTests =              @"v1/client_configuration/multivariate_tests";

@implementation ShelbyAPIClient

static AFHTTPClient *httpClient = nil;
static BOOL headOnly = YES;

+ (void)initialize {
    httpClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:kShelbyAPIBaseURL]];
    
    Reachability *reacher = [Reachability reachabilityWithHostName:@"api.shelby.tv"];
    NetworkStatus netStatus = [reacher currentReachabilityStatus];
    if (netStatus == NotReachable) {
        headOnly = YES;
        DLog(@"*** api.shelby.tv is unreachable; going HEAD ONLY ***");
    } else {
        headOnly = NO;
        DLog(@"*** api.shelby.tv seems fine; staying ONLINE ***");
    }
}

+ (BOOL)isHeadOnly
{
    return headOnly;
}

+ (NSURLRequest *)requestWithMethod:(NSString *)method
                            forPath:(NSString *)path
                withQueryParameters:(NSDictionary *)queryParams
                      shouldAddAuth:(BOOL)addAuthIfUserIsLoggedIn
{
    if (addAuthIfUserIsLoggedIn) {
        User __block *user;
        if ([NSThread isMainThread]) {
            NSManagedObjectContext *moc = [[ShelbyDataMediator sharedInstance] mainThreadContext];
            user = [User currentAuthenticatedUserInContext:moc];
        } else {
            DLog(@"Shelby API grabbing user on background thread... i don't LOVE this :-/");
            [[ShelbyDataMediator sharedInstance] privateContextPerformBlockAndWait:^(NSManagedObjectContext *privateMOC) {
                user = [User currentAuthenticatedUserInContext:privateMOC];
            }];
        }
        if (user) {
            STVAssert(user.token, @"expected user to have token");
            NSMutableDictionary *queryWithAuth = queryParams ? [queryParams mutableCopy] : [NSMutableDictionary dictionaryWithCapacity:1];
            queryWithAuth[kShelbyAPIParamAuthToken] = user.token;
            queryParams = queryWithAuth;
        }
    }
    return [httpClient requestWithMethod:method path:path parameters:queryParams];
}

+ (void)synchronousLogout
{
    if (headOnly) {
        DLog(@"Head Only NOOP");
        return;
    }
    
    [[httpClient operationQueue] cancelAllOperations];

    NSURLRequest *request = [self requestWithMethod:GET
                                            forPath:kShelbyAPIGetSignout
                                withQueryParameters:nil
                                      shouldAddAuth:NO];
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        //all good
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        [self clearAllCookies];
    }];
    
    [operation start];
    [operation waitUntilFinished];
}

// cancelAllOperations does not prevent cookies from getting set by operations
// that return after signout.  So we clear cookies on sigup and signin.
+ (void)clearAllCookies
{
    if (headOnly) {
        DLog(@"Head Only NOOP");
        return;
    }
    
    NSHTTPCookieStorage *cookieStore = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (NSHTTPCookie *cookie in cookieStore.cookies) {
        [cookieStore deleteCookie:cookie];
    }
}

#pragma mark - User
+ (void)postSignupWithUserParams:(NSDictionary *)userParams
                        andBlock:(shelby_api_request_complete_block_t)completionBlock
{
    if (headOnly) {
        DLog(@"Head Only NOOP");
        return;
    }
    
    [self clearAllCookies];
    
    NSURLRequest *request = [self requestWithMethod:POST
                                            forPath:kShelbyAPIPostSignupPath
                                withQueryParameters:userParams
                                      shouldAddAuth:NO];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        completionBlock(JSON, nil);
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        if (JSON) { // Backend passing error
            completionBlock(nil, JSON);
        } else {
            completionBlock(nil, error);
        }
    }];
    
    [operation start];

}

+ (void)postSignupWithName:(NSString *)name
                  nickname:(NSString *)nickname
                  password:(NSString *)password
                     email:(NSString *)email
                  andBlock:(shelby_api_request_complete_block_t)completionBlock
{
    if (headOnly) {
        DLog(@"Head Only NOOP");
        return;
    }
    
    NSDictionary *userParams = @{@"user": @{@"name": name,
                                            @"nickname": nickname,
                                            @"password": password,
                                            @"primary_email": email},
                                 kShelbyAPIParamClientIdentifierKey : kShelbyAPIParamClientIdentifierValue};
    [ShelbyAPIClient postSignupWithUserParams:userParams andBlock:completionBlock];
}

+ (void)postSignupWithName:(NSString *)name
                     email:(NSString *)email
                  andBlock:(shelby_api_request_complete_block_t)completionBlock

{
    if (headOnly) {
        DLog(@"Head Only NOOP");
        return;
    }
    
    NSDictionary *userParams = @{@"user": @{@"name": name,
                                            @"primary_email": email},
                                 @"generate_temporary_nickname_and_password" : @"1",
                                 kShelbyAPIParamClientIdentifierKey : kShelbyAPIParamClientIdentifierValue};
    [ShelbyAPIClient postSignupWithUserParams:userParams andBlock:completionBlock];
}

+ (void)postCreateAnonymousUser:(shelby_api_request_complete_block_t)completionBlock
{
    if (headOnly) {
        DLog(@"Head Only NOOP");
        return;
    }
    
    NSDictionary *userParams = @{@"anonymous": @(YES)};
    [ShelbyAPIClient postSignupWithUserParams:userParams andBlock:completionBlock];
}

+ (void)putUserWithParams:(NSDictionary *)params
                 andBlock:(shelby_api_request_complete_block_t)completionBlock
{
    if (headOnly) {
        DLog(@"Head Only NOOP");
        return;
    }
    
    User *user = [User currentAuthenticatedUserInContext:[[ShelbyDataMediator sharedInstance] mainThreadContext]];

    if (!user) {
        if (completionBlock) {
            completionBlock(nil, nil);
        }
        return;
    }
    NSMutableDictionary *userParams = [NSMutableDictionary dictionaryWithDictionary:params];
    userParams[kShelbyAPIParamAuthToken] = user.token;
    
    NSURLRequest *request = [self requestWithMethod:PUT
                                            forPath:[NSString stringWithFormat:kShelbyAPIPutUserPath, user.userID]
                                withQueryParameters:userParams
                                      shouldAddAuth:NO];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        // if the user succesfully added an email address for the first time, track that in Localytics
        if ((!user.email || ![user.email length])) {
            NSString *newEmail = [params valueForKey:kShelbyAPIParamEmail];
            if (newEmail && [newEmail length]) {
                [ShelbyAnalyticsClient sendLocalyticsEventForFinishConnectingAccountType:kLocalyticsAttributeValueAccountTypeEmail];
            }
        }

        completionBlock(JSON, nil);
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        if (JSON) { // Backend passing error
            completionBlock(nil, JSON);
        } else {
            completionBlock(nil, error);
        }
    }];
    
    [operation start];
}

+ (void)putSessionVisitForUser:(User *)user
                     withBlock:(shelby_api_request_complete_block_t)completionBlock
{
    if (headOnly) {
        DLog(@"Head Only NOOP");
        return;
    }
    
    STVAssert(user, @"must include user");

    NSMutableDictionary *userParams = [@{@"platform":@"ios",
                                       kShelbyAPIParamAuthToken: user.token} mutableCopy];

    NSURLRequest *request = [self requestWithMethod:PUT
                                            forPath:[NSString stringWithFormat:kShelbyAPIPutUserSessionVisitPath, user.userID]
                                withQueryParameters:userParams
                                      shouldAddAuth:NO];

    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        if (completionBlock) {
            completionBlock(JSON, nil);
        }
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        if (JSON) { // Backend passing error
            if (completionBlock) {
                completionBlock(nil, JSON);
            }
        } else {
            if (completionBlock) {
                completionBlock(nil, error);
            }
        }
    }];

    [operation start];
}

+ (void)uploadUserAvatar:(UIImage *)avatar andBlock:(shelby_api_request_complete_block_t)completionBlock
{
    if (headOnly) {
        DLog(@"Head Only NOOP");
        return;
    }
    
    User *user = [User currentAuthenticatedUserInContext:[[ShelbyDataMediator sharedInstance] mainThreadContext]];

    if (!user) {
        if (completionBlock) {
            completionBlock(nil, nil);
        }
        return;
    }
    NSDictionary *params = @{kShelbyAPIParamAuthToken: user.token};

    if (avatar.size.width > 512) {
        CGFloat scaleFactor = 512.f/avatar.size.width;
        CGSize newAvatarSize = CGSizeMake(roundf(scaleFactor * avatar.size.width), roundf(scaleFactor * avatar.size.height));
        avatar = [avatar scaleToSize:newAvatarSize];
    }
    NSData *imageData = UIImageJPEGRepresentation(avatar, 0.8);
    if ([imageData length] > 1000000) {
        imageData = UIImageJPEGRepresentation(avatar, 0.4);
    }

    NSURLRequest *request = [httpClient multipartFormRequestWithMethod:PUT path:[NSString stringWithFormat:kShelbyAPIPutUserPath, user.userID] parameters:params constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        [formData appendPartWithFileData:imageData name:kShelbyAPIParamAvatar fileName:@"ios_avatar.png" mimeType:@"image/png"];
    }];

    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        if (completionBlock) {
            completionBlock(JSON, nil);
        }
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        if (completionBlock) {
            completionBlock(JSON, error);
        }
    }];

    [operation start];
}

+ (void)loginUserWithEmail:(NSString *)email
                  password:(NSString *)password
                  andBlock:(shelby_api_request_complete_block_t)completionBlock
{
    if (headOnly) {
        DLog(@"Head Only NOOP");
        return;
    }
    
    STVAssert(email && password, @"required arguments email and password cannot be nil");
    
    [self clearAllCookies];
    
    NSDictionary *loginParams = @{kShelbyAPIParamLoginEmail: email,
                                  kShelbyAPIParamLoginPassword: password};
    NSURLRequest *request = [self requestWithMethod:POST forPath:kShelbyAPIPostLoginPath withQueryParameters:loginParams shouldAddAuth:NO];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        completionBlock(JSON, nil);
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        completionBlock(nil, error);
    }];
    
    [operation start];
}

+ (void)fetchUserForUserID:(NSString *)userID
                  andBlock:(shelby_api_request_complete_block_t)completionBlock
{
    if (headOnly) {
        DLog(@"Head Only NOOP");
        return;
    }
    
    if (!userID) {
        return;
    }
    
    NSURLRequest *request = [self requestWithMethod:GET
                                            forPath:[NSString stringWithFormat:kShelbyAPIGetUserPath, userID]
                                withQueryParameters:nil
                                      shouldAddAuth:NO];

    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        completionBlock(JSON, nil);
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        completionBlock(nil, error);
    }];
    
    [operation start];

}

+ (void)putGoogleAnalyticsClientID:(NSString *)clientID forUser:(User *)user
{
    if (headOnly) {
        DLog(@"Head Only NOOP");
        return;
    }
    
    if (!clientID || [clientID isEqualToString:@""]) {
        return;
    }

    NSDictionary *params = @{kShelbyAPIParamGAClientID: clientID,
                             kShelbyAPIParamAuthToken: user.token};
    NSURLRequest *request = [self requestWithMethod:PUT
                                            forPath:[NSString stringWithFormat:kShelbyAPIPutUserPath, user.userID]
                                withQueryParameters:params
                                      shouldAddAuth:NO];
 
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        // Do nothing
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        DLog(@"%@", error);
    }];
    
    [operation start];
}

#pragma mark - ABTest
+ (void)fetchABTestWithBlock:(shelby_api_request_complete_block_t)completionBlock
{
    if (headOnly) {
        DLog(@"Head Only NOOP");
        return;
    }
    
    NSURLRequest *request = [self requestWithMethod:GET
                                            forPath:kShelbyAPIMultivariateTests
                                withQueryParameters:nil
                                      shouldAddAuth:NO];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        completionBlock(JSON, nil);
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        completionBlock(nil, error);
    }];
    
    [operation start];
}

#pragma mark - Video
+ (void)markUnplayableVideo:(NSString *)videoID
{
    if (headOnly) {
        DLog(@"Head Only NOOP");
        return;
    }
    
    NSURLRequest *request = [self requestWithMethod:PUT
                                            forPath:[NSString stringWithFormat:kShelbyAPIPutUnplayableVideoPath, videoID]
                                withQueryParameters:nil
                                      shouldAddAuth:YES];

    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        // Do nothing
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        DLog(@"Problem marking video unplayable");
    }];
    
    [operation start];
}

+ (void)fetchAllLikersOfVideo:(NSString *)videoID withBlock:(shelby_api_request_complete_block_t)completionBlock
{
    if (headOnly) {
        DLog(@"Head Only NOOP");
        return;
    }
    
    NSURLRequest *request = [self requestWithMethod:GET
                                            forPath:[NSString stringWithFormat:kShelbyAPIGetAllLikersOfVideo, videoID]
                                withQueryParameters:nil
                                      shouldAddAuth:NO];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        completionBlock(JSON, nil);
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        completionBlock(nil, error);
    }];
    
    [operation start];
}

#pragma mark - Channels
+ (void)fetchGlobalChannelsWithBlock:(shelby_api_request_complete_block_t)completionBlock
{
    if (headOnly) {
        DLog(@"Head Fake");
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSDictionary *JSON = [NSJSONSerialization JSONObjectWithData:[@"{\"status\": 200,	\"result\": [{\"category_title\":\"iPhone Lineup\",\"rolls\":[],\"user_channels\":[{\"display_title\":\"Community\",\"user_id\":\"515d83ecb415cc0d1a025bfe\",\"display_description\":\"An old channel...\",\"display_thumbnail_ipad_src\":\"\",\"display_channel_color\":\"6FBE47\",\"include_in\":{\"iphone_standard\":true}},{\"display_title\":\"Featured\",\"user_id\":\"521264b4b415cc44c9000001\",\"display_description\":\"Featured members of the Shelby community\",\"display_thumbnail_ipad_src\":\"\",\"display_channel_color\":\"6FBE47\",\"include_in\":{\"iphone_standard\":true}}]}]}" dataUsingEncoding:NSUTF8StringEncoding]
                                                                 options:0
                                                                   error:nil];
            completionBlock(JSON, nil);
        });
        return;
    }
    
    static NSString *segmentForGlobalChannels = @"iphone_standard";
    NSDictionary *channelsParams = @{kShelbyAPIParamChannelsSegment:segmentForGlobalChannels
                                     };
    NSURLRequest *request = [self requestWithMethod:GET
                                            forPath:kShelbyAPIGetAllChannelsPath
                                withQueryParameters:channelsParams
                                      shouldAddAuth:NO];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        completionBlock(JSON, nil);
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        completionBlock(nil, error);
    }];
    [operation start];
}

+ (void)fetchFeaturedChannelsWithBlock:(shelby_api_request_complete_block_t)completionBlock
{
    if (headOnly) {
        DLog(@"Head Only NOOP");
        return;
    }
    
    static NSString *segmentForFeaturedChannels = @"onboarding";
    NSDictionary *channelsParams = @{kShelbyAPIParamChannelsSegment:segmentForFeaturedChannels
                                     };
    NSURLRequest *request = [self requestWithMethod:GET
                                            forPath:kShelbyAPIGetAllChannelsPath
                                withQueryParameters:channelsParams
                                      shouldAddAuth:YES];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        completionBlock(JSON, nil);
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        completionBlock(nil, error);
    }];
    [operation start];
}

+ (void)fetchDashboardEntriesForDashboardID:(NSString *)dashboardID
                                 sinceEntry:(DashboardEntry *)sinceEntry
                              withAuthToken:(NSString *)authToken
                                   andBlock:(shelby_api_request_complete_block_t)completionBlock
{
    if (headOnly) {
        DLog(@"Head Only NOOP");
        completionBlock(nil, nil);
        return;
    }
    
    NSMutableDictionary *params = [@{kShelbyAPIParamLimit: @"50",
                                     kShelbyAPIParamTriggerRecommendations: @"true",
                                     kShelbyAPIParamRecommendationsVersion: @"2"} mutableCopy];
    if (sinceEntry) {
        params[kShelbyAPIParamSinceId] = sinceEntry.dashboardEntryID;
    }
    if (authToken) {
        params[kShelbyAPIParamAuthToken] = authToken;
    }
    NSURLRequest *request = [self requestWithMethod:GET
                                            forPath:[NSString stringWithFormat:kShelbyAPIGetChannelDashboardEntriesPath, dashboardID]
                                withQueryParameters:params
                                      shouldAddAuth:NO];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        completionBlock(JSON, nil);
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        completionBlock(nil, error);
    }];
    
    [operation start];
}

#pragma mark - Rolls
+ (void)fetchRollFollowingsForUser:(User *)user
                     withAuthToken:(NSString *)authToken
                          andBlock:(shelby_api_request_complete_block_t)completionBlock
{
    if (headOnly) {
        DLog(@"Head Only NOOP");
        return;
    }
    
    NSMutableDictionary *params = [@{} mutableCopy];
    if (authToken) {
        params[kShelbyAPIParamAuthToken] = authToken;
    }
    
    NSURLRequest *request = [self requestWithMethod:GET
                                            forPath:[NSString stringWithFormat:kShelbyAPIGetRollsUserFollows, user.userID]
                                withQueryParameters:params
                                      shouldAddAuth:NO];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        completionBlock(JSON, nil);
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        completionBlock(nil, error);
    }];
    
    [operation start];
}

+ (void)followRoll:(NSString *)rollID
     withAuthToken:(NSString *)authToken
          andBlock:(shelby_api_request_complete_block_t)completionBlock
{
    if (headOnly) {
        DLog(@"Head Only NOOP");
        return;
    }
    
    NSMutableDictionary *params = [@{} mutableCopy];
    if (authToken) {
        params[kShelbyAPIParamAuthToken] = authToken;
    }

    NSURLRequest *request = [self requestWithMethod:POST
                                            forPath:[NSString stringWithFormat:kShelbyAPIPostRollFollow, rollID]
                                withQueryParameters:params
                                      shouldAddAuth:NO];

    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        completionBlock(JSON, nil);
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        completionBlock(nil, error);
    }];

    [operation start];
}

+ (void)unfollowRoll:(NSString *)rollID
       withAuthToken:(NSString *)authToken
            andBlock:(shelby_api_request_complete_block_t)completionBlock
{
    if (headOnly) {
        DLog(@"Head Only NOOP");
        return;
    }
    
    NSMutableDictionary *params = [@{} mutableCopy];
    if (authToken) {
        params[kShelbyAPIParamAuthToken] = authToken;
    }
    
    NSURLRequest *request = [self requestWithMethod:POST
                                            forPath:[NSString stringWithFormat:kShelbyAPIPostRollUnfollow, rollID]
                                withQueryParameters:params
                                      shouldAddAuth:NO];

    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        completionBlock(JSON, nil);
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        completionBlock(nil, error);
    }];

    [operation start];
}

#pragma mark - Frame
+ (void)fetchFrameForFrameID:(NSString *)frameID
                   withBlock:(shelby_api_request_complete_block_t)completionBlock
{
    if (headOnly) {
        DLog(@"Head Only NOOP");
        return;
    }
    
    NSURLRequest *request = [self requestWithMethod:GET
                                            forPath:[NSString stringWithFormat:kShelbyAPIGetFramePath, frameID]
                                withQueryParameters:nil
                                      shouldAddAuth:NO];

    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        completionBlock(JSON, nil);
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        completionBlock(nil, error);
    }];
    
    [operation start];
}

#pragma mark - Dashboard
// -- Dashboard
+ (void)fetchDashboardEntryForDashboardID:(NSString *)dashboardID
                                 withBlock:(shelby_api_request_complete_block_t)completionBlock
{
    if (headOnly) {
        DLog(@"Head Only NOOP");
        return;
    }
    
    NSURLRequest *request = [self requestWithMethod:GET
                                            forPath:[NSString stringWithFormat:kShelbyAPIGetDashboardPath, dashboardID]
                                withQueryParameters:nil
                                      shouldAddAuth:NO];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        completionBlock(JSON, nil);
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        completionBlock(nil, error);
    }];
    
    [operation start];
 
}

#pragma mark - Frames
+ (void)fetchFramesForRollID:(NSString *)rollID
                  sinceEntry:(Frame *)sinceFrame
                   withBlock:(shelby_api_request_complete_block_t)completionBlock
{
    if (headOnly) {
        DLog(@"Head Fake");
        completionBlock(nil, nil);
        return;
    }
    
    NSMutableDictionary *params = [@{} mutableCopy];
    if (sinceFrame) {
        params[kShelbyAPIParamSinceId] = sinceFrame.frameID;
    }
    NSURLRequest *request = [self requestWithMethod:GET
                                            forPath:[NSString stringWithFormat:kShelbyAPIGetRollFramesPath, rollID]
                                withQueryParameters:params
                                      shouldAddAuth:YES];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        completionBlock(JSON, nil);
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        completionBlock(nil, error);
    }];
    
    [operation start];
}

+ (void)postUserLikedFrame:(NSString *)frameID
             withAuthToken:(NSString *)authToken
                  andBlock:(shelby_api_request_complete_block_t)completionBlock
{
    if (headOnly) {
        DLog(@"Head Only NOOP");
        return;
    }
    
    NSDictionary *params = nil;
    if (authToken) {
        params = @{kShelbyAPIParamAuthToken: authToken};
    }
    NSURLRequest *request = [self requestWithMethod:PUT
                                            forPath:[NSString stringWithFormat:kShelbyAPIPostFrameLikePath, frameID]
                                withQueryParameters:params
                                      shouldAddAuth:YES];

    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        completionBlock(JSON, nil);
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        completionBlock(nil, error);
    }];
    
    [operation start];
}

+ (void)postUserWatchedFrame:(NSString *)frameID
                  completely:(BOOL)completeWatch
                        from:(NSString *)fromTimeInSeconds
                          to:(NSString *)toTimeInSeconds
{
    if (headOnly) {
        DLog(@"Head Only NOOP");
        return;
    }
    
    NSMutableDictionary *params = [@{} mutableCopy];
    if (completeWatch) {
        params[@"complete"] = @"1";
    } else {
        STVAssert(fromTimeInSeconds && toTimeInSeconds, @"expected valid times for incomplete watch");
    }
    if (fromTimeInSeconds && toTimeInSeconds) {
        params[@"start_time"] = fromTimeInSeconds;
        params[@"end_time"] = toTimeInSeconds;
    }

    NSURLRequest *request = [self requestWithMethod:POST
                                            forPath:[NSString stringWithFormat:kShelbyAPIPostFrameWatchedPath, frameID]
                                withQueryParameters:params
                                      shouldAddAuth:YES];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        //do nothing
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        //do nothing
    }];
    
    [operation start];
}

+ (void)deleteFrame:(NSString *)frameID
      withAuthToken:(NSString *)authToken
           andBlock:(shelby_api_request_complete_block_t)completionBlock
{
    if (headOnly) {
        DLog(@"Head Only NOOP");
        return;
    }
    
    NSDictionary *params = nil;
    if (authToken) {
        params = @{kShelbyAPIParamAuthToken: authToken};
    }
    NSURLRequest *request = [self requestWithMethod:DELETE
                                            forPath:[NSString stringWithFormat:kShelbyAPIDeleteFramePath, frameID]
                                withQueryParameters:params
                                      shouldAddAuth:YES];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        completionBlock(JSON, nil);
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        completionBlock(nil, error);
    }];
    
    [operation start];
}

+ (void)getShortlinkForFrame:(Frame *)frame
               allowFallback:(BOOL)shouldFallbackToLongLink
                   withBlock:(shelby_api_shortlink_request_complete_block_t)completionBlock
{
    if (headOnly) {
        DLog(@"Head Fake");
        if (shouldFallbackToLongLink && completionBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock([frame.video permalinkAtSource], YES);
            });
        }
        return;
    }
    
    NSURLRequest *request = [self requestWithMethod:GET
                                            forPath:[NSString stringWithFormat:kShelbyAPIGetShortLinkPath, frame.frameID]
                                withQueryParameters:nil
                                      shouldAddAuth:NO];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        NSString *shortLink = [[JSON valueForKey:@"result"] valueForKey:@"short_link"];
        if (completionBlock) {
            completionBlock(shortLink, NO);
        }
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        if (shouldFallbackToLongLink && completionBlock) {
            DLog(@"Failed getting short link for frame. Using long link.");
            completionBlock([frame longLink], YES);
        } else if (completionBlock) {
            completionBlock(nil, YES);
        }
    }];
    
    [operation start];
}

+ (void)rollFrame:(NSString *)frameID
         onToRoll:(NSString *)rollID
      withMessage:(NSString *)message
        authToken:(NSString *)authToken
         andBlock:(shelby_api_request_complete_block_t)completionBlock
{
    if (headOnly) {
        DLog(@"Head Only NOOP");
        return;
    }
    
    NSDictionary *params = @{kShelbyAPIParamFrameId: frameID,
                             kShelbyAPIParamText: message,
                             kShelbyAPIParamAuthToken: authToken};
    NSURLRequest *request = [self requestWithMethod:POST
                                            forPath:[NSString stringWithFormat:kShelbyAPIPostFrameToRollPath, rollID]
                                withQueryParameters:params
                                      shouldAddAuth:NO];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        DLog(@"Successfully rolled frame");
        if (completionBlock){
            completionBlock(JSON, nil);
        }
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        DLog(@"Problem rolling frame, %@", error);
        if (completionBlock){
            completionBlock(JSON, error);
        }
        
    }];
    
    [operation start];
}

+ (void)shareFrame:(NSString *)frameID
toExternalDestinations:(NSArray *)destinations
       withMessage:(NSString *)message
      andAuthToken:(NSString *)authToken
{
    if (headOnly) {
        DLog(@"Head Only NOOP");
        return;
    }
    
    NSDictionary *params = @{kShelbyAPIParamDestinationArray: destinations,
                             kShelbyAPIParamText: message,
                             kShelbyAPIParamAuthToken: authToken};
    NSURLRequest *request = [self requestWithMethod:POST
                                            forPath:[NSString stringWithFormat:kShelbyAPIPostExternalShare, frameID]
                                withQueryParameters:params
                                      shouldAddAuth:NO];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        DLog(@"Successfully shared frame to social networks");
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        DLog(@"Problem sharing frame to social networks: %@", error);
        
    }];
    
    [operation start];
}

+ (void)LoginWithFacebookAccountID:(NSString *)accountID
                        oauthToken:(NSString *)token
                          andBlock:(shelby_api_request_complete_block_t)completionBlock
{
    if (headOnly) {
        DLog(@"Head Only NOOP");
        return;
    }
    
    if (!accountID || !token) {
        return;
    }
    
    NSDictionary *params = @{kShelbyAPIParamOAuthProviderName: @"facebook",
                             kShelbyAPIParamOAuthUid: accountID,
                             kShelbyAPIParamOAuthToken: token,
                             kShelbyAPIParamAuthTokenAction : @"login"};
    
    [ShelbyAPIClient postThirdPartyTokenWithDictionary:params andBlock:completionBlock];

}

+ (void)signupWithFacebookAccountID:(NSString *)accountID
                         oauthToken:(NSString *)token
                           andBlock:(shelby_api_request_complete_block_t)completionBlock
{
    if (headOnly) {
        DLog(@"Head Only NOOP");
        return;
    }
    
    if (!accountID || !token) {
        return;
    }
    
    NSDictionary *params = @{kShelbyAPIParamOAuthProviderName: @"facebook",
                             kShelbyAPIParamOAuthUid: accountID,
                             kShelbyAPIParamOAuthToken: token,
                             kShelbyAPIParamAuthTokenAction : @"signup",
                             kShelbyAPIParamClientIdentifierKey : kShelbyAPIParamClientIdentifierValue};
    
    [ShelbyAPIClient postThirdPartyTokenWithDictionary:params andBlock:completionBlock];
    
}

#pragma mark - OAuth
+ (void)postThirdPartyToken:(NSString *)provider
              withAccountID:(NSString *)accountID
                 oauthToken:(NSString *)token
                oauthSecret:(NSString *)secret
            shelbyAuthToken:(NSString *)authToken
                   andBlock:(shelby_api_request_complete_block_t)completionBlock
{
    if (headOnly) {
        DLog(@"Head Only NOOP");
        return;
    }
    
    if (!provider || !accountID || !token || !authToken) {
        return;
    }
    
    NSDictionary *params = @{kShelbyAPIParamOAuthProviderName: provider,
                             kShelbyAPIParamOAuthUid: accountID,
                             kShelbyAPIParamOAuthToken: token,
                             kShelbyAPIParamAuthToken: authToken,
                             kShelbyAPIParamAuthTokenAction : @"connect" };
    if (secret) {
        NSMutableDictionary *mutableParams = [params mutableCopy];
        mutableParams[kShelbyAPIParamOAuthSecret] = secret;
        params = mutableParams;
    }
    
    [ShelbyAPIClient postThirdPartyTokenWithDictionary:params andBlock:completionBlock];
}

// This is a private method. Should only be called from this class. Not from the outside.s
+ (void)postThirdPartyTokenWithDictionary:(NSDictionary *)params
                                 andBlock:(shelby_api_request_complete_block_t)completionBlock
{
    if (headOnly) {
        DLog(@"Head Only NOOP");
        return;
    }
    
    NSURLRequest *request = [self requestWithMethod:POST
                                            forPath:kShelbyAPIPostThirdPartyTokenPath
                                withQueryParameters:params
                                      shouldAddAuth:NO];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        if (completionBlock) {
            completionBlock(JSON, nil);
        }
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        if ([response statusCode] == 403) {
            //403 == tried to connect an existing user
            NSDictionary *errorInfo = JSON[@"message"];
            if ([errorInfo isKindOfClass:[NSDictionary class]]) {
                NSInteger errorCode = [errorInfo[@"error_code"] intValue];
                if (errorCode == 403001) {
                    error = [NSError errorWithDomain:@"ShelbyAPIClient" code:errorCode userInfo:errorInfo];
                } else if (errorCode == 403004) {
                    error = [NSError errorWithDomain:@"ShelbyAPIClient" code:errorCode userInfo:errorInfo];
                } else {
                    error = [NSError errorWithDomain:@"ShelbyAPIClient" code:403002 userInfo:errorInfo];
                }
            }
        }
        if (completionBlock) {
            completionBlock(nil, error);
        }
    }];
    
    [operation start];
}

+ (void)deleteDeviceToken:(NSString *)token
                  forUser:(User *)user
                 andBlock:(shelby_api_request_complete_block_t)completionBlock

{
    if (headOnly) {
        DLog(@"Head Only NOOP");
        return;
    }
    
    [ShelbyAPIClient sendDeviceToken:token forUser:user withRequestMethod:DELETE andBlock:completionBlock];
}

+ (void)postDeviceToken:(NSString *)token
                forUser:(User *)user
               andBlock:(shelby_api_request_complete_block_t)completionBlock
{
    if (headOnly) {
        DLog(@"Head Only NOOP");
        return;
    }
    
    [ShelbyAPIClient sendDeviceToken:token forUser:user withRequestMethod:POST andBlock:completionBlock];
}

+ (void)sendDeviceToken:(NSString *)token
                forUser:(User *)user
      withRequestMethod:(NSString *)requestMethod
               andBlock:(shelby_api_request_complete_block_t)completionBlock
{
    if (headOnly) {
        DLog(@"Head Only NOOP");
        return;
    }
    
    if (!token || !user.token || !user.userID) {
        return;
    }

    NSURLRequest *request = [self requestWithMethod:requestMethod
                                            forPath:[NSString stringWithFormat:kShelbyAPIPostDeviceTokenPath, user.userID]
                                withQueryParameters:@{kShelbyAPIParamOAuthToken: token,
                                                      kShelbyAPIParamAuthToken: user.token}
                                      shouldAddAuth:YES];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        if (completionBlock) {
            completionBlock(JSON, nil);
        }
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        if (completionBlock) {
            completionBlock(nil, error);
        }
    }];
    
    [operation start];
}
@end
