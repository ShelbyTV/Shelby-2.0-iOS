//
//  WelcomeScrollHolderView.m
//  Shelby.tv
//
//  Created by Daniel Spinosa on 8/28/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "WelcomeScrollHolderView.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

@interface WelcomeScrollHolderView()
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *tipLabel;
@property (weak, nonatomic) IBOutlet UIView *phoneView;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@property (strong, nonatomic) IBOutletCollection(UIImageView) NSArray *tipIconsP1;
@property (strong, nonatomic) IBOutletCollection(UIImageView) NSArray *tipIconsP2;
@property (strong, nonatomic) IBOutletCollection(UIImageView) NSArray *tipIconsP3;

@property (weak, nonatomic) IBOutlet UIImageView *scrollUpImage;
@property (weak, nonatomic) IBOutlet UIImageView *swipeLeftImage;
@end

#define PAGES_IN_SCROLL_VIEW 4

@implementation WelcomeScrollHolderView{
    MPMoviePlayerController *_player;
    NSTimer *_scrollUpTimer, *_swipeLeftTimer;
    STVParallaxView *_parallaxView;
    UIView *_parallaxFg, *_parallaxBg;
    NSInteger _curScrollPage, _curParallaxPage;
}

- (void)awakeFromNib
{
    //init tip icons w/o animation
    self.tipLabel.text = nil;
    for (NSArray *tipCollection in @[self.tipIconsP1, self.tipIconsP2, self.tipIconsP3]) {
        for (UIView *view in tipCollection) {
            view.alpha = 0.f;
        }
    }

    self.titleLabel.font = kShelbyFontH2;
    [self initScroller];
    [self showTip:0];
    _curScrollPage = 0;
    _curParallaxPage = 0;
}

- (void)dealloc
{
    [self cancelScrollUpHelper];
    [self cancelSwipeLeftHelper];
}

- (void)initScroller
{
    self.scrollView.delegate = self;

    //page 0 is movie
    [self initPlayerWithMovie:@"hungry" atIndex:0];
    [self.scrollView addSubview:_player.view];
    [_player play];

    //pages 1 and 2 are simple images
    UIView *page1 = [self pageForImageNamed:@"welcome-h-p1" atIndex:1];
    [self.scrollView addSubview:page1];
    UIView *page2 = [self pageForImageNamed:@"welcome-h-p2" atIndex:2];
    [self.scrollView addSubview:page2];

    //page 3 has swipeable summary/detail
    [self initParallaxViewAtIndex:3];
    UIView *page3a = _parallaxView;
    [self.scrollView addSubview:page3a];
    self.scrollView.contentSize = CGSizeMake(self.scrollView.bounds.size.width, self.scrollView.bounds.size.height * PAGES_IN_SCROLL_VIEW);
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if (scrollView.contentOffset.y < (scrollView.contentSize.height-scrollView.bounds.size.height)) {
        [self showTip:999];
    }
    [self.scrollViewDelegate scrollViewWillBeginDragging:scrollView];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView.contentOffset.y < (scrollView.contentSize.height-scrollView.bounds.size.height)) {
        [self showTip:999];
    }
    [self.scrollViewDelegate scrollViewDidScroll:scrollView];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    [self.scrollViewDelegate scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    NSInteger page = scrollView.contentOffset.y / scrollView.bounds.size.height;
    _curScrollPage = page;
    [self showTip:page];
}

#pragma mark - STVParallaxViewDelegate

- (void)parallaxDidChange:(STVParallaxView *)parallaxView
{
    //ignore
}

- (void)didScrollToPage:(NSUInteger)page
{
    _curParallaxPage = page;
    switch (page) {
        case 0:
            [self cancelScrollUpHelper];
            [self resetSwipeLeftHelper:.5];
            break;
        case 1:
            [self cancelSwipeLeftHelper];
            [self resetScrollUpHelper:1.5];
            break;
        default:
            break;
    }
}

#pragma mark - Tip Management

- (void)showTip:(NSUInteger)tipIdx
{
    switch (tipIdx) {
        case 0:
            [self zoomOutOnPhone];
            [self changeTitleText:@"Bringing you 15 minutes of video everyday."
                          tipText:@""];
            for (NSArray *tipCollection in @[self.tipIconsP1, self.tipIconsP2, self.tipIconsP3]) {
                [self setViews:tipCollection alpha:0.f];
            }
            [self resetScrollUpHelper:4.0];
            [self cancelSwipeLeftHelper];
            break;
        case 1:
            [self zoomInOnPhone];
            [self changeTitleText:@"...from your favorite people and places."
                          tipText:@"Shelby users share great new video all day long"];
            for (NSArray *tipCollection in @[self.tipIconsP2, self.tipIconsP3]) {
                [self setViews:tipCollection alpha:0.f];
            }
            [self setViews:self.tipIconsP1 alpha:1.f];
            [self resetScrollUpHelper:4.0];
            [self cancelSwipeLeftHelper];
            break;
        case 2:
            [self zoomInOnPhone];
            [self changeTitleText:@"It's like a TV channel personalized for you."
                          tipText:@"Like and share videos to get better recommendations."];
            for (NSArray *tipCollection in @[self.tipIconsP1, self.tipIconsP3]) {
                [self setViews:tipCollection alpha:0.f];
            }
            [self setViews:self.tipIconsP2 alpha:1.f];
            [self resetScrollUpHelper:5.0];
            [self cancelSwipeLeftHelper];
            break;
        case 3:
            [self zoomInOnPhone];
            [self changeTitleText:@"...a TV channel powered by your friends."
                          tipText:@"Swipe left to see what your friend said."];
            for (NSArray *tipCollection in @[self.tipIconsP1, self.tipIconsP2]) {
                [self setViews:tipCollection alpha:0.f];
            }
            [self setViews:self.tipIconsP3 alpha:1.f];
            [_parallaxView scrollToPage:0];
            [self cancelScrollUpHelper];
            [self resetSwipeLeftHelper:1];
            break;
        default:
            break;
    }
}

- (void)changeTitleText:(NSString *)newTitle tipText:(NSString *)newTip
{
    if ([self.titleLabel.text isEqualToString:newTitle]) {
        return;
    }

    [UIView animateWithDuration:0.2 animations:^{
        self.titleLabel.alpha = 0.f;
        self.tipLabel.alpha = 0.f;
    } completion:^(BOOL finished) {
        self.titleLabel.text = newTitle;
        self.tipLabel.text = newTip;
        [UIView animateWithDuration:0.5 animations:^{
            self.titleLabel.alpha = 1.f;
            self.tipLabel.alpha = 1.f;
        }];
    }];
}

- (void)setViews:(NSArray *)viewsArray alpha:(CGFloat)alpha
{
    [UIView animateWithDuration:0.5 animations:^{
        for (UIView *view in viewsArray) {
            view.alpha = alpha;
        }
    }];
}

#pragma mark - View Creation

- (UIView *)pageForImageNamed:(NSString *)imageName atIndex:(NSUInteger)idx
{
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:[self frameForIndex:idx]];
    imageView.image = [UIImage imageNamed:imageName];
    return imageView;
}

- (void)initPlayerWithMovie:(NSString *)movieName atIndex:(NSUInteger)idx
{
    NSURL *vidURL = [[NSBundle mainBundle] URLForResource:movieName withExtension:@"m4v"];

    _player = [[MPMoviePlayerController alloc] initWithContentURL:vidURL];
    _player.view.frame = [self frameForIndex:idx];
    _player.repeatMode = MPMovieRepeatModeOne;
    _player.controlStyle = MPMovieControlStyleNone;
    [_player play];
}

- (void)initParallaxViewAtIndex:(NSUInteger)idx
{
    _parallaxView = [[STVParallaxView alloc] initWithFrame:[self frameForIndex:idx]];
    _parallaxBg = [self pageForImageNamed:@"welcome-h-p3-bg" atIndex:0];
    _parallaxView.backgroundContent = _parallaxBg;
    _parallaxFg = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.scrollView.bounds.size.width*2, self.scrollView.bounds.size.height)];
    _parallaxView.foregroundContent = _parallaxFg;

    UIImageView *summaryFg = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"welcome-h-p3-summary-overlay"]];
    summaryFg.center = CGPointMake(80, 30);
    [_parallaxFg addSubview:summaryFg];

    UIImageView *detailFg = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"welcome-h-p3-detail-overlay"]];
    detailFg.center = CGPointMake(self.scrollView.bounds.size.width + 148, 80);
    [_parallaxFg addSubview:detailFg];

    _parallaxView.delegate = self;
}

- (CGRect)frameForIndex:(NSUInteger)idx
{
    CGRect scrollPageBounds = self.scrollView.bounds;
    return CGRectMake(scrollPageBounds.origin.x, idx*scrollPageBounds.size.height, scrollPageBounds.size.width, scrollPageBounds.size.height);
}

#pragma mark - View Zooming

- (void)zoomOutOnPhone
{
    CGFloat s = .83;
    CGAffineTransform transform = CGAffineTransformScale(CGAffineTransformIdentity, s, s);
    [UIView animateWithDuration:.5 animations:^{
        self.phoneView.transform = transform;
    } completion:^(BOOL finished) {
        //
    }];
}

- (void)zoomInOnPhone
{
    [UIView animateWithDuration:.5 animations:^{
        self.phoneView.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        //
    }];
}

#pragma mark - Tap Gesture on background

- (IBAction)tapOnBackground:(UITapGestureRecognizer *)sender {
    if (_curScrollPage < 3) {
        [self bounceScrollerUp];
    } else {
        if (_curParallaxPage == 0) {
            [self bounceParallaxLeft];
        } else {
            [self bounceScrollerUp];
        }
    }
}

- (void)bounceScrollerUp
{
    CGFloat startingOffsetY = self.scrollView.contentOffset.y;
    [UIView animateWithDuration:.2 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.scrollView.contentOffset = CGPointMake(0, startingOffsetY + 50);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:.5 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.scrollView.contentOffset = CGPointMake(0, startingOffsetY-10);
        } completion:^(BOOL finished) {
            [self.scrollView setContentOffset:CGPointMake(0, startingOffsetY) animated:YES];
        }];

    }];
}

- (void)bounceParallaxLeft
{
    //ideally we could actually bounce, but STVParllaxView doesn't support arbitrary contentOffset
    //and i'm not trying to make any big changes right now
    [_parallaxView scrollToPage:1];
    [self didScrollToPage:1];
}

#pragma mark - Timers for Scroll Images

#define BREATHE_TIME 1.3

- (void)showScrollUpHelper
{
    _scrollUpTimer = nil;
    self.scrollUpImage.alpha = 0.f;
    self.scrollUpImage.hidden = NO;

    UIViewAnimationOptions options = UIViewAnimationOptionRepeat | UIViewAnimationOptionAutoreverse | UIViewAnimationOptionCurveEaseOut;
    [UIView animateWithDuration:BREATHE_TIME delay:0 options:options animations:^{
        self.scrollUpImage.alpha = 1.f;
    } completion:nil];
}

- (void)cancelScrollUpHelper
{
    [_scrollUpTimer invalidate];
    _scrollUpTimer = nil;
    self.scrollUpImage.hidden = YES;
}

- (void)resetScrollUpHelper:(NSTimeInterval)t
{
    [self cancelScrollUpHelper];
    _scrollUpTimer = [NSTimer scheduledTimerWithTimeInterval:t
                                                      target:self
                                                    selector:@selector(showScrollUpHelper)
                                                    userInfo:nil
                                                     repeats:NO];
}

- (void)showSwipeLeftHelper
{
    _swipeLeftTimer = nil;
    self.swipeLeftImage.alpha = 0.f;
    self.swipeLeftImage.hidden = NO;

    UIViewAnimationOptions options = UIViewAnimationOptionRepeat | UIViewAnimationOptionAutoreverse | UIViewAnimationOptionCurveEaseOut;
    [UIView animateWithDuration:BREATHE_TIME delay:0 options:options animations:^{
        self.swipeLeftImage.alpha = 1.f;
    } completion:nil];
}

- (void)cancelSwipeLeftHelper
{
    [_swipeLeftTimer invalidate];
    _swipeLeftTimer = nil;
    self.swipeLeftImage.hidden = YES;
}

- (void)resetSwipeLeftHelper:(NSTimeInterval)t
{
    [self cancelSwipeLeftHelper];
    _swipeLeftTimer = [NSTimer scheduledTimerWithTimeInterval:t
                                                       target:self
                                                     selector:@selector(showSwipeLeftHelper)
                                                     userInfo:nil
                                                      repeats:NO];
}

@end
