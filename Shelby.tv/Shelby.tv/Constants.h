//
//  Constants.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 10/17/12.
//  Copyright (c) 2012 Shelby TV. All rights reserved.
//

#import "GAIConstants.h"
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
extern NSString * const kShelbyWillPresentModalViewNotification;
extern NSString * const kShelbyDidDismissModalViewNotification;

/// Colors - deprecated
#define kShelbyColorGray                                    [UIColor colorWithHex:@"adadad" andAlpha:1.0f]
#define kShelbyColorOrange                                  [UIColor colorWithHex:@"F38D00" andAlpha:1.0f]
#define kShelbyColorTutorialGreen                           [UIColor colorWithHex:@"7DC400" andAlpha:1.0f]
#define kShelbyColorLikesRedString                          @"D84955"
#define kShelbyColorLikesRedColor                           [UIColor colorWithHex:@"D84955" andAlpha:1.0f]
#define kShelbyColorMyRollColorString                       @"4B0082"
#define kShelbyColorMyRollColor                             [UIColor colorWithHex:@"4B0082" andAlpha:1.0f]
#define kShelbyColorMyStreamColorString                     @"CC6666"
#define kShelbyColorMyStreamColor                           [UIColor colorWithHex:@"CC6666" andAlpha:1.0f]

/// Colors
#define kShelbyColorBlack                                   [UIColor colorWithHex:@"000000" andAlpha:1.0f]
#define kShelbyColorWhite                                   [UIColor colorWithHex:@"ffffff" andAlpha:1.0f]
#define kShelbyColorLightGray                               [UIColor colorWithHex:@"aaaaaa" andAlpha:1.0f]
#define kShelbyColorMediumGray                              [UIColor colorWithHex:@"555555" andAlpha:1.0f]
#define kShelbyColorDarkGray                                [UIColor colorWithHex:@"333333" andAlpha:1.0f]
#define kShelbyColorGreen                                   [UIColor colorWithHex:@"6fbe47" andAlpha:1.0f]
#define kShelbyColorTwitterBlue                             [UIColor colorWithHex:@"2ba9e1" andAlpha:1.0f]
#define kShelbyColorFacebookBlue                            [UIColor colorWithHex:@"3b5998" andAlpha:1.0f]
#define kShelbyColorAirPlayBlue                             [UIColor colorWithHex:@"2484E8" andAlpha:1.0f]



#define kShelbyColorLikesRed                                [UIColor colorWithHex:kShelbyColorLikesRedString andAlpha:1.0f]

/// Size
#define  kShelbyFullscreenWidth                             [[UIScreen mainScreen] bounds].size.width
#define  kShelbyFullscreenHeight                            [[UIScreen mainScreen] bounds].size.height

/// Fonts
#define kShelbyFontH1Bold                                   [UIFont fontWithName:@"Ubuntu-Medium" size:32]
#define kShelbyFontH2                                       [UIFont fontWithName:@"Ubuntu" size:24]
#define kShelbyFontH3Bold                                   [UIFont fontWithName:@"Ubuntu-Bold" size:18]
#define kShelbyFontH3Light                                  [UIFont fontWithName:@"Ubuntu-Light" size:18]
#define kShelbyFontH3                                       [UIFont fontWithName:@"Ubuntu" size:18]
#define kShelbyFontH4Bold                                   [UIFont fontWithName:@"Ubuntu-Bold" size:14]
#define kShelbyFontH4Medium                                 [UIFont fontWithName:@"Ubuntu-Medium" size:14]
#define kShelbyFontH4                                       [UIFont fontWithName:@"Ubuntu" size:14]
#define kShelbyFontH4Bold                                   [UIFont fontWithName:@"Ubuntu-Bold" size:14]
#define kShelbyFontH5Bold                                   [UIFont fontWithName:@"Ubuntu-Bold" size:12]
#define kShelbyFontH6Bold                                   [UIFont fontWithName:@"Ubuntu-Bold" size:9]
#define kShelbyBodyFont1                                    [UIFont fontWithName:@"HelveticaNeue" size:17]
#define kShelbyBodyFont1Bold                                [UIFont fontWithName:@"HelveticaNeue-Medium" size:17]
#define kShelbyBodyFont2                                    [UIFont fontWithName:@"HelveticaNeue" size:14]
#define kShelbyBodyFont2Bold                                [UIFont fontWithName:@"HelveticaNeue-Medium" size:14]

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

#define SHELBY_APP_ID                                        @"732244981"

//motion
#define kShelbyMotionForegroundYMin                         @-20.f
#define kShelbyMotionForegroundYMax                         @20.f

//timing
#define kShelbyStreamRefreshForRecommendationsDelay         10.0
