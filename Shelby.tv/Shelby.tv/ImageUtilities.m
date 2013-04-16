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

+ (UIImage *)crop:(UIImage *)image inRect:(CGRect)frame
{
    NSInteger y = frame.origin.y == 0 ? 0 : -frame.origin.y;
    
    UIGraphicsBeginImageContextWithOptions(frame.size, NO, [UIScreen mainScreen].scale);
    [image drawAtPoint:CGPointMake(0, y)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}


+ (UIImage *)captureVideo:(AVPlayer *)player
{
    AVAssetImageGenerator *imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:[player.currentItem asset]];
    [imageGenerator setRequestedTimeToleranceAfter:kCMTimeZero];
    [imageGenerator setRequestedTimeToleranceBefore:kCMTimeZero];
    
    CGImageRef ref = [imageGenerator copyCGImageAtTime:player.currentItem.currentTime actualTime:nil error:nil];
    UIImage *image = [UIImage imageWithCGImage:ref];
    CGImageRelease(ref);

    return image;
}


+ (UIImage *)captureVideo:(AVPlayer *)player toSize:(CGSize)size
{
    CGSize videoSize = size;
    
    NSArray *tracks = [player.currentItem.asset tracksWithMediaType:AVMediaTypeVideo];
    for (AVAssetTrack *assetTrack in tracks) {
        CGSize size = [assetTrack naturalSize];
        CGAffineTransform transform = player.currentItem.asset.preferredTransform;
        double xScale = sqrt(transform.a * transform.a + transform.c * transform.c);
        double yScale = sqrt(transform.b * transform.b + transform.d * transform.d);
        
        videoSize = CGSizeMake(size.width * xScale, size.height * yScale);
        double ratio = 1;
        if (videoSize.width > size.width) {
            ratio = size.width / videoSize.width;
            videoSize.height *= ratio;
            videoSize.width = size.width;
        }
        if (videoSize.height > size.height) {
            ratio = size.height / videoSize.height;
            videoSize.width *= ratio;
            videoSize.height = size.height;
        }
    }
    
    UIImage *image = [ImageUtilities captureVideo:player];
    
    return [image scaleToSize:videoSize];
}
@end
