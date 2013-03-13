//
//  ShelbyAPIClient.m
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 12/5/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

#import "ShelbyAPIClient.h"
#import "LoginView.h"

@implementation ShelbyAPIClient

#pragma mark - Authentication (POST)
+ (void)postAuthenticationWithEmail:(NSString *)email andPassword:(NSString *)password withLoginView:(LoginView *)loginView
{
    NSString *requestString = [NSString stringWithFormat:kShelbyAPIPostAuthorizeEmail, email, password];
    [requestString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL *requestURL = [NSURL URLWithString:requestString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestURL];
    [request setTimeoutInterval:30.0];
    [request setHTTPMethod:@"POST"];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {

        if ( response.statusCode == 200 ) {
            
            // Store User Data
            CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_StoreUser];
            [dataUtility storeUser:JSON];
            
        }
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        
        [loginView userAuthenticationDidFail];
 
        DLog(@"%@", error);
        
        NSString *errorMessage = nil;
        // Error code -1009 - no connection
        // Error code -1001 - timeout
        if ([error code] == -1009 || [error code] == -1001) {
            errorMessage = @"Please make sure you are connected to the Internet";
        } else {
            errorMessage = @"Please make sure you've entered your login credientials correctly.";
        }

        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Login Error"
                                                            message:errorMessage
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil, nil];
        [alertView show];
        
    }];
    
    [operation start];
}

#pragma mark - Stream (GET)
+ (void)getStream
{

    CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
    User *user = [dataUtility fetchUser];
    
    NSString *authToken = [user token];
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:kShelbyAPIGetStream, authToken]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"GET"];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Sync];
            [dataUtility storeStream:JSON];
            
        });
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        
        DLog(@"Problem fetching Stream");
        
    }];
    
    [operation start];
}

+ (void)getMoreFramesInStream:(NSString *)skipParam
{
    
    CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
    User *user = [dataUtility fetchUser];
    
    NSString *authToken = [user token];
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:kShelbyAPIGetMoreStream, authToken, skipParam]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"GET"];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_ActionUpdate];
            [dataUtility storeStream:JSON];
            
        });
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        
        DLog(@"Problem fetching Stream");
        
    }];
    
    [operation start];
}

#pragma mark - Video (PUT)
+ (void)markUnplayableVideo:(NSString *)videoID
{
    if (!videoID || [videoID isEqualToString:@""]) {
        return;
    }
    
    CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
    User *user = [dataUtility fetchUser];
    
    NSString *authToken = [user token];

    NSString *requestString = [NSString stringWithFormat:kShelbyAPIPutUnplayableVideo, videoID, authToken];
    NSURL *requestURL = [NSURL URLWithString:requestString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestURL];
    [request setHTTPMethod:@"PUT"];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {

        // Do nothing?
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        DLog(@"Problem marking video unplayable");
    }];
    
    [operation start];

}

#pragma mark - Likes (GET)
+ (void)getLikes
{
    
    CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
    User *user = [dataUtility fetchUser];
    NSString *likesRollID = [user likesRollID];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:kShelbyAPIGetRollFrames, likesRollID]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"GET"];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Sync];
            [dataUtility storeRollFrames:JSON forGroupType:GroupType_Likes];
            
        });
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        
        DLog(@"Problem fetching Likes Roll");
        
    }];
    
    [operation start];
    
}

+ (void)getMoreFramesInLikes:(NSString *)skipParam
{
    
    CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
    User *user = [dataUtility fetchUser];
    NSString *likesRollID = [user likesRollID];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:kShelbyAPIGetMoreRollFrames, likesRollID, skipParam]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"GET"];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_ActionUpdate];
            [dataUtility storeRollFrames:JSON forGroupType:GroupType_Likes];
            
        });
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        
        DLog(@"Problem fetching Likes Roll");
        
    }];
    
    [operation start];
    
}

#pragma mark - Personal Roll (GET)
+ (void)getPersonalRoll
{

    CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
    User *user = [dataUtility fetchUser];
    NSString *personalRollID = [user personalRollID];

    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:kShelbyAPIGetRollFrames, personalRollID]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"GET"];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Sync];
            [dataUtility storeRollFrames:JSON forGroupType:GroupType_PersonalRoll];
            
        });
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        
        DLog(@"Problem fetching User Personal Roll");
        
    }];
    
    [operation start];
}

+ (void)getMoreFramesInPersonalRoll:(NSString *)skipParam
{
    CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
    User *user = [dataUtility fetchUser];
    NSString *personalRollID = [user personalRollID];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:kShelbyAPIGetMoreRollFrames, personalRollID, skipParam]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"GET"];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_ActionUpdate];
            [dataUtility storeRollFrames:JSON forGroupType:GroupType_PersonalRoll];
            
        });
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        
        DLog(@"Problem fetching User Personal Roll");
        
    }];
    
    [operation start];
}

#pragma mark - Categories (GET)
+ (void)getAllCategories
{
    
    NSURL *url = [NSURL URLWithString:kShelbyAPIGetAllCategories];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"GET"];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_StoreCategories];
            [dataUtility storeCategories:JSON];
            
        });
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        
        // Post notificaiton to dismiss channelLoadingScreen if there's no connectivity
        [[NSNotificationCenter defaultCenter] postNotificationName:kShelbyNotificationNoConnectivity object:nil];

        DLog(@"Problem fetching all Categories");
        
    }];
    
    [operation start];
    
}

+ (void)getCategoryChannel:(NSString *)channelID
{
    NSString *requestString = [NSString stringWithFormat:kShelbyAPIGetCategoryChannel, channelID];
    NSURL *requestURL = [NSURL URLWithString:requestString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestURL];
    [request setHTTPMethod:@"GET"];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
            [dataUtility storeFrames:JSON forCategoryChannel:channelID];
            
        });
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        
        DLog(@"Problem fetching channel: %@", requestString);
        
    }];
    
    [operation start];
}

+ (void)getMoreFrames:(NSString *)skipParam forCategoryChannel:(NSString *)channelID
{
    NSString *requestString = [NSString stringWithFormat:kShelbyAPIGetMoreCategoryChannel, channelID, skipParam];
    NSURL *requestURL = [NSURL URLWithString:requestString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestURL];
    [request setHTTPMethod:@"GET"];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_ActionUpdate];
            [dataUtility storeFrames:JSON forCategoryChannel:channelID];
            
        });
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        
        DLog(@"Problem fetching more frames for channel: %@", requestString);
        
    }];
    
    [operation start];
}

+ (void)getCategoryRoll:(NSString *)rollID
{
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:kShelbyAPIGetRollFrames, rollID]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"GET"];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Sync];
            [dataUtility storeFrames:JSON forCategoryRoll:rollID];
            
        });
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        
        DLog(@"Problem fetching Category Roll");
        
    }];
    
    [operation start];
    
}


+ (void)getMoreFrames:(NSString *)skipParam forCategoryRoll:(NSString *)rollID
{

    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:kShelbyAPIGetMoreRollFrames, rollID, skipParam]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"GET"];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_ActionUpdate];
            [dataUtility storeRollFrames:JSON forGroupType:GroupType_CategoryRoll];
            
        });
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        
        DLog(@"Problem fetching Category Roll");
        
    }];
    
    [operation start];
}

#pragma mark - Syncing (GET)
+ (void)getLikesForSync
{
    
    CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
    User *user = [dataUtility fetchUser];
    NSString *likesRollID = [user likesRollID];
    NSUInteger frameCount = [dataUtility fetchLikesCount];
    
    if ( frameCount ) {
        
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:kShelbyAPIGetRollFramesForSync, likesRollID, frameCount]];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        [request setHTTPMethod:@"GET"];
        
        AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                
                CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Sync];
                [dataUtility syncLikes:JSON];
                
            });
            
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
            
            DLog(@"Problem fetching Likes for sync");
            
        }];
        
        [operation start];
    }
}

+ (void)getPersonalRollForSync
{
    
    CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
    User *user = [dataUtility fetchUser];
    NSString *personallRollID = [user personalRollID];
    NSUInteger frameCount = [dataUtility fetchPersonalRollCount];
    
    if ( frameCount ) {
        
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:kShelbyAPIGetRollFramesForSync, personallRollID, frameCount]];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        [request setHTTPMethod:@"GET"];
        
        AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                
                CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Sync];
                [dataUtility syncPersonalRoll:JSON];
                
            });
            
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
            
            DLog(@"Problem fetching Personal Roll for sync");
            
        }];
        
        [operation start];
    }
}

#pragma mark - Liking (POST)
+ (void)postFrameToWatchedRoll:(NSString *)frameID
{
    CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
    User *user = [dataUtility fetchUser];
    NSString *authToken = [user token];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:kShelbyAPIPostFrameToWatchedRoll, frameID, authToken]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
        DLog(@"Succesfully posted frame to watched roll: %@", frameID);
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        
        DLog(@"Problem posting frame to watched roll: %@", frameID);
        
    }];
    
    [operation start];
}

+ (void)postFrameToLikes:(NSString *)frameID
{
    CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
    User *user = [dataUtility fetchUser];
    NSString *authToken = [user token];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:kShelbyAPIPostFrameToLikes, frameID, authToken]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
        // Fetch likes to update CoreData store
        [self getLikes];
    
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        
        DLog(@"Problem posting frame to likes: %@", frameID);
        
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

@end
