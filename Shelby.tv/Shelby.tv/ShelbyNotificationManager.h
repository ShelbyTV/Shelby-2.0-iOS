//
//  ShelbyNotificationManager.h
//  Shelby.tv
//
//  Created by Keren on 9/26/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ShelbyNotificationManager : NSObject

+ (ShelbyNotificationManager *)sharedInstance;

- (void)scheduleNotificationForVideos:(NSArray *)videos;
- (void)localNotificationFired:(UILocalNotification *)localNotification;
@end
