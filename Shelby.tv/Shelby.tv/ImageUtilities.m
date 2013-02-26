//
//  ImageUtilities.m
//  Shelby.tv
//
//  Created by Keren on 2/25/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

#import "ImageUtilities.h"
#import "UIImage+Scale.h"

@implementation ImageUtilities

+ (UIImage *)screenshot:(UIView *)view
{
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, NO, [UIScreen mainScreen].scale);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}


+ (UIImage *)captureVideo:(AVPlayer *)player toSize:(CGSize)size
{
    AVAssetImageGenerator *imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:[player.currentItem asset]];
    [imageGenerator setRequestedTimeToleranceAfter:kCMTimeZero];
    [imageGenerator setRequestedTimeToleranceBefore:kCMTimeZero];
    
    CGImageRef ref = [imageGenerator copyCGImageAtTime:player.currentItem.currentTime actualTime:nil error:nil];
    UIImage *image = [UIImage imageWithCGImage:ref];
    CGImageRelease(ref);
    
    return [image scaleToSize:size];
}
@end
