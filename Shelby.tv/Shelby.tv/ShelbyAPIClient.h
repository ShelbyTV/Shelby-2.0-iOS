//
//  ShelbyAPIClient.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 12/5/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

@class LoginView;

@interface ShelbyAPIClient : NSObject

+ (void)postAuthenticationWithEmail:(NSString *)email andPassword:(NSString *)password withLoginView:(LoginView *)loginView;
+ (void)getStream;
+ (void)getMoreFramesInStream:(NSString *)skipParam;
+ (void)getLikesRoll;
+ (void)getMoreFramesInLikes:(NSString *)skipParam;
+ (void)getPersonalRoll;
+ (void)getMoreFramesInPersonalRoll:(NSString *)skipParam;
+ (void)getLikesForSync;
+ (void)getPersonalRollForSync;
+ (void)getAllChannels;
+ (void)getChannel:(NSString*)channelID;

@end
