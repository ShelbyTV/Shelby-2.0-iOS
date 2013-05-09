//
//  FacebookHandler.m
//  Shelby.tv
//
//  Created by Keren on 4/9/13.
//  Copyright (c) 2013 Shelby TV. All rights reserved.
//

#import "FacebookHandler.h"
#import <FacebookSDK/FacebookSDK.h>
#import "ShelbyAPIClient.h"
#import "CoreDataUtility.h"
#import "User.h"

NSString * const kShelbyNotificationFacebookAuthorizationCompleted = @"kShelbyNotificationFacebookAuthorizationCompleted";

@interface FacebookHandler()
@property (nonatomic, assign) BOOL allowPublishActions;
@property (nonatomic, strong) NSInvocation *invocationMethod;

// Helper methods
- (NSArray *)facebookPermissions;
- (void)saveFacebookInfo;
- (void)sendToken;
@end


@implementation FacebookHandler

+ (FacebookHandler *)sharedInstance
{
    static FacebookHandler *sharedInstance = nil;
    static dispatch_once_t modelToken = 0;
    dispatch_once(&modelToken, ^{
        sharedInstance = [[super allocWithZone:NULL] init];
    });
    
    return sharedInstance;
}


#pragma mark - Helper methods (Private)
- (NSArray *)facebookPermissions
{
    return [[FBSession activeSession] permissions];
}

- (void)saveFacebookInfo
{
    
    NSString *oldToken = [[NSUserDefaults standardUserDefaults] objectForKey:kShelbyFacebookToken];
    NSString *facebookToken = [self facebookToken];
    [[NSUserDefaults standardUserDefaults] setObject:facebookToken forKey:kShelbyFacebookToken];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    NSString *oldFacebookID = [[NSUserDefaults standardUserDefaults] objectForKey:kShelbyFacebookUserID];
    [[FBRequest requestForMe] startWithCompletionHandler:^(FBRequestConnection *connection, NSDictionary<FBGraphUser> *user, NSError *error) {
        if (!error && [user isKindOfClass:[NSDictionary class]]) {
            NSString *facebookUserID = user[@"id"];
            NSString *facebookUserName = user[@"name"];
            if (facebookUserID && (!oldFacebookID || ![facebookUserID isEqualToString:oldFacebookID])) {
                [[NSUserDefaults standardUserDefaults] setObject:facebookUserID forKey:kShelbyFacebookUserID];
                if (facebookToken && (!oldToken || ![facebookToken isEqualToString:oldToken])) {
                    [self sendToken];
                }
            }
            if (facebookUserName) {
                [[NSUserDefaults standardUserDefaults] setObject:facebookUserName forKey:kShelbyFacebookUserFullName];
            }
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    }];
}

- (void)sendToken
{
    [ShelbyAPIClient postThirdPartyToken:@"facebook" accountID:[self facebookUserID] token:[self facebookToken] andSecret:nil];
}

- (void)facebookCleanup
{
    if ([[FBSession activeSession] isOpen]) {
        [[FBSession activeSession] closeAndClearTokenInformation];
        [FBSession setActiveSession:nil];
    }
}

- (NSString *)facebookUserID
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:kShelbyFacebookUserID];
}

#pragma mark - Facebook state (Public)
- (NSString *)facebookAppID
{
    return [FBSession defaultAppID];
}

- (NSString *)facebookToken
{
    return [[[FBSession activeSession] accessTokenData] accessToken];
}

#pragma mark - Facebook Read/Write Permissions (Public)
- (void)openSessionWithAllowLoginUI:(BOOL)allowLoginUI withBlock:(shelby_facebook_request_complete_block_t)completionBlock
{
    if ([[FBSession activeSession] isOpen]) {
        return;
    }
    
    [FBSession openActiveSessionWithReadPermissions:@[@"email", @"read_stream"]
                                       allowLoginUI:allowLoginUI
                                  completionHandler:^(FBSession *session,
                                                      FBSessionState status,
                                                      NSError *error) {
        if (status == FBSessionStateClosedLoginFailed || status == FBSessionStateCreatedOpening) {
            [self facebookCleanup];
            
            if (status == FBSessionStateClosedLoginFailed) {
                completionBlock(nil, nil, @"Go to Settings -> Facebook and turn Shelby ON");
//                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Go to Settings -> Facebook and turn Shelby ON" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
//                [alertView show];
            }
        } else {
//            [self saveFacebookInfo];
            // KP KP: TODO: dump this, open issue on backend to get user full name
            [[FBRequest requestForMe] startWithCompletionHandler:^(FBRequestConnection *connection, NSDictionary<FBGraphUser> *user, NSError *error) {
                if (!error && [user isKindOfClass:[NSDictionary class]]) {
                    completionBlock(user, [self facebookToken], nil);
                } else {
                    // error? could not fetch user.
                }
            }];
            
            if (self.invocationMethod) {
                [self.invocationMethod invoke];
                [self setInvocationMethod:nil];
            }
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kShelbyNotificationFacebookAuthorizationCompleted object:nil];
     }];
}

- (BOOL)allowPublishActions
{
    NSArray *permissions = [self facebookPermissions];
    for (NSString *permission in permissions) {
        if ([permission isEqualToString:@"publish_stream"]) {
            return YES;
        }
    }

    return NO;
}

- (void)askForPublishPermissions
{
    // KP KP: TODO: deal with invocation
    if (![[FBSession activeSession] isOpen]) {
//        NSMethodSignature *signature = [FacebookHandler instanceMethodSignatureForSelector:@selector(askForPublishPermissions)];
//        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
//        
//        [invocation setTarget:self];
//        [invocation setSelector:@selector(askForPublishPermissions)];
//        
//        [self setInvocationMethod:invocation];
//        
//        [self openSessionWithAllowLoginUI:YES];
        return;
    }
    
    [[FBSession activeSession]
     requestNewPublishPermissions:@[@"publish_stream", @"publish_actions"] defaultAudience:FBSessionDefaultAudienceFriends completionHandler:^(FBSession *session, NSError *error) {
         if (!error) {
             [self saveFacebookInfo];
             // KP KP: TODO: show an alert dialog if there are errors asking user to approver FB?
         }
         
         [[NSNotificationCenter defaultCenter] postNotificationName:kShelbyNotificationFacebookAuthorizationCompleted object:nil];
     }];
}


#pragma mark - Methods to support App Delegate
- (BOOL)handleOpenURL:(NSURL *)url
{
    return [FBSession.activeSession handleOpenURL:url];
}

- (void)handleDidBecomeActive
{
    [[FBSession activeSession] handleDidBecomeActive];
}

@end
