//
//  SPShareLikeActivity.m
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 2/19/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

#import "SPShareLikeActivity.h"
#import "SPModel.h"

@implementation SPShareLikeActivity

- (NSString *)activityType
{
    return @"tv.Shelby.Shelby-tv.likes";
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

- (void)performActivity
{
    
    [ShelbyAPIClient postFrameToLikes:_frameID];
    
    SPModel *model = (SPModel *)[SPModel sharedInstance];
    
    [model.overlayView showOverlayView];
    
    [model.overlayView showLikeNotificationView];
    
    [NSTimer scheduledTimerWithTimeInterval:2.5f
                                     target:model.overlayView
                                   selector:@selector(hideLikeNotificationView)
                                   userInfo:nil
                                    repeats:NO];
    
    [model rescheduleOverlayTimer];
    
    [self activityDidFinish:YES];
    
}

@end
