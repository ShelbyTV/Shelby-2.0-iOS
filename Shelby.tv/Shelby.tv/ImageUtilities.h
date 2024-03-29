//
//  ImageUtilities.h
//  Shelby.tv
//
//  Created by Keren on 2/25/13.
//  Copyright (c) 2013 Shelby TV. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

@interface ImageUtilities : NSObject
+ (UIImage *)screenshot:(UIView *)view;
+ (UIImage *)crop:(UIImage *)image inRect:(CGRect)frame;

+ (UIImage *)captureVideo:(AVPlayer *)player;

/// Capturing a video will take into account the actual size of the video played (i.e. will maintain ratio)
+ (UIImage *)captureVideo:(AVPlayer *)player toSize:(CGSize)size;
@end
