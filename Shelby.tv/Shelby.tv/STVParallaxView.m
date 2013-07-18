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
@property (nonatomic, assign) NSUInteger currentPage;
@end

@implementation STVParallaxView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _currentPage = 0;
        
        CGRect contentFrame = CGRectMake(0, 0, frame.size.width, kShelbyFullscreenHeight);

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

- (void)layoutSubviews
{
    //NB: -layoutSubviews is called after rotation of device and after resizing of views' frame
    [super layoutSubviews];

    //Fix content offset
    [self scrollToCurrentPageBoundary];
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
    if (parallaxView && !CGPointEqualToPoint(self.foregroundScroller.contentOffset, parallaxView.foregroundScroller.contentOffset)) {
        self.foregroundScroller.contentOffset = parallaxView.foregroundScroller.contentOffset;
        self.currentPage = parallaxView.currentPage;
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
}

- (void)scrollToPage:(NSInteger)page
{
    [self.foregroundScroller setContentOffset:CGPointMake(page*self.foregroundScroller.frame.size.width, 0) animated:YES];
    self.currentPage = page;
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
    self.currentPage = (scrollView.contentOffset.x / scrollView.frame.size.width);
    [self.delegate didScrollToPage:self.currentPage];
}

#pragma mark - View/Layout Helpers

- (void)scrollToCurrentPageBoundary
{
    // if foreground's contentOffset if it isn't on a page boundary
    // adjust it to the correct content offset
    CGFloat remainder = remainderf(self.foregroundScroller.contentOffset.x, self.foregroundScroller.frame.size.width);
    if (remainder != 0.0) {
        self.foregroundScroller.contentOffset = CGPointMake(self.currentPage * self.foregroundScroller.frame.size.width, 0);
    }
}

@end
