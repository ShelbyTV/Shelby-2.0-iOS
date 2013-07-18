//
//  Constants.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 10/17/12.
//  Copyright (c) 2012 Shelby TV. All rights reserved.
//

#import "GAIConstants.h"
#import "Structures.h"
#import "SPConstants.h"
#import "UIColor+ColorWithHexAndAlpha.h"

/// Misc.
#define kShelbyCurrentVersion                               [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]

/// NSUserDefaults
#define kShelbyDefaultUserAuthorized                        @"Shelby User Authorization Stored in NSUserDefaults"
#define kShelbyDefaultUserIsAdmin                           @"Shelby User Is Administrator"
#define kShelbyDefaultOfflineModeEnabled                    @"Shelby Offline Mode Enabled"
#define kShelbyDefaultOfflineViewModeEnabled                @"Shelby View Mode Enabled"
#define kShelbyDefaultHMACStoredValue                       @"Shelby HMAC Stored Value"

/// Notifications
#define kShelbyNotificationUserAuthenticationDidSucceed     @"User Did Successfully Authenticate with Shelby Notification"
#define kShelbyNotificationUserAuthenticationDidFail        @"User Authentication Failed"
//#define kShelbyNotificationUserSignupDidSucceed             @"User Signup Succeed"
//#define kShelbyNotificationUserSignupDidFail                @"User Signup Failed"
#define kShelbyNotificationFetchingOlderVideosFailed        @"Fetching Older Videos Failed"

/// Colors
#define kShelbyColorBlack                                   [UIColor colorWithHex:@"333" andAlpha:1.0f]
#define kShelbyColorGray                                    [UIColor colorWithHex:@"adadad" andAlpha:1.0f]
#define kShelbyColorGreen                                   [UIColor colorWithHex:@"6ab843" andAlpha:1.0f]
#define kShelbyColorOrange                                  [UIColor colorWithHex:@"F38D00" andAlpha:1.0f]
#define kShelbyColorTutorialGreen                           [UIColor colorWithHex:@"7DC400" andAlpha:1.0f]
#define kShelbyColorLikesRedString                          @"D84955"
#define kShelbyColorLikesRedColor                           [UIColor colorWithHex:@"D84955" andAlpha:1.0f]
#define kShelbyColorMyRollColorString                       @"4B0082"
#define kShelbyColorMyRollColor                             [UIColor colorWithHex:@"4B0082" andAlpha:1.0f]
#define kShelbyColorMyStreamColorString                     @"CC6666"
#define kShelbyColorMyStreamColor                           [UIColor colorWithHex:@"CC6666" andAlpha:1.0f]

#define kShelbyColorLikesRed                                [UIColor colorWithHex:kShelbyColorLikesRedString andAlpha:1.0f]
#define kShelbyColorWhite                                   [UIColor colorWithHex:@"f4f4f4" andAlpha:1.0f]

/// Size
#define  kShelbyFullscreenWidth                             [[UIScreen mainScreen] bounds].size.width
#define  kShelbyFullscreenHeight                            [[UIScreen mainScreen] bounds].size.height

/// Facebook
#define kShelbyFacebookToken                                @"facebookToken"
#define kShelbyFacebookUserID                               @"facebookUserID"
#define kShelbyFacebookUserFullName                         @"facebookUserFullName"

/// Twitter
#define kShelbyTwitterUsername                              @"twitterUsername"
#define kShelbyTwitterConsumerKey                           @"5DNrVZpdIwhQthCJJXCfnQ"
#define kShelbyTwitterConsumerSecret                        @"Tlb35nblFFTZRidpu36Uo3z9mfcvSVv1MuZZ19SHaU"

// Shared BrowseVC & SPVideoReel Prefetching Constant
#define kShelbyPrefetchEntriesWhenNearEnd                   1

// Web URLs (ie. not to be used directly via JSON)
#define kShelbyForgotPasswordURL                            @"http://api.shelby.tv/user/password/new"

#define DEVICE_IPAD                                       (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
