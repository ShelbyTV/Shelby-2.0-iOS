//
//  STVParallaxView.m
//  Shelby.tv
//
//  Created by Daniel Spinosa on 6/24/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "STVParallaxView.h"

@interface STVParallaxView()
@property (nonatomic, strong) UIScrollView *backgroundScroller;
@property (nonatomic, strong) UIScrollView *foregroundScroller;
@end

@implementation STVParallaxView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        CGRect contentFrame = CGRectMake(0, 0, frame.size.width, frame.size.height);

        _backgroundScroller = [[UIScrollView alloc] initWithFrame:contentFrame];
        _backgroundScroller.scrollEnabled = NO;
        _backgroundScroller.gestureRecognizers = nil;
        _backgroundScroller.showsHorizontalScrollIndicator = NO;
        [self addSubview:_backgroundScroller];

        _foregroundScroller = [[UIScrollView alloc] initWithFrame:contentFrame];
        _foregroundScroller.pagingEnabled = YES;
        _foregroundScroller.delegate = self;
        _foregroundScroller.showsHorizontalScrollIndicator = NO;
        [self addSubview:_foregroundScroller];
    }
    return self;
}

- (void)setBackgroundContent:(UIView *)backgroundContent
{
    [self.backgroundContent removeFromSuperview];
    _backgroundContent = backgroundContent;
    [self.backgroundScroller addSubview:_backgroundContent];
    [self bringSubviewToFront:self.foregroundContent];
    self.backgroundScroller.contentSize = self.backgroundContent.frame.size;
}

- (void)setForegroundContent:(UIView *)foregroundContent
{
    [self.foregroundContent removeFromSuperview];
    _foregroundContent = foregroundContent;
    [self.foregroundScroller addSubview:_foregroundContent];
    [self bringSubviewToFront:self.foregroundContent];
    self.foregroundScroller.contentSize = self.foregroundContent.frame.size;
}

- (void)matchParallaxOf:(STVParallaxView *)parallaxView
{
    if (parallaxView && parallaxView != self) {
        self.foregroundScroller.contentOffset = parallaxView.foregroundScroller.contentOffset;
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat bgX = 0;
    bgX = self.foregroundScroller.contentOffset.x * self.parallaxRatio;
    self.backgroundScroller.contentOffset = CGPointMake(bgX, 0);

    [self.delegate parallaxDidChange:self];
}

@end
