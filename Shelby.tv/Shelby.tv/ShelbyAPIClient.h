//
//  ShelbyAPIClient.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 12/5/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

@interface ShelbyAPIClient : NSObject

/// Authentication
+ (void)postAuthenticationWithEmail:(NSString *)email andPassword:(NSString *)password;
+ (void)postSignupWithName:(NSString *)name nickname:(NSString *)nickname password:(NSString *)password andEmail:(NSString *)email;

/// Google Analytics
+ (void)putGoogleAnalyticsClientID:(NSString *)clientID;

/// Stream
+ (void)getStream;
+ (void)getMoreFramesInStream:(NSString *)skipParam;

/// Video
+ (void)markUnplayableVideo:(NSString *)videoID;

/// Likes
+ (void)getLikes;
+ (void)getMoreFramesInLikes:(NSString *)skipParam;

/// Personal Roll
+ (void)getPersonalRoll;
+ (void)getMoreFramesInPersonalRoll:(NSString *)skipParam;

/// Categories
+ (void)getAllCategories;
+ (void)getCategoryChannel:(NSString *)channelID;
+ (void)getMoreFrames:(NSString *)skipParam forCategoryChannel:(NSString *)channelID;
+ (void)getCategoryRoll:(NSString *)rollID;
+ (void)getMoreFrames:(NSString *)skipParam forCategoryRoll:(NSString *)rollID;

/// Syncing
+ (void)getLikesForSync;
+ (void)getPersonalRollForSync;

/// Watching
+ (void)postFrameToWatchedRoll:(NSString *)frameID;

/// Liking
+ (void)postFrameToLikes:(NSString *)frameID;

/// Rolling
+ (void)postFrameToPersonalRoll:(NSString*)requestString;

/// Sharing
+ (void)postShareFrameToSocialNetworks:(NSString*)requestString;

@end
