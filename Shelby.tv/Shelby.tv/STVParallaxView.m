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
        CGRect contentFrame = CGRectMake(0, 0, frame.size.width, kShelbyFullscreenHeight - 20);

        self.backgroundColor = [UIColor clearColor];

        _backgroundScroller = [[UIScrollView alloc] initWithFrame:contentFrame];
        _backgroundScroller.scrollEnabled = NO;
        _backgroundScroller.gestureRecognizers = nil;
        _backgroundScroller.showsHorizontalScrollIndicator = NO;
        _backgroundScroller.showsVerticalScrollIndicator = NO;
        [self addSubview:_backgroundScroller];

        _foregroundScroller = [[UIScrollView alloc] initWithFrame:contentFrame];
        _foregroundScroller.pagingEnabled = YES;
        _foregroundScroller.delegate = self;
        _foregroundScroller.showsHorizontalScrollIndicator = NO;
        _backgroundScroller.showsVerticalScrollIndicator = NO;
        [self addSubview:_foregroundScroller];
    }
    return self;
}

- (UIView *)getBackgroundView
{
    return self.backgroundScroller;
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

- (CGPoint)foregroundContentOffset
{
    return self.foregroundScroller.contentOffset;
}


- (void)updateFrame:(CGRect)frame
{
    self.frame = frame;
    self.backgroundScroller.frame =  frame;
    self.foregroundScroller.frame = frame;

    NSInteger width;
    NSInteger height;
    if (frame.size.width > frame.size.height) {
        // landscape
        width = self.backgroundContent.frame.size.height;
        height = self.backgroundContent.frame.size.width;
    } else {
        // Portrait
        width = self.backgroundContent.frame.size.width;
        height = self.backgroundContent.frame.size.height;
    }

    self.backgroundContent.frame = CGRectMake(0, 0, width, height);
    self.foregroundContent.frame = CGRectMake(0, 0, self.frame.size.width * 2, self.frame.size.height);
    
    self.backgroundScroller.contentSize = self.backgroundContent.frame.size;
    self.foregroundScroller.contentSize = self.foregroundContent.frame.size;
    
    // KP KP: TODO: need to also update content offset.
}

#pragma mark - UIScrollViewDelegate (only of _foregroundScroller)

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat bgX = 0;
    bgX = self.foregroundScroller.contentOffset.x * self.parallaxRatio;
    self.backgroundScroller.contentOffset = CGPointMake(bgX, 0);

    [self.delegate parallaxDidChange:self];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    NSUInteger page = (scrollView.contentOffset.x / scrollView.frame.size.width);
    [self.delegate didScrollToPage:page];
}

@end
