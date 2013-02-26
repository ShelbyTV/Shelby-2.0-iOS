//
//  ImageUtilities.h
//  Shelby.tv
//
//  Created by Keren on 2/25/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ImageUtilities : NSObject
+ (UIImage *)screenshot:(UIView *)view;
+ (UIImage *)captureVideo:(AVPlayer *)player toSize:(CGSize)size;
@end
