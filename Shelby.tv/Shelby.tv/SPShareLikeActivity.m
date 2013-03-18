//
//  SPShareLikeActivity.m
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 2/19/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

#import "SPShareLikeActivity.h"
#import "SPModel.h"
#import "SPConstants.h"

@implementation SPShareLikeActivity

- (NSString *)activityType
{
    return kShelbySPActivityTypeLike;
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
    
    if ( [[NSUserDefaults standardUserDefaults] boolForKey:kShelbyDefaultUserAuthorized] ) { // Logged In
        
        [ShelbyAPIClient postFrameToLikes:_videoFrame.frameID];
        
    } else { // Logged Out
        
        CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_StoreLoggedOutLike];
        [dataUtility storeFrameInLoggedOutLikes:_videoFrame];
        
    }
    
    SPModel *model = (SPModel *)[SPModel sharedInstance];
    
    [model.overlayView showOverlayView];
    
    [model.overlayView showLikeNotificationView];
    
    [NSTimer scheduledTimerWithTimeInterval:5.0f
                                     target:model.overlayView
                                   selector:@selector(hideLikeNotificationView)
                                   userInfo:nil
                                    repeats:NO];
    
    [model rescheduleOverlayTimer];
    
    [self activityDidFinish:YES];
    
}

@end
