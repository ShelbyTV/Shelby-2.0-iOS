//
//  ShelbyNotificationManager.m
//  Shelby.tv
//
//  Created by Keren on 9/26/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyNotificationManager.h"

@interface ShelbyNotificationManager()
@end

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


- (NSDate *)notificationDateWithDay:(NSInteger)day andTime:(NSInteger)time
{
    NSDate *today = [NSDate date];
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    [gregorian setTimeZone:[NSTimeZone systemTimeZone]];
    [gregorian setLocale:[NSLocale currentLocale]];
    
    NSDateComponents *todayComp = [gregorian components:NSCalendarUnitYear | NSCalendarUnitWeekday | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond fromDate:today];

    NSInteger hour = time / 100;
    NSInteger minute = time % 100;
    
    // Using the deltaDayComponent figure out how many days ahead the next notification should be
    NSDateComponents *deltaDayComponent = [[NSDateComponents alloc] init];
    NSInteger numberOfDays = day - todayComp.weekday;
    if (numberOfDays < 0) {
        numberOfDays = 7 + numberOfDays;
    } else if (numberOfDays == 0) {
        // If today is the same day we want the notification, check if hour has passed. And if it has, schedule for today next week.
        if (hour < todayComp.hour) {
            numberOfDays += 7;
        }
    }
    
    deltaDayComponent.day = numberOfDays;
    
    // notificationDate is the day we should notifiy the user, now set the correct hour and minute
    NSDate *notificationDate = [[NSCalendar currentCalendar] dateByAddingComponents:deltaDayComponent toDate:today options:0];

    NSDateComponents *notificationDateComponent = [[NSCalendar currentCalendar] components:NSCalendarUnitYear |NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute fromDate:notificationDate];
    notificationDateComponent.hour = hour;
    notificationDateComponent.minute = minute;
    
    // Send the new date - after setting the correct hour, minute in the notificationDate
    return [[NSCalendar currentCalendar] dateFromComponents:notificationDateComponent];

}

- (void)scheduleNotificationWithDay:(NSInteger)day time:(NSInteger)time andMessage:(NSString *)message
{
    [self cancelAllNotifications];
    
    // Now schedule new notification

    NSDate *date = [self notificationDateWithDay:day andTime:time];
    
    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
    localNotification.fireDate = date;
    localNotification.timeZone = [NSTimeZone defaultTimeZone];
    
    localNotification.alertBody = message;
    localNotification.alertAction = NSLocalizedString(@"Watch Videos", nil);
    
    localNotification.soundName = UILocalNotificationDefaultSoundName;
    localNotification.applicationIconBadgeNumber = 0;
    
    // Figure out what the dict should be.
//    NSDictionary *infoDictionary = @{@"local_notification_key": @"local_notification"};
//    localNotification.userInfo = infoDictionary;
    
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
}

- (void)localNotificationFired:(UILocalNotification *)localNotification
{
    // Get data from local notification
    // Save
}


@end
