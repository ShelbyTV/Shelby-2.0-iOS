//
//  ShelbyNotificationManager.m
//  Shelby.tv
//
//  Created by Keren on 9/26/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyNotificationManager.h"
#import "ShelbyABTestManager.h"

@interface ShelbyNotificationManager()
@property (nonatomic, strong) NSDictionary *defaultsDictionary;
@end

@implementation ShelbyNotificationManager

+ (ShelbyNotificationManager *)sharedInstance
{
    static ShelbyNotificationManager *sharedInstance = nil;
    static dispatch_once_t modelToken = 0;
    dispatch_once(&modelToken, ^{
        sharedInstance = [[super allocWithZone:NULL] init];
        sharedInstance.defaultsDictionary = [[ShelbyABTestManager sharedInstance] dictionaryForTest:kShelbyABTestNotification];
    });
    
    return sharedInstance;
}

- (void)cancelAllNotifications
{
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
}


- (NSDate *)notificateionDateWithDay:(NSInteger)day andTime:(NSInteger)time
{
    NSDate *today = [NSDate date];
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    [gregorian setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
    [gregorian setLocale:[NSLocale currentLocale]];
    
    NSDateComponents *nowComponents = [gregorian components:NSCalendarUnitYear | kCFCalendarUnitWeekOfYear | NSCalendarUnitWeekday | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond fromDate:today];
    
    NSInteger hour = time / 100;
    NSInteger minute = time % 100;
    NSInteger addWeek = 0;

    if (nowComponents.weekday > day) {
        addWeek = 1;
    } else if (nowComponents.weekday == day && nowComponents.hour >= hour) {
        addWeek = 1;
    }
    nowComponents.weekday = day;
    
    nowComponents.weekOfYear = (([nowComponents weekOfYear] + addWeek) % 52); //Next week if needed
    if (nowComponents.weekOfYear == 1) {
        nowComponents.year = nowComponents.year + 1;
    }
    nowComponents.hour = hour;
    nowComponents.minute = minute;
    nowComponents.second =  0;
    
    return [gregorian dateFromComponents:nowComponents];

}

- (void)scheduleNotificationForVideos:(NSArray *)videos
{
    [self cancelAllNotifications];
    
    // Now schedule new notification

    NSDictionary *testDictionary = [[ShelbyABTestManager sharedInstance] dictionaryForTest:kShelbyABTestNotification];
    
    // Figure out date - obviously not the line below. But a specific date & time
    NSDate *date = [self notificateionDateWithDay:[testDictionary[kShelbyABTestNotificationDay] integerValue] andTime:[testDictionary[kShelbyABTestNotificationTime] integerValue]];
    
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
