//
//  ShelbyAPIClient.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 12/5/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

@interface ShelbyAPIClient : NSObject

+ (void)postAuthenticationWithEmail:(NSString*)email andPassword:(NSString*)password withIndicator:(UIActivityIndicatorView*)indicator;
+ (void)getStream;
+ (void)getMoreFramesInStream:(NSString*)skipParam;
+ (void)getQueueRoll;
+ (void)getMoreFramesInQueueRoll:(NSString*)skipParam;
+ (void)getPersonalRoll;
+ (void)getMoreFramesInPersonalRoll:(NSString*)skipParam;
+ (void)getQueueForSync;
+ (void)getGroups;

@end
