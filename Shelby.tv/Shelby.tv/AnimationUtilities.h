//
//  AnimationUtilities.h
//  Shelby.tv
//
//  Created by Joshua Samberg on 3/21/14.
//  Copyright (c) 2014 Shelby TV, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AnimationUtilities : NSObject
// pause all animations in a layer
+(void)pauseLayer:(CALayer*)layer;
// resume all animations in a layer from the point at which they were paused
+(void)resumeLayer:(CALayer*)layer;
@end
