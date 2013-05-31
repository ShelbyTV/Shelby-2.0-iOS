//
//  FacebookHandler.h
//  Shelby.tv
//
//  Created by Keren on 4/9/13.
//  Copyright (c) 2013 Shelby TV. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^shelby_facebook_request_complete_block_t)(NSDictionary *facebookUser, NSString *facebookToken, NSString *errorMessage);

extern NSString * const kShelbyNotificationFacebookAuthorizationCompleted;


@interface FacebookHandler : NSObject

+ (FacebookHandler *)sharedInstance;

// Facebook state
- (NSString *)facebookToken;
- (NSString *)facebookAppID;

// Read/Write Permissions
- (void)openSessionWithAllowLoginUI:(BOOL)allowLoginUI
            andAskPublishPermission:(BOOL)askForPublishPermission
                          withBlock:(shelby_facebook_request_complete_block_t)completionBlock;
- (void)askForPublishPermissions;
- (BOOL)allowPublishActions;

// Methods to support App Delegate
- (BOOL)handleOpenURL:(NSURL *)url;
- (void)handleDidBecomeActive;

/// Cleanup
- (void)facebookCleanup;
@end
