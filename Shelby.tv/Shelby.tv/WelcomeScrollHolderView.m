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
    NSTimer *_scrollUpTimer;
    NSTimer *_swipeLeftTimer;
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
}

- (void)initScroller
{
    self.scrollView.delegate = self;

    //page 0 is movie
    [self initPlayerWithMovie:@"hungry" atIndex:0];
    [self.scrollView addSubview:_player.view];
    [_player play];

    UIView *page1 = [self pageForImageNamed:@"welcome-h-p1" atIndex:1];
    [self.scrollView addSubview:page1];
    UIView *page2 = [self pageForImageNamed:@"welcome-h-p2" atIndex:2];
    [self.scrollView addSubview:page2];
    UIView *page3a = [self pageForImageNamed:@"welcome-h-p3-bg" atIndex:3];
    [self.scrollView addSubview:page3a];
    self.scrollView.contentSize = CGSizeMake(self.scrollView.bounds.size.width, self.scrollView.bounds.size.height * PAGES_IN_SCROLL_VIEW);

    //TODO: add p3 summary + detail overlays
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if (scrollView.contentOffset.y < (scrollView.contentSize.height-scrollView.bounds.size.height)) {
        [self showTip:999];
    }
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
    [self showTip:page];
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
            [self resetScrollUpHelper:6.0];
            break;
        case 1:
            [self zoomInOnPhone];
            [self changeTitleText:@"...from your favorite people and places."
                          tipText:@"Shelby users share great new video all day long"];
            for (NSArray *tipCollection in @[self.tipIconsP2, self.tipIconsP3]) {
                [self setViews:tipCollection alpha:0.f];
            }
            [self setViews:self.tipIconsP1 alpha:1.f];
            [self resetScrollUpHelper:6.0];
            break;
        case 2:
            [self zoomInOnPhone];
            [self changeTitleText:@"It's like a TV channel personalized for you."
                          tipText:@"Like and share videos to get better recommendations."];
            for (NSArray *tipCollection in @[self.tipIconsP1, self.tipIconsP3]) {
                [self setViews:tipCollection alpha:0.f];
            }
            [self setViews:self.tipIconsP2 alpha:1.f];
            [self resetScrollUpHelper:12.0];
            break;
        case 3:
            [self zoomInOnPhone];
            [self changeTitleText:@"...a TV channel powered by your friends."
                          tipText:@"Swipe left to see what your friend said."];
            for (NSArray *tipCollection in @[self.tipIconsP1, self.tipIconsP2]) {
                [self setViews:tipCollection alpha:0.f];
            }
            [self setViews:self.tipIconsP3 alpha:1.f];
            [self cancelScrollUpHelper];
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
    CGRect scrollPageBounds = self.scrollView.bounds;
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(scrollPageBounds.origin.x, idx*scrollPageBounds.size.height, scrollPageBounds.size.width, scrollPageBounds.size.height)];
    imageView.image = [UIImage imageNamed:imageName];
    return imageView;
}

- (void)initPlayerWithMovie:(NSString *)movieName atIndex:(NSUInteger)idx
{
    CGRect scrollPageBounds = self.scrollView.bounds;

    NSURL *vidURL = [[NSBundle mainBundle] URLForResource:movieName withExtension:@"m4v"];

    _player = [[MPMoviePlayerController alloc] initWithContentURL:vidURL];
    _player.view.frame = CGRectMake(scrollPageBounds.origin.x, idx*scrollPageBounds.size.height, scrollPageBounds.size.width, scrollPageBounds.size.height);
    _player.repeatMode = MPMovieRepeatModeOne;
    _player.controlStyle = MPMovieControlStyleNone;
    [_player play];
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

#pragma mark - Timers for Scroll Images

- (void)showScrollUpHelper
{
    _scrollUpTimer = nil;
    [UIView animateWithDuration:0.2 animations:^{
        self.scrollUpImage.alpha = 1.f;
    }];
}

- (void)cancelScrollUpHelper
{
    [_scrollUpTimer invalidate];
    _scrollUpTimer = nil;
    [UIView animateWithDuration:0.2 animations:^{
        self.scrollUpImage.alpha = 0.f;
    }];
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

@end
