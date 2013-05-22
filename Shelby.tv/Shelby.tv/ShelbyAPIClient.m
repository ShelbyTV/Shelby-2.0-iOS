//
//  ShelbyAPIClient.m
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 12/5/12.
//  Copyright (c) 2012 Shelby TV. All rights reserved.
//

#import "AFNetworking.h"
#import "LoginView.h"
#import "ShelbyAPIClient.h"
#import "User+Helper.h"

@implementation ShelbyAPIClient

#pragma mark - Authentication (POST)
+ (void)postAuthenticationWithEmail:(NSString *)email andPassword:(NSString *)password
{
    NSString *requestString = [NSString stringWithFormat:kShelbyAPIPostLogin, email, password];
    [requestString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL *requestURL = [NSURL URLWithString:requestString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestURL];
    [request setTimeoutInterval:30.0];
    [request setHTTPMethod:@"POST"];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
            
        // Store User Data
        //djs XXX old stuff
//        CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_StoreUserForLogin];
//        [dataUtility storeUser:JSON];
    
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        DLog(@"%@", error);
        
        NSString *errorMessage = nil;
        // Error code -1009 - no connection
        // Error code -1001 - timeout
        if ([error code] == -1009 || [error code] == -1001) {
            errorMessage = @"Please make sure you are connected to the Internet";
        } else {
            errorMessage = @"Please make sure you've entered your login credientials correctly.";
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:kShelbyNotificationUserAuthenticationDidFail object:errorMessage];
    }];
    
    [operation start];
}

+ (void)postSignupWithName:(NSString *)name nickname:(NSString *)nickname password:(NSString *)password andEmail:(NSString *)email
{

    // Params
    NSDictionary *userDictionary = @{@"name":name,@"nickname":nickname,@"password":password,@"primary_email":email};
    NSDictionary *params = [NSDictionary dictionaryWithObject:userDictionary forKey:@"user"];
    
    NSURL *basURL = [NSURL URLWithString:kShelbyAPIBaseURL];
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:basURL];
    NSURLRequest *request = [httpClient requestWithMethod:@"POST" path:@"/v1/user" parameters:params];

    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        // Store User Data
        //djs XXX old stuff
//        CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_StoreUserForSignUp];
//        [dataUtility storeUser:JSON];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kShelbyNotificationUserSignupDidSucceed object:nil];
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        DLog(@"%@", error);
        [[NSNotificationCenter defaultCenter] postNotificationName:kShelbyNotificationUserSignupDidFail object:JSON];
    }];

    [operation start];
}


#pragma mark - Google Analytics (PUT)
+ (void)putGoogleAnalyticsClientID:(NSString *)clientID
{
    if (!clientID || [clientID isEqualToString:@""]) {
        return;
    }

    NSDictionary *params = @{@"google_analytics_client_id" : clientID};
    
    NSURL *basURL = [NSURL URLWithString:kShelbyAPIBaseURL];

    //djs XXX old stuff
//    CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
    User *user;// = [dataUtility fetchUser];
    NSString *userID = [user userID];
    NSString *authToken = [user token];
    
    NSString *pathURL =[NSString stringWithFormat:kShelbyAPIPutGAClientId, userID, authToken];
    
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:basURL];
    NSURLRequest *request = [httpClient requestWithMethod:@"PUT" path:pathURL parameters:params];
 
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        // Do nothing
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        DLog(@"%@", error);
    }];
    
    [operation start];
}

#pragma mark - Stream (GET)
+ (void)getStream
{

    //djs XXX old stuff
//    CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
//    User *user = [dataUtility fetchUser];
//    
//    NSString *authToken = [user token];
//    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:kShelbyAPIGetStream, authToken]];
//    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
//    [request setHTTPMethod:@"GET"];
//    
//    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
//        
//        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//            
//            CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Sync];
//            [dataUtility storeStream:JSON];
//            
//        });
//        
//    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
//        
//        DLog(@"Problem fetching Stream");
//        
//    }];
//    
//    [operation start];
}

+ (void)getMoreFramesInStream:(NSString *)skipParam
{

    //djs XXX old stuff
//    CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
//    User *user = [dataUtility fetchUser];
//    
//    NSString *authToken = [user token];
//    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:kShelbyAPIGetMoreStream, authToken, skipParam]];
//    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
//    [request setHTTPMethod:@"GET"];
//    
//    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
//        
//        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//            
//            CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_SwipeUpdate];
//            [dataUtility storeStream:JSON];
//            
//        });
//        
//    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
//        
//        DLog(@"Problem fetching Stream");
//        [[NSNotificationCenter defaultCenter] postNotificationName:kShelbyNotificationFetchingOlderVideosFailed object:user.userID];
//        
//    }];
//    
//    [operation start];
}

#pragma mark - Video (PUT)
+ (void)markUnplayableVideo:(NSString *)videoID
{
    //djs XXX old stuff
//    if (!videoID || [videoID isEqualToString:@""]) {
//        return;
//    }
//    
//    CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
//    User *user = [dataUtility fetchUser];
//    
//    NSString *authToken = [user token];
//
//    NSString *requestString = [NSString stringWithFormat:kShelbyAPIPutUnplayableVideo, videoID, authToken];
//    NSURL *requestURL = [NSURL URLWithString:requestString];
//    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestURL];
//    [request setHTTPMethod:@"PUT"];
//    
//    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
//
//        // Do nothing?
//    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
//        DLog(@"Problem marking video unplayable");
//    }];
//    
//    [operation start];
}

#pragma mark - Likes (GET)
+ (void)getLikes
{

    //djs XXX old stuff
//    CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
//    User *user = [dataUtility fetchUser];
//    NSString *likesRollID = [user likesRollID];
//    
//    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:kShelbyAPIGetRollFrames, likesRollID]];
//    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
//    [request setHTTPMethod:@"GET"];
//    
//    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
//        
//        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//            
//            CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Sync];
//            [dataUtility storeRollFrames:JSON forGroupType:GroupType_Likes];
//            
//        });
//        
//    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
//        
//        DLog(@"Problem fetching Likes Roll");
//        
//    }];
//    
//    [operation start];
}

+ (void)getMoreFramesInLikes:(NSString *)skipParam
{
    //djs XXX old stuff
//    CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
//    User *user = [dataUtility fetchUser];
//    NSString *likesRollID = [user likesRollID];
//    
//    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:kShelbyAPIGetMoreRollFrames, likesRollID, skipParam]];
//    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
//    [request setHTTPMethod:@"GET"];
//    
//    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
//        
//        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//            
//            CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_SwipeUpdate];
//            [dataUtility storeRollFrames:JSON forGroupType:GroupType_Likes];
//            
//        });
//        
//    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
//        
//        DLog(@"Problem fetching Likes Roll");
//        [[NSNotificationCenter defaultCenter] postNotificationName:kShelbyNotificationFetchingOlderVideosFailed object:user.likesRollID];
//        
//    }];
//    
//    [operation start];
}

#pragma mark - Personal Roll (GET)
+ (void)getPersonalRoll
{
    //djs XXX old stuff
//    CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
//    User *user = [dataUtility fetchUser];
//    NSString *personalRollID = [user publicRollID];
//
//    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:kShelbyAPIGetRollFrames, personalRollID]];
//    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
//    [request setHTTPMethod:@"GET"];
//    
//    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
//        
//        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//            
//            CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Sync];
//            [dataUtility storeRollFrames:JSON forGroupType:GroupType_PersonalRoll];
//            
//        });
//        
//    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
//        
//        DLog(@"Problem fetching User Personal Roll");
//        
//    }];
//    
//    [operation start];
}

+ (void)getMoreFramesInPersonalRoll:(NSString *)skipParam
{
    //djs XXX old stuff
//    CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
//    User *user = [dataUtility fetchUser];
//    NSString *personalRollID = [user publicRollID];
//    
//    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:kShelbyAPIGetMoreRollFrames, personalRollID, skipParam]];
//    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
//    [request setHTTPMethod:@"GET"];
//    
//    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
//        
//        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//            
//            CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_SwipeUpdate];
//            [dataUtility storeRollFrames:JSON forGroupType:GroupType_PersonalRoll];
//            
//        });
//        
//    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
//        
//        DLog(@"Problem fetching User Personal Roll");
//        [[NSNotificationCenter defaultCenter] postNotificationName:kShelbyNotificationFetchingOlderVideosFailed object:user.publicRollID];
//        
//    }];
//    
//    [operation start];
}

#pragma mark - Authentication (POST)
+ (void)loginUserWithEmail:(NSString *)email
                  password:(NSString *)password
                  andBlock:(shelby_api_request_complete_block_t)completionBlock
{
    NSString *requestString = [NSString stringWithFormat:kShelbyAPIPostLogin, email, password];
    [requestString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL *requestURL = [NSURL URLWithString:requestString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestURL];
    [request setTimeoutInterval:30.0];
    [request setHTTPMethod:@"POST"];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
       completionBlock(JSON, nil);
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        completionBlock(nil, error);
    }];
    
    [operation start];
}


#pragma mark - Channels (GET)
//djs update done!
+ (void)fetchChannelsWithBlock:(shelby_api_request_complete_block_t)completionBlock
{
    NSURL *url = [NSURL URLWithString:kShelbyAPIGetAllChannels];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"GET"];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        completionBlock(JSON, nil);
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        completionBlock(nil, error);
    }];
    [operation start];
}

//djs update done!
+ (void)fetchDashboardEntriesForDashboardID:(NSString *)dashboardID
                                 sinceEntry:(DashboardEntry *)sinceEntry
                                  withBlock:(shelby_api_request_complete_block_t)completionBlock
{
    NSString *requestString;
    if(sinceEntry){
        requestString = [NSString stringWithFormat:kShelbyAPIGetChannelDashboardEntriesSince, dashboardID, sinceEntry.dashboardEntryID];
    } else {
        requestString = [NSString stringWithFormat:kShelbyAPIGetChannelDashboardEntries, dashboardID];
    }
    NSURL *requestURL = [NSURL URLWithString:requestString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestURL];
    [request setHTTPMethod:@"GET"];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        completionBlock(JSON, nil);
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        completionBlock(nil, error);
    }];
    
    [operation start];
}

// TODO: deal with unlike, sync likes after user logs in.
+ (void)postUserLikedFrame:(NSString *)frameID userToken:(NSString *)authToken withBlock:(shelby_api_request_complete_block_t)completionBlock
{
    NSString *requestString = [NSString stringWithFormat:kShelbyAPIPostFrameToLikesWithAuthentication, frameID, authToken];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:requestString]];
    [request setHTTPMethod:@"PUT"];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        completionBlock(JSON, nil);
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        completionBlock(nil, error);
    }];
    
    [operation start];
}

#pragma mark - Rolling (POST)
+ (void)postFrameToPersonalRoll:(NSString *)requestString
{
    
    NSURL *url = [NSURL URLWithString:requestString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
        // Post to Roll and Social Networks
        DLog(@"Successfully posted frame to roll and networks");
        
        [ShelbyAPIClient getPersonalRoll];
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        
        DLog(@"Problem rolling frame to roll and networks: %@", requestString);
        
    }];
    
    [operation start];
}

#pragma mark - Sharing (POST)
+ (void)postShareFrameToSocialNetworks:(NSString *)requestString
{
    
    NSURL *url = [NSURL URLWithString:requestString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
        // Post to Roll and Social Networks
        DLog(@"Successfully shared frame to social networks");
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        
        DLog(@"Problem sharing frame to social networks: %@", requestString);
        
    }];
    
    [operation start];
}

#pragma mark - Third Party Token (POST)
// KP KP: TODO: might want to add more checks: If twitter and there is no secret - error.
+ (void)postThirdPartyToken:(NSString *)provider accountID:(NSString *)accountID token:(NSString *)token andSecret:(NSString *)secret
{
    if (!provider || !accountID || !token) {
        return;
    }
    
    NSString *requestString = nil;
    if (secret) {
        requestString = [NSString stringWithFormat:kShelbyAPIPostThirdPartyToken, provider, accountID, token, secret];
    } else {
        requestString = [NSString stringWithFormat:kShelbyAPIPostThirdPartyTokenNoSecret, provider, accountID, token];
    }
    NSURL *requestURL = [NSURL URLWithString:requestString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestURL];
    [request setHTTPMethod:@"POST"];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        DLog(@"%@ - Shelby Token Swap Succeeded", provider);
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        DLog(@"%@ - Shelby Token Swap Failed", provider);
    }];
    
    [operation start];
}


@end
