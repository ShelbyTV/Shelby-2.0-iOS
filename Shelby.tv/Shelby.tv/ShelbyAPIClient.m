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
#import "ShelbyAlertView.h"
#import "ShelbyDataMediator.h"
#import "User+Helper.h"

NSString * const kShelbyAPIBaseURL =                        @"https://api.shelby.tv/";

NSString * const DELETE =  @"DELETE";
NSString * const kShelbyAPIDeleteFramePath =                @"v1/frame/%@";
NSString * const GET =     @"GET";
NSString * const kShelbyAPIGetShortLinkPath =               @"v1/frame/%@/short_link";
NSString * const kShelbyAPIGetRollFramesPath =              @"v1/roll/%@/frames";
NSString * const kShelbyAPIGetAllChannelsPath =             @"v1/roll/featured";
NSString * const kShelbyAPIGetChannelDashboardEntriesPath = @"v1/user/%@/dashboard";
NSString * const kShelbyAPIGetUser =                        @"v1/user/%@";
NSString * const POST =    @"POST";
NSString * const kShelbyAPIPostFrameLikePath =              @"v1/frame/%@/like";
NSString * const kShelbyAPIPostExternalShare =              @"v1/frame/%@/share";
NSString * const kShelbyAPIPostFrameWatchedPath =           @"v1/frame/%@/watched";
NSString * const kShelbyAPIPostFrameToRollPath =            @"v1/roll/%@/frames";
NSString * const kShelbyAPIPostLoginPath =                  @"v1/token";
NSString * const kShelbyAPIPostThirdPartyTokenPath =        @"v1/token";
NSString * const kShelbyAPIPostSignupPath =                 @"v1/user";
NSString * const PUT =     @"PUT";
NSString * const kShelbyAPIPutGAClientIdPath =              @"v1/user/%@";
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
        NSManagedObjectContext *moc = nil;
        if ([NSThread isMainThread]) {
            moc = [[ShelbyDataMediator sharedInstance] mainThreadContext];
        } else {
            moc = [[ShelbyDataMediator sharedInstance] createPrivateQueueContext];
        }
        User *user = [User currentAuthenticatedUserInContext:moc];
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
        completionBlock(nil, error);
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
    NSDictionary *userParams = @{@"user": @{@"name": name,
                                            @"primary_email": email},
                                            @"generate_temporary_nickname_and_password" : @"1"};

    [ShelbyAPIClient postSignupWithUserParams:userParams andBlock:completionBlock];
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
                                            forPath:[NSString stringWithFormat:kShelbyAPIGetUser, userID]
                                withQueryParameters:nil
                                      shouldAddAuth:NO];

    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        completionBlock(JSON, nil);
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        completionBlock(nil, error);
    }];
    
    [operation start];

}

// KP KP: TODO: this method is not getting called. Once we call it, make sure from what thread and get the correct moc.
+ (void)putGoogleAnalyticsClientID:(NSString *)clientID
{
    if (!clientID || [clientID isEqualToString:@""]) {
        return;
    }

    User *user = [User currentAuthenticatedUserInContext:[[ShelbyDataMediator sharedInstance] createPrivateQueueContext]];
    NSDictionary *params = @{kShelbyAPIParamGAClientID: clientID,
                             kShelbyAPIParamAuthToken: user.token};
    NSURLRequest *request = [self requestWithMethod:PUT
                                            forPath:[NSString stringWithFormat:kShelbyAPIPutGAClientIdPath, user.userID]
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

    if (!DEVICE_IPAD) {
        route = @"iphone_standard";
    }
    
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
               withAuthToken:(NSString *)authToken
{
    NSDictionary *params = @{kShelbyAPIParamAuthToken: authToken};
    NSURLRequest *request = [self requestWithMethod:POST
                                            forPath:[NSString stringWithFormat:kShelbyAPIPostFrameWatchedPath, frameID]
                                withQueryParameters:params
                                      shouldAddAuth:NO];
    
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
        DLog(@"Succeeded fetching short link for frame: %@", shortLink);
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
    if (!provider || !accountID || !token) {
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
            ShelbyAlertView *alert = [[ShelbyAlertView alloc] initWithTitle:title
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
