//
//  FacebookHandler.m
//  Shelby.tv
//
//  Created by Keren on 4/9/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
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
            if (facebookUserID && (!oldFacebookID || ![facebookUserID isEqualToString:oldFacebookID])) {
                [[NSUserDefaults standardUserDefaults] setObject:facebookUserID forKey:kShelbyFacebookUserID];
                [[NSUserDefaults standardUserDefaults] synchronize];

                if (facebookToken && (!oldToken || ![facebookToken isEqualToString:oldToken])) {
                    [self sendToken];
                }
            }
        }
    }];
}

- (void)sendToken
{
    [ShelbyAPIClient postThirdPartyToken:@"facebook" accountID:[self facebookUserID] token:[self facebookToken] andSecret:nil];
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
- (void)openSession:(BOOL)allowLoginUI
{
    if ([[FBSession activeSession] isOpen]) {
        return;
    }
    
    [FBSession openActiveSessionWithReadPermissions:@[@"email", @"read_stream"] allowLoginUI:allowLoginUI completionHandler:^(FBSession *session,
                                                                                                                              FBSessionState status,
                                                                                                                              NSError *error) {
        if (status == FBSessionStateClosedLoginFailed || status == FBSessionStateCreatedOpening) {
            [[FBSession activeSession] closeAndClearTokenInformation];
            [FBSession setActiveSession:nil];
            
            if (status == FBSessionStateClosedLoginFailed) {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Go to Settings -> Facebook and turn ON Shelby" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [alertView show];
            }
        } else {
            [self saveFacebookInfo];
            
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
        DLog(@"%@", permissions);
    }

    return NO;
}

- (void)askForPublishPermissions
{
    if (![[FBSession activeSession] isOpen]) {
        NSMethodSignature *signature = [FacebookHandler instanceMethodSignatureForSelector:@selector(askForPublishPermissions)];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
        
        [invocation setTarget:self];
        [invocation setSelector:@selector(askForPublishPermissions)];
        
        [self setInvocationMethod:invocation];
        
        [self openSession:YES];
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
