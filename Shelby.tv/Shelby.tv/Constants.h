//
//  Constants.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 10/17/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

#import "APIConstants.h"
#import "CoreDataConstants.h"
#import "Structures.h"
#import "SPConstants.h"

// Misc.
#define kShelbyCurrentVersion                               [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]

// NSUserDefault Constants
#define kShelbyDefaultUserAuthorized                        @"Shelby User Authorization Stored in NSUserDefaults"
#define kShelbyDefaultUserIsAdmin                           @"Shelby User Is Administrator"
#define kShelbyDefaultOfflineModeEnabled                    @"Shelby Offline Mode Enabled"

// Notifications
#define kShelbyNotificationUserAuthenticationDidSucceed     @"User Did Successfully Authenticate with Shelby Notification"
#define kShelbyNotificationNoConnectivity                   @"No Connectivity"

// Colors
#define kShelbyColorBlack                                   [UIColor colorWithHex:@"333" andAlpha:1.0f]
#define kShelbyColorGray                                    [UIColor colorWithHex:@"adadad" andAlpha:1.0f]
#define kShelbyColorGreen                                   [UIColor colorWithHex:@"6fbe47" andAlpha:1.0f]
#define kShelbyColorWhite                                   [UIColor colorWithHex:@"eee" andAlpha:1.0f]
