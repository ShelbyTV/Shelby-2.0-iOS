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

// This method cancels ALL notifications when called
- (void)scheduleNotificationWithDay:(NSInteger)day time:(NSInteger)time andMessage:(NSString *)message;

// This is for future smart-notification analysis 
- (void)localNotificationFired:(UILocalNotification *)localNotification;

- (void)cancelAllNotifications;
@end
