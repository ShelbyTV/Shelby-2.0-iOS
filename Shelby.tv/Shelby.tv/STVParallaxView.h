//
//  STVParallaxView.h
//  Shelby.tv
//
//  Created by Daniel Spinosa on 6/24/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//
//  Manages two scroll views.  A foreground view the user can directly manipuate,
//  and a background view that is moved relative to the foreground, controlled by
//  the parallaxRatio.
//
//  The actual content must be provided by the user of this class.

#import <UIKit/UIKit.h>

@class STVParallaxView;

@protocol STVParallaxViewDelegate <NSObject>
- (void)parallaxDidChange:(STVParallaxView *)parallaxView;
- (void)didScrollToPage:(NSUInteger)page;
@optional
- (void)parallaxViewWillBeginDragging;
@end

@interface STVParallaxView : UIView <UIScrollViewDelegate>

@property (nonatomic, weak) UIView *backgroundContent;
@property (nonatomic, weak) UIView *foregroundContent;

// Ratio of background to foreground movement from 0.0 - 1.0, inclusive.
//
// Smaller numbers have the effect of increasing the perceived distance
// between foreground and background.  A ratio of 1.0 means for every pixel
// of foreground movement, the background will move 1 pixel.
// A ratio of 0.5 means for every pixel of foreground movement, the
// background will move 1/2 a pixel.  A ratio of 0.0 prevents the background
// from moving.
@property (nonatomic, assign) CGFloat parallaxRatio;

@property (nonatomic, weak) id<STVParallaxViewDelegate>delegate;

- (void)insertViewBelowForeground:(UIView *)view;

// Useful, in conjuntion with the delegate, in keeping parallax synchronized
// between multiple views
- (void)matchParallaxOf:(STVParallaxView *)parallaxView;

- (CGPoint)foregroundContentOffset;

- (UIView *)getBackgroundView;

- (void)updateFrame:(CGRect)frame;

- (void)scrollToPage:(NSInteger)page;

@end
