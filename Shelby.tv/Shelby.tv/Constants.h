//
//  Constants.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 10/17/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

#import "APIConstants.h"
#import "CoreDataConstants.h"
#import "GAIConstants.h"
#import "Structures.h"
#import "SPConstants.h"

// Misc.
#define kShelbyCurrentVersion                               [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]

// NSUserDefaults
#define kShelbyDefaultUserAuthorized                        @"Shelby User Authorization Stored in NSUserDefaults"
#define kShelbyDefaultUserIsAdmin                           @"Shelby User Is Administrator"
#define kShelbyDefaultOfflineModeEnabled                    @"Shelby Offline Mode Enabled"
#define kShelbyDefaultOfflineViewModeEnabled                @"Shelby View Mode Enabled"
#define kShelbyDefaultHMACStoredValue                       @"Shelby HMAC Stored Value"

// Notifications
#define kShelbyNotificationUserAuthenticationDidSucceed     @"User Did Successfully Authenticate with Shelby Notification"
#define kShelbyNotificationUserAuthenticationDidFail        @"User Authentication Failed"
#define kShelbyNotificationUserSignupDidSucceed             @"User Signup Succeed"
#define kShelbyNotificationUserSignupDidFail                @"User Signup Failed"
#define kShelbyNotificationNoConnectivity                   @"No Connectivity"

// Colors
#define kShelbyColorBlack                                   [UIColor colorWithHex:@"333" andAlpha:1.0f]
#define kShelbyColorGray                                    [UIColor colorWithHex:@"adadad" andAlpha:1.0f]
#define kShelbyColorGreen                                   [UIColor colorWithHex:@"6ab843" andAlpha:1.0f]
#define kShelbyColorWhite                                   [UIColor colorWithHex:@"f4f4f4" andAlpha:1.0f]

/// Size
#define  kShelbyFullscreenWidth                             [[UIScreen mainScreen] bounds].size.width
#define  kShelbyFullscreenHeight                            [[UIScreen mainScreen] bounds].size.height

/// Facebook
#define kShelbyFacebookToken                                @"facebookToken"
