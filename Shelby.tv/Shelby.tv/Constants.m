//
//  SPConstants.m
//  Shelby.tv
//
//  Created by Daniel Spinosa on 1/16/2014.
//  Copyright (c) 2014 Shelby TV. All rights reserved.
//

//TODO: convert all #define strings to const strings

/// NSUserDefaults
NSString * const kShelbyUserEducationDefaultsKeyPrefix = @"userEd-";

/// Notifications
NSString * const kShelbyWillPresentModalViewNotification = @"kShelbyWillPresentModalViewNotification";
NSString * const kShelbyDidDismissModalViewNotification = @"kShelbyDidDismissModalViewNotification";
NSString * const kShelbyStreamConnectFacebookVisibilityChangeNotification = @"kShelbyStreamConnectFacebookVisibilityChangeNotification";
NSString * const kShelbyStreamConnectTwitterVisibilityChangeNotification = @"kShelbyStreamConnectTwitterVisibilityChangeNotification";

NSString * const kShelbyPlaybackEntityDidChangeNotification = @"kShelbyPlaybackEntityDidChangeNotification";
NSString * const kShelbyPlaybackCurrentEntityKey = @"kShelbyPlaybackCurrentEntityKey";
NSString * const kShelbyPlaybackCurrentChannelKey = @"kShelbyPlaybackChannelKey";

NSString * const kShelbyUserReceivedFollowRollEducationBoolKey = @"kShelbyUserReceivedFollowRollEducationBoolKey";
NSString * const kShelbyUserReceivedUnfollowRollEducationBoolKey = @"kShelbyUserReceivedUnfollowRollEducationBoolKey";
NSString * const kShelbyUserReceivedVideoLikingEducationBoolKey = @"kShelbyUserReceivedVideoLikingEducationBoolKey";
