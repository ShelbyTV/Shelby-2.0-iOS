//
//  FacebookHandler.h
//  Shelby.tv
//
//  Created by Keren on 4/9/13.
//  Copyright (c) 2013 Shelby TV. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^shelby_facebook_request_complete_block_t)(BOOL sessionOpen, NSDictionary *facebookUser, NSString *facebookToken, NSString *errorMessage);

extern NSString * const kShelbyNotificationFacebookAuthorizationCompleted;
extern NSString * const kShelbyNotificationFacebookAuthorizationCompletedWithError;
extern NSString * const kShelbyNotificationFacebookPublishAuthorizationCompleted;

@interface FacebookHandler : NSObject

+ (FacebookHandler *)sharedInstance;

// Facebook state
- (NSString *)facebookToken;
- (NSString *)facebookAppID;
- (BOOL)hasOpenSession;

// Read/Write Permissions
- (void)openSessionWithAllowLoginUI:(BOOL)allowLoginUI
                          withBlock:(shelby_facebook_request_complete_block_t)completionBlock;
- (void)askForPublishPermissions;
- (BOOL)allowPublishActions;

// Methods to support App Delegate
- (BOOL)handleOpenURL:(NSURL *)url;
- (void)handleDidBecomeActive;

// Send requests
- (void)sendAppRequest;

/// Cleanup
- (void)facebookCleanup;
@end
