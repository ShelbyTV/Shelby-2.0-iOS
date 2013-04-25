//
//  FacebookHandler.h
//  Shelby.tv
//
//  Created by Keren on 4/9/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const kShelbyNotificationFacebookAuthorizationCompleted;


@interface FacebookHandler : NSObject

+ (FacebookHandler *)sharedInstance;

// Facebook state
- (NSString *)facebookToken;
- (NSString *)facebookAppID;

// Read/Write Permissions
- (void)openSession:(BOOL)allowLoginUI;
- (void)askForPublishPermissions;
- (BOOL)allowPublishActions;

// Methods to support App Delegate
- (BOOL)handleOpenURL:(NSURL *)url;
- (void)handleDidBecomeActive;

/// Cleanup
- (void)facebookCleanup;
@end
