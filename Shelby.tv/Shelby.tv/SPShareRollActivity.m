//
//  SPShareRollActivity.m
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 2/19/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

#import "SPShareRollActivity.h"

@implementation SPShareRollActivity

- (NSString *)activityType
{
    return @"tv.shelby.roll";
}

- (NSString *)activityTitle
{
    return @"Roll Video";
}

- (UIImage *)activityImage
{
    return [UIImage imageNamed:@"rollActivityButton"];
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems
{
    return YES;
}

@end
