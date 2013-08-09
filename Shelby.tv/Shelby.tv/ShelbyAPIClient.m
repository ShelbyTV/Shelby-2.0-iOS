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
#import "ShelbyAlert.h"
#import "ShelbyDataMediator.h"

NSString * const kShelbyAPIBaseURL =                        @"https://api.shelby.tv/";

NSString * const DELETE =  @"DELETE";
NSString * const kShelbyAPIDeleteFramePath =                @"v1/frame/%@";
NSString * const GET =     @"GET";
NSString * const kShelbyAPIGetShortLinkPath =               @"v1/frame/%@/short_link";
NSString * const kShelbyAPIGetRollFramesPath =              @"v1/roll/%@/frames";
NSString * const kShelbyAPIGetAllChannelsPath =             @"v1/roll/featured";
NSString * const kShelbyAPIGetChannelDashboardEntriesPath = @"v1/user/%@/dashboard";
NSString * const kShelbyAPIGetUserPath =                    @"v1/user/%@";
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
NSString * const PUT =     @"PUT";
NSString * const kShelbyAPIPutUserPath =                    @"v1/user/%@";
NSString * const kShelbyAPIPutUserSessionVisitPath =        @"v1/user/%@/visit";
NSString * const kShelbyAPIPutUnplayableVideoPath =         @"v1/video/%@/unplayable";

NSString * const kShelbyAPIParamAuthToken =                 @"auth_token";
NSString * const kShelbyAPIParamChannelsSegment =           @"segment";
//when value for this key is an array of N items, this param is turned into "destination[]" and listed N times
NSString * const kShelbyAPIParamDestinationArray =          @"destination";
NSString * const kShelbyAPIParamFrameId =                   @"frame_id";
NSString * const kShelbyAPIParamGAClientID =                @"google_analytics_client_id";
NSString * const kShelbyAPIParamLoginEmail =                @"email";
NSString * const kShelbyAPIParamLoginPassword =             @"password";
NSString * const kShelbyAPIParamOAuthProviderName =         @"provider_name";
NSString * const kShelbyAPIParamOAuthUid =                  @"uid";
NSString * const kShelbyAPIParamOAuthToken =                @"token";
NSString * const kShelbyAPIParamOAuthSecret =               @"secret";
NSString * const kShelbyAPIParamSinceId =                   @"since_id";
NSString * const kShelbyAPIParamSkip =                      @"skip";
NSString * const kShelbyAPIParamText =                      @"text";
NSString * const kShelbyAPIParamNickname =                  @"nickname";
NSString * const kShelbyAPIParamEmail =                     @"primary_email";
NSString * const kShelbyAPIParamPassword =                  @"password";
NSString * const kShelbyAPIParamPasswordConfirmation =      @"password_confirmation";
NSString * const kShelbyAPIParamName =                      @"name";
NSString * const kShelbyAPIParamAvatar =                    @"avatar";

@implementation ShelbyAPIClient

static AFHTTPClient *httpClient = nil;

+ (void)initialize {
    httpClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:kShelbyAPIBaseURL]];
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

#pragma mark - User
+ (void)postSignupWithUserParams:(NSDictionary *)userParams
                        andBlock:(shelby_api_request_complete_block_t)completionBlock
{
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
    NSDictionary *userParams = @{@"user": @{@"name": name,
                                            @"nickname": nickname,
                                            @"password": password,
                                            @"primary_email": email}};
    [ShelbyAPIClient postSignupWithUserParams:userParams andBlock:completionBlock];
}

+ (void)postSignupWithName:(NSString *)name
                     email:(NSString *)email
                  andBlock:(shelby_api_request_complete_block_t)completionBlock

{
//    NSString *clientID = (DEVICE_IPAD ? @"iOS_iPad" : @"iOS_iPhone");
    NSDictionary *userParams = @{@"user": @{@"name": name,
                                            @"primary_email": email},
                                            @"generate_temporary_nickname_and_password" : @"1",
                                            @"client_identifier" : @"iOS_iPhone"};

    [ShelbyAPIClient postSignupWithUserParams:userParams andBlock:completionBlock];
}

+ (void)putUserWithParams:(NSDictionary *)params
                 andBlock:(shelby_api_request_complete_block_t)completionBlock
{
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
    User *user = [User currentAuthenticatedUserInContext:[[ShelbyDataMediator sharedInstance] mainThreadContext]];

    if (!user) {
        if (completionBlock) {
            completionBlock(nil, nil);
        }
        return;
    }
    NSDictionary *params = @{kShelbyAPIParamAuthToken: user.token};

    NSData *imageData = UIImagePNGRepresentation(avatar);
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

#pragma mark - Video
+ (void)markUnplayableVideo:(NSString *)videoID
{
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

#pragma mark - Channels
+ (void)fetchChannelsWithBlock:(shelby_api_request_complete_block_t)completionBlock
{

    NSString *route = nil;
#ifdef SHELBY_ENTERPRISE
    route = @"ipad_vertical_one";
#else
    route = @"ipad_standard";
#endif

//    if (!DEVICE_IPAD) {
    route = @"iphone_standard";
//    }
    
    NSDictionary *channelsParams = @{kShelbyAPIParamChannelsSegment:route
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

+ (void)fetchDashboardEntriesForDashboardID:(NSString *)dashboardID
                                 sinceEntry:(DashboardEntry *)sinceEntry
                              withAuthToken:(NSString *)authToken
                                   andBlock:(shelby_api_request_complete_block_t)completionBlock
{
    NSMutableDictionary *params = [@{} mutableCopy];
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
+ (void)followRoll:(NSString *)rollID
     withAuthToken:(NSString *)authToken
          andBlock:(shelby_api_request_complete_block_t)completionBlock
{
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

#pragma mark - Frames
+ (void)fetchFramesForRollID:(NSString *)rollID
                  sinceEntry:(Frame *)sinceFrame
                   withBlock:(shelby_api_request_complete_block_t)completionBlock
{
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

// TODO: deal with sync likes after user logs in.
+ (void)postUserLikedFrame:(NSString *)frameID
             withAuthToken:(NSString *)authToken
                  andBlock:(shelby_api_request_complete_block_t)completionBlock
{
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

#pragma mark - OAuth
+ (void)postThirdPartyToken:(NSString *)provider
              withAccountID:(NSString *)accountID
                 oauthToken:(NSString *)token
                oauthSecret:(NSString *)secret
            shelbyAuthToken:(NSString *)authToken
                   andBlock:(shelby_api_request_complete_block_t)completionBlock
{
    if (!provider || !accountID || !token || !authToken) {
        return;
    }
    
    NSDictionary *params = @{kShelbyAPIParamOAuthProviderName: provider,
                             kShelbyAPIParamOAuthUid: accountID,
                             kShelbyAPIParamOAuthToken: token,
                             kShelbyAPIParamAuthToken: authToken};
    if (secret) {
        NSMutableDictionary *mutableParams = [params mutableCopy];
        mutableParams[kShelbyAPIParamOAuthSecret] = secret;
        params = mutableParams;
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
            NSString *currentNickname = errorInfo[@"current_user_nickname"];
            NSString *existingUserNickname = errorInfo[@"existing_other_user_nickname"];
            NSString *title = [NSString stringWithFormat:NSLocalizedString(@"ALREADY_LOGGED_IN_TITLE", @"--Already Logged In--"), currentNickname];
            NSString *message = [NSString stringWithFormat:NSLocalizedString(@"ALREADY_LOGGED_IN_MESSAGE", nil), existingUserNickname];
            ShelbyAlert *alert = [[ShelbyAlert alloc] initWithTitle:title
                                                                    message:message
                                                         dismissButtonTitle:NSLocalizedString(@"ALREADY_LOGGED_IN_BUTTON", nil)
                                                             autodimissTime:0
                                                                  onDismiss:nil];
            [alert show];
        }
        if (completionBlock) {
            completionBlock(JSON, error);
        }
    }];
    
    [operation start];
}

@end
