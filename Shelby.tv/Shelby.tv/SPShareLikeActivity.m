//
//  SPShareLikeActivity.m
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 2/19/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

#import "SPShareLikeActivity.h"

@implementation SPShareLikeActivity

- (NSString *)activityType
{
    return @"tv.shelby.likes";
}

- (NSString *)activityTitle
{
    return @"Like Video";
}

- (UIImage *)activityImage
{
    return [UIImage imageNamed:@"likeActivityButton"];
}


- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems

{
    return YES;
}

@end
