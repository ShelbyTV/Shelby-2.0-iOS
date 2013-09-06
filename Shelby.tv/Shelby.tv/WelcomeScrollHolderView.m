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

@interface WelcomeScrollHolderView() {
    MPMoviePlayerController *_player;
}
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *tipLabel;
@property (weak, nonatomic) IBOutlet UIView *phoneView;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@end

#define PAGES_IN_SCROLL_VIEW 4

@implementation WelcomeScrollHolderView

- (void)awakeFromNib
{
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

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    NSInteger page = scrollView.contentOffset.y / scrollView.bounds.size.height;
    [self showTip:page];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    [self.scrollViewDelegate scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
}

#pragma mark - View Helpers

- (void)showTip:(NSUInteger)tipIdx
{
    switch (tipIdx) {
        case 0:
            [self zoomOutOnPhone];
            self.titleLabel.text = @"Shelby brings you 15 minutes of video everyday.";
            self.tipLabel.text = @"";
            break;
        case 1:
            [self zoomInOnPhone];
            self.titleLabel.text = @"...from your favorite people and places.";
            self.tipLabel.text = @"Shelby users share great new video all day long";
            break;
        case 2:
            [self zoomInOnPhone];
            self.titleLabel.text = @"It's like a TV channel personalized for you.";
            self.tipLabel.text = @"Like and share videos to get better recommendations.";
            break;
        case 3:
            [self zoomInOnPhone];
            self.titleLabel.text = @"...a TV channel powered by your friends.";
            self.tipLabel.text = @"Swipe left to see what your friend said.";
            break;
        default:
            break;
    }
}

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

@end
