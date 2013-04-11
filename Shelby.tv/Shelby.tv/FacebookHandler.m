//
//  FacebookHandler.m
//  Shelby.tv
//
//  Created by Keren on 4/9/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

#import "FacebookHandler.h"
#import <FacebookSDK/FacebookSDK.h>

NSString * const kShelbyNotificationFacebookAuthorizationCompleted = @"kShelbyNotificationFacebookAuthorizationCompleted";

@interface FacebookHandler()
@property (nonatomic, assign) BOOL allowPublishActions;
@property (nonatomic, strong) NSInvocation *invocationMethod;

// Helper methods
- (NSArray *)facebookPermissions;
- (void)saveAccessToken;
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

- (void)saveAccessToken
{
    [[NSUserDefaults standardUserDefaults] setObject:[[[FBSession activeSession] accessTokenData] accessToken] forKey:kShelbyFacebookToken];
    [[NSUserDefaults standardUserDefaults] synchronize];
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
                                                                                                                              NSError *error)
     {
         if (status == FBSessionStateClosedLoginFailed || status == FBSessionStateCreatedOpening) {
             [[FBSession activeSession] closeAndClearTokenInformation];
             [FBSession setActiveSession:nil];
             
             if (status == FBSessionStateClosedLoginFailed) {
                 UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Go to Settings -> Facebook and turn ON Shelby" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                 [alertView show];
             }
         } else {
             [self saveAccessToken];
             
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
         if (error) {
             // KP KP: TODO: show an alert dialog asking user to approver FB?
         }
         
         [[NSNotificationCenter defaultCenter] postNotificationName:kShelbyNotificationFacebookAuthorizationCompleted object:nil];
     }];
}


#pragma mark - Methods to support App Delegate
- (BOOL)handleOpenURL:(NSURL *)url
{
    BOOL returnVal =  [FBSession.activeSession handleOpenURL:url];
    
    [self saveAccessToken];
        
    return returnVal;
}

- (void)handleDidBecomeActive
{
    [[FBSession activeSession] handleDidBecomeActive];
}

@end
