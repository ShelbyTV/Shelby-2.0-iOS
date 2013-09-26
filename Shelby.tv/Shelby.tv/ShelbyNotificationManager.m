//
//  ShelbyNotificationManager.m
//  Shelby.tv
//
//  Created by Keren on 9/26/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyNotificationManager.h"

@implementation ShelbyNotificationManager

+ (ShelbyNotificationManager *)sharedInstance
{
    static ShelbyNotificationManager *sharedInstance = nil;
    static dispatch_once_t modelToken = 0;
    dispatch_once(&modelToken, ^{
        sharedInstance = [[super allocWithZone:NULL] init];
    });
    
    return sharedInstance;
}

- (void)cancelAllNotifications
{
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
}


- (void)scheduleNotificationForVideos:(NSArray *)videos
{
    [self cancelAllNotifications];
    
    // Now schedule new notification

    // Figure out date - obviously not the line below. But a specific date & time
    NSDate *date = [NSDate dateWithTimeIntervalSinceNow:600];
    
    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
    localNotification.fireDate = date;
    localNotification.timeZone = [NSTimeZone defaultTimeZone];
    
    localNotification.alertBody = @"notification body";
    localNotification.alertAction = NSLocalizedString(@"Watch Video", nil);
    
    localNotification.soundName = UILocalNotificationDefaultSoundName;
    localNotification.applicationIconBadgeNumber = 1;
    
    // Figure out what the dict should be.
    NSDictionary *infoDictionary = @{@"local_notification_key": @"local_notification"};
    localNotification.userInfo = infoDictionary;
    
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
}

- (void)localNotificationFired:(UILocalNotification *)localNotification
{
    // Get data from local notification
    // Save
}


@end
