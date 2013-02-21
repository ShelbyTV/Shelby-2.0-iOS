//
//  ShelbyAPIClient.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 12/5/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

@class LoginView;

@interface ShelbyAPIClient : NSObject

/// Authentication
+ (void)postAuthenticationWithEmail:(NSString *)email andPassword:(NSString *)password withLoginView:(LoginView *)loginView;

/// Stream
+ (void)getStream;
+ (void)getMoreFramesInStream:(NSString *)skipParam;

/// Likes
+ (void)getLikes;
+ (void)getMoreFramesInLikes:(NSString *)skipParam;

/// Personal Roll
+ (void)getPersonalRoll;
+ (void)getMoreFramesInPersonalRoll:(NSString *)skipParam;

/// Channels
+ (void)getAllChannels;
+ (void)getChannel:(NSString *)channelID;
+ (void)getMoreFrames:(NSString *)skipParam forChannel:(NSString *)channelID;

/// Syncing
+ (void)getLikesForSync;
+ (void)getPersonalRollForSync;

/// Liking
+ (void)postFrameToLikes:(NSString *)frameID;

/// Rolling
+ (void)postFrameToRoll:(NSString*)requestString;

/// Sharing
+ (void)postShareFrameToSocialNetworks:(NSString*)requestString;

@end
