//
//  NSDate+Extension.m
//  Shelby.tv
//
//  Created by Daniel Spinosa on 9/12/13.
//  Copyright (c) 2013 Shelby.tv. All rights reserved.
//

#import "NSDate+Extension.h"

@implementation NSDate (Extension)

+ (NSDate *)dateFromBSONObjectID:(NSString *)identifier
{
    NSUInteger result;
    [[NSScanner scannerWithString:[identifier substringToIndex:8]] scanHexInt:&result];
    return [NSDate dateWithTimeIntervalSince1970:result];
}

- (NSString *)prettyRelativeTime
{
    NSTimeInterval minSinceNow = MAX(0, -[self timeIntervalSinceNow]) / 60;

    if (minSinceNow <= 1) {
        return @"just now";
    } else if (minSinceNow < 60) {
        return [NSString stringWithFormat:@"%.0fm ago", minSinceNow];
    } else if (minSinceNow < 720) {
        return [NSString stringWithFormat:@"%.0fh ago", minSinceNow/60];
    } else {
        return [NSDate monthAndDayStringFor:self];
    }
}

+ (NSString *)monthAndDayStringFor:(NSDate *)d
{
    static NSDateFormatter *formatter;
    if (!formatter) {
        formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = [NSDateFormatter dateFormatFromTemplate:@"MMM d" options:0 locale:[NSLocale currentLocale]];
    }
    return [formatter stringFromDate:d];
}

@end
