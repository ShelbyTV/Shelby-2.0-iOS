//
//  ShelbyAPIClient.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 12/5/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

@interface ShelbyAPIClient : NSObject

+ (void)postAuthenticationWithEmail:(NSString*)email andPassword:(NSString*)password;
+ (void)getStream;
+ (void)getQueueRoll;
+ (void)getMoreFramesInQueueRoll:(NSString*)skipParam;
+ (void)getPersonalRoll;
+ (void)getMoreFramesInPersonalRoll:(NSString*)skipParam;

@end