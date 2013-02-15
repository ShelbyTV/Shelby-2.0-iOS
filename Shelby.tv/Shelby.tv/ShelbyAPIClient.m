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

+ (void)postAuthenticationWithEmail:(NSString *)email andPassword:(NSString *)password withLoginView:(LoginView *)loginView
{
    NSString *requestString = [NSString stringWithFormat:kShelbyAPIPostAuthorizeEmail, email, password];
    [requestString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL *requestURL = [NSURL URLWithString:requestString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestURL];
    [request setHTTPMethod:@"POST"];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {

        if ( response.statusCode == 200 ) {
            
            // Clean Image Cache and Core Data store
            AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            [appDelegate performCleanIfUserDidAuthenticate];
            
            // Store User Data
            CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_StoreUser];
            [dataUtility storeUser:JSON];
            
        }
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        
        [loginView userAuthenticationDidFail];
        
        DLog(@"%@", error);
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Login Error"
                                                            message:@"Please make sure you've entered your login credientials correctly."
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil, nil];
        [alertView show];
        
    }];
    
    [operation start];
}

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
            
            CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_BackgroundUpdate];
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

+ (void)getLikesRoll
{
    
    CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
    User *user = [dataUtility fetchUser];
    
    NSString *authToken = [user token];
    NSString *likesRollID = [user likesRollID];
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:kShelbyAPIGetRollFrames, likesRollID, authToken]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"GET"];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_BackgroundUpdate];
            [dataUtility storeRollFrames:JSON];
            
        });
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        
        DLog(@"Problem fetching Queue Roll");
        
    }];
    
    [operation start];
    
}

+ (void)getMoreFramesInLikes:(NSString *)skipParam
{
    
    CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
    User *user = [dataUtility fetchUser];
    
    NSString *authToken = [user token];
    NSString *likesRollID = [user likesRollID];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:kShelbyAPIGetMoreRollFrames, likesRollID, authToken, skipParam]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"GET"];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_ActionUpdate];
            [dataUtility storeRollFrames:JSON];
            
        });
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        
        DLog(@"Problem fetching Queue Roll");
        
    }];
    
    [operation start];
    
}

+ (void)getPersonalRoll
{

    CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
    User *user = [dataUtility fetchUser];
    
    NSString *authToken = [user token];
    NSString *personalRollID = [user personalRollID];
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:kShelbyAPIGetRollFrames, personalRollID, authToken]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"GET"];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_BackgroundUpdate];
            [dataUtility storeRollFrames:JSON];
            
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
    
    NSString *authToken = [user token];
    NSString *personalRollID = [user personalRollID];
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:kShelbyAPIGetMoreRollFrames, personalRollID, authToken, skipParam]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"GET"];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_ActionUpdate];
            [dataUtility storeRollFrames:JSON];
            
        });
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        
        DLog(@"Problem fetching User Personal Roll");
        
    }];
    
    [operation start];
}

+ (void)getLikesForSync
{
        
    CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
    User *user = [dataUtility fetchUser];
    NSString *authToken = [user token];
    NSString *likesRollID = [user likesRollID];
    NSUInteger frameCount = [dataUtility fetchLikesCount];
    
    if ( frameCount ) {
        
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:kShelbyAPIGetRollFramesForSync, likesRollID, authToken, frameCount]];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        [request setHTTPMethod:@"GET"];
        
        AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                
                CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Sync];
                [dataUtility syncLikes:JSON];
                
            });
            
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
            
            DLog(@"Problem fetching Likes for sync.");
            
        }];
        
        [operation start];
    }
}

+ (void)getPersonalRollForSync
{
    
    CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
    User *user = [dataUtility fetchUser];
    NSString *authToken = [user token];
    NSString *personallRollID = [user personalRollID];
    NSUInteger frameCount = [dataUtility fetchLikesCount];
    
    if ( frameCount ) {
        
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:kShelbyAPIGetRollFramesForSync, personallRollID, authToken, frameCount]];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        [request setHTTPMethod:@"GET"];
        
        AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                
                CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Sync];
                [dataUtility syncPersonalRoll:JSON];
                
            });
            
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
            
            DLog(@"Problem fetching Personal Roll for sync.");
            
        }];
        
        [operation start];
    }
}

+ (void)getAllChannels
{
    
    NSURL *url = [NSURL URLWithString:kShelbyAPIGetAllChannels];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"GET"];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Sync];
            [dataUtility storeChannel:JSON];
            
        });
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        
        DLog(@"Problem fetching Personal Roll for sync.");
        
    }];
    
    [operation start];
    
}

+ (void)getChannel:(NSString *)channelID
{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:kShelbyAPIGetChannelDashbaord, channelID]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"GET"];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Sync];
            [dataUtility storeRollFrames:JSON forChannel:channelID];
            
        });
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        
        DLog(@"Problem fetching Personal Roll for sync.");
        
    }];
    
    [operation start];
}

@end
