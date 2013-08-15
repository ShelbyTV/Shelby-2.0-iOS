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
#import "User.h"

NSString * const kShelbyNotificationFacebookAuthorizationCompleted = @"kShelbyNotificationFacebookAuthorizationCompleted";

@interface FacebookHandler()
@property (nonatomic, assign) BOOL allowPublishActions;

// Helper methods
- (NSArray *)facebookPermissions;
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
- (void)openSessionWithAllowLoginUI:(BOOL)allowLoginUI
            andAskPublishPermission:(BOOL)askForPublishPermission
                          withBlock:(shelby_facebook_request_complete_block_t)completionBlock
{
    if ([[FBSession activeSession] isOpen]) {
        if (askForPublishPermission) {
            [self askForPublishPermissions];
        }
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
                completionBlock(nil, nil, @"Go to Settings -> Privacy -> Facebook and turn Shelby ON");
            }
        } else {
            // If status is OpenTokenExtended - we had a session - no need to change a thing - just call the completion block to let the delegate know facebookSessionDidComplete
            if (status == FBSessionStateOpenTokenExtended) {
                completionBlock(nil, [self facebookToken], nil);
            } else {
                // Get request for user object - send user and token back.
                [[FBRequest requestForMe] startWithCompletionHandler:^(FBRequestConnection *connection, NSDictionary<FBGraphUser> *user, NSError *error) {
                    if (!error && [user isKindOfClass:[NSDictionary class]]) {
                        completionBlock(user, [self facebookToken], nil);
                        
                    } else {
                        // error? could not fetch user.
                    }
                }];
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
    [[FBSession activeSession]
     requestNewPublishPermissions:@[@"publish_stream", @"publish_actions"] defaultAudience:FBSessionDefaultAudienceFriends completionHandler:^(FBSession *session, NSError *error) {
         if (!error) {
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
