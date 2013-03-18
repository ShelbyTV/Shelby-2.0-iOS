//
//  SPShareRollActivity.m
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 2/19/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

#import "SPShareRollActivity.h"
#import "SPModel.h"
#import "SPShareController.h"


@implementation SPShareRollActivity

- (NSString *)activityType
{
    return kShelbySPActivityTypeRoll;
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

- (void)performActivity
{
    
    SPModel *model = (SPModel *)[SPModel sharedInstance];
    [model.overlayView showOverlayView];
    
    [self.shareController showRollView];
    
    [self activityDidFinish:YES];
}

@end
