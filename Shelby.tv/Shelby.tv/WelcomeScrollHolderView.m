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
#import "ShelbyAnalyticsClient.h"

@interface WelcomeScrollHolderView()
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *tipLabel;
@property (weak, nonatomic) IBOutlet UIView *phoneView;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@property (strong, nonatomic) IBOutletCollection(UIImageView) NSArray *tipIconsP1;
@property (strong, nonatomic) IBOutletCollection(UIImageView) NSArray *tipIconsP2;
//@property (strong, nonatomic) IBOutletCollection(UIImageView) NSArray *tipIconsP3;

@property (weak, nonatomic) IBOutlet UIImageView *scrollUpImage;
@property (weak, nonatomic) IBOutlet UIImageView *swipeLeftImage;
@end

#define PAGES_IN_SCROLL_VIEW 3

@implementation WelcomeScrollHolderView{
    MPMoviePlayerController *_player;
    NSTimer *_scrollUpTimer, *_swipeLeftTimer;
    STVParallaxView *_parallaxView;
    UIView *_parallaxFg, *_parallaxBg;
    NSInteger _curScrollPage, _curParallaxPage;
    BOOL _isBouncingScroller;
}

- (void)awakeFromNib
{
    //init tip icons w/o animation
    self.tipLabel.text = nil;
    for (NSArray *tipCollection in @[self.tipIconsP1, self.tipIconsP2, /*self.tipIconsP3*/]) {
        for (UIView *view in tipCollection) {
            view.alpha = 0.f;
        }
    }

    self.titleLabel.font = kShelbyFontH2;
    [self initScroller];
    [self showTip:0];
    _curScrollPage = 0;
    _curParallaxPage = 0;
    _isBouncingScroller = NO;
}

- (void)dealloc
{
    [self cancelScrollUpHelper];
    [self cancelSwipeLeftHelper];

    // b/c scroll views have zombie issues
    self.scrollView.delegate = nil;
}

- (void)initScroller
{
    self.scrollView.delegate = self;

    //page 0 is movie
    [self initPlayerWithMovie:@"welcome-1" atIndex:0];
    [self.scrollView addSubview:_player.view];
    [_player play];

    //pages 1 and 2 are simple images
    UIView *page1 = [self pageForImageNamed:@"welcome-h-p1" atIndex:1];
    [self.scrollView addSubview:page1];
    UIView *page2 = [self pageForImageNamed:@"welcome-h-p2" atIndex:2];
    [self.scrollView addSubview:page2];

    /* 
     * Not Using Page 3 (with left/right swiping) for now
     *
    //page 3 has swipeable summary/detail
    [self initParallaxViewAtIndex:3];
    UIView *page3a = _parallaxView;
    [self.scrollView addSubview:page3a];
     */

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

/* PAGE 3 UNUSED */
- (void)parallaxDidChange:(STVParallaxView *)parallaxView
{
    //ignore
}

/* PAGE 3 UNUSED */
- (void)didScrollToPage:(NSUInteger)page
{
    _curParallaxPage = page;
    switch (page) {
        case 0:
            [self cancelScrollUpHelper];
            [self resetSwipeLeftHelper:.5];
            [ShelbyAnalyticsClient trackScreen:kAnalyticsScreenWelcomeA4l];
            break;
        case 1:
            [self cancelSwipeLeftHelper];
            [self resetScrollUpHelper:1.5];
            [ShelbyAnalyticsClient trackScreen:kAnalyticsScreenWelcomeA4r];
            break;
        default:
            break;
    }
}

#pragma mark - Tip Management

#define HIDE_DURATION 0.3
#define HIDE_DELAY 0.0
#define TITLE_SHOW_DURATION 0.5
#define TIP_SHOW_DURATION 1.0
#define TIP_SHOW_DELAY 0.5

- (void)showTip:(NSUInteger)tipIdx
{
    switch (tipIdx) {
        case 0:
            [self zoomOutOnPhone];
            [self changeTitleText:@"Discover videos you and your friends will love."
                          tipText:@""];
            for (NSArray *tipCollection in @[self.tipIconsP1, self.tipIconsP2/*, self.tipIconsP3*/]) {
                [self setViews:tipCollection alpha:0.f duration:HIDE_DURATION delay:HIDE_DELAY];
            }
            [self resetScrollUpHelper:2.0];
            [self cancelSwipeLeftHelper];
            [ShelbyAnalyticsClient trackScreen:kAnalyticsScreenWelcomeA1];
            break;
        case 1:
            [self zoomInOnPhone];
            [self changeTitleText:@"See what videos your friends Like."
                          tipText:@""];
            for (NSArray *tipCollection in @[self.tipIconsP2/*, self.tipIconsP3*/]) {
                [self setViews:tipCollection alpha:0.f duration:HIDE_DURATION delay:HIDE_DELAY];
            }
            [self setViews:self.tipIconsP1 alpha:1.f duration:TIP_SHOW_DURATION delay:TIP_SHOW_DELAY];
            [self resetScrollUpHelper:4.0];
            [self cancelSwipeLeftHelper];
            [ShelbyAnalyticsClient trackScreen:kAnalyticsScreenWelcomeA2];
            break;
        case 2:
            [self zoomInOnPhone];
            [self changeTitleText:@"'Like' a video and Shelby uncovers more."
                          tipText:@""];
            for (NSArray *tipCollection in @[self.tipIconsP1/*, self.tipIconsP3*/]) {
                [self setViews:tipCollection alpha:0.f duration:HIDE_DURATION delay:HIDE_DELAY];
            }
            [self setViews:self.tipIconsP2 alpha:1.f duration:TIP_SHOW_DURATION delay:TIP_SHOW_DELAY];
            [self resetScrollUpHelper:5.0];
            [self cancelSwipeLeftHelper];
            [ShelbyAnalyticsClient trackScreen:kAnalyticsScreenWelcomeA3];
            break;
        case 3: /* PAGE 3 UNUSED */
            [self zoomInOnPhone];
            [self changeTitleText:@"...a TV channel powered by your friends."
                          tipText:@"Swipe left to see what your friend said."];
            for (NSArray *tipCollection in @[self.tipIconsP1, self.tipIconsP2]) {
                [self setViews:tipCollection alpha:0.f duration:HIDE_DURATION delay:HIDE_DELAY];
            }
            /*[self setViews:self.tipIconsP3 alpha:1.f];*/
            [_parallaxView scrollToPage:0];
            [self didScrollToPage:0];
            //see didScrollToPage for continued view tracking
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

    [UIView animateWithDuration:HIDE_DURATION animations:^{
        self.titleLabel.alpha = 0.f;
        self.tipLabel.alpha = 0.f;
    } completion:^(BOOL finished) {
        self.titleLabel.text = newTitle;
        self.tipLabel.text = newTip;

        //show title and tip at different speeds
        [UIView animateWithDuration:TITLE_SHOW_DURATION animations:^{
            self.titleLabel.alpha = 1.f;
        }];
        [UIView animateWithDuration:TIP_SHOW_DURATION delay:TIP_SHOW_DELAY options:(UIViewAnimationCurveEaseInOut | UIViewAnimationOptionBeginFromCurrentState) animations:^{
            self.tipLabel.alpha = 1.f;
        } completion:nil];
    }];
}

- (void)setViews:(NSArray *)viewsArray alpha:(CGFloat)alpha duration:(NSTimeInterval)duration delay:(NSTimeInterval)delay
{
    [UIView animateWithDuration:duration delay:delay options:(UIViewAnimationCurveEaseInOut | UIViewAnimationOptionBeginFromCurrentState) animations:^{
        for (UIView *view in viewsArray) {
            view.alpha = alpha;
        }
    } completion:nil];
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
    NSURL *vidURL = [[NSBundle mainBundle] URLForResource:movieName withExtension:@"mov"];

    _player = [[MPMoviePlayerController alloc] initWithContentURL:vidURL];
    _player.view.frame = [self frameForIndex:idx];
    _player.repeatMode = MPMovieRepeatModeOne;
    _player.controlStyle = MPMovieControlStyleNone;
    _player.allowsAirPlay = NO;
    [_player play];
}

/* PAGE 3 UNUSED */
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
    if (!_isBouncingScroller) {
        _isBouncingScroller = YES;
        CGFloat startingOffsetY = self.scrollView.contentOffset.y;
        [UIView animateWithDuration:.2 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.scrollView.contentOffset = CGPointMake(0, startingOffsetY + 50);
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:.5 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                self.scrollView.contentOffset = CGPointMake(0, startingOffsetY-10);
            } completion:^(BOOL finished) {
                [UIView animateWithDuration:.2 animations:^{
                    self.scrollView.contentOffset = CGPointMake(0, startingOffsetY);
                } completion:^(BOOL finished) {
                    _isBouncingScroller = NO;
                }];
            }];

        }];
    }
}

/* PAGE 3 UNUSED */
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

/* PAGE 3 UNUSED */
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

/* PAGE 3 UNUSED */
- (void)cancelSwipeLeftHelper
{
    [_swipeLeftTimer invalidate];
    _swipeLeftTimer = nil;
    self.swipeLeftImage.hidden = YES;
}

/* PAGE 3 UNUSED */
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
