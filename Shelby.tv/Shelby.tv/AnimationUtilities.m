//
//  AnimationUtilities.m
//  Shelby.tv
//
//  Created by Joshua Samberg on 3/21/14.
//  Copyright (c) 2014 Shelby TV, Inc. All rights reserved.
//

#import "AnimationUtilities.h"

@implementation AnimationUtilities
+(void)pauseLayer:(CALayer*)layer
{
    CFTimeInterval pausedTime = [layer convertTime:CACurrentMediaTime() fromLayer:nil];
    layer.speed = 0.0;
    layer.timeOffset = pausedTime;
}

+(void)resumeLayer:(CALayer*)layer
{
    CFTimeInterval pausedTime = [layer timeOffset];
    layer.speed = 1.0;
    layer.timeOffset = 0.0;
    layer.beginTime = 0.0;
    CFTimeInterval timeSincePause = [layer convertTime:CACurrentMediaTime() fromLayer:nil] - pausedTime;
    layer.beginTime = timeSincePause;
}
@end
