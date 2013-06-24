//
//  STVParalaxView.h
//  Shelby.tv
//
//  Created by Daniel Spinosa on 6/24/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface STVParallaxView : UIView

@property (nonatomic, weak) UIView *backgroundContent;
@property (nonatomic, weak) UIView *foregroundContent;

// Ratio of background to foreground movement from 0.0 - 1.0, inclusive.
// Smaller numbers have the effect of increasing the perceived distance
// between foreground and background.  A ratio of 1.0 means for every pixel
// of foreground movement, the background will move 1 pixel.
// A ratio of 0.5 means for every pixel of foreground movement, the
// background will move 1/2 a pixel.  A ratio of 0.0 prevents the background
// from moving.
@property (nonatomic, assign) CGFloat paralaxRatio;

@end
