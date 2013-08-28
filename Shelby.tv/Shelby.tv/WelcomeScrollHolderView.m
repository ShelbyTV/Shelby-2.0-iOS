//
//  WelcomeScrollHolderView.m
//  Shelby.tv
//
//  Created by Daniel Spinosa on 8/28/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "WelcomeScrollHolderView.h"

@interface WelcomeScrollHolderView()
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@property (weak, nonatomic) IBOutlet UIImageView *tip1;
@property (weak, nonatomic) IBOutlet UIImageView *tip2;
@property (weak, nonatomic) IBOutlet UIImageView *tip3;

@end

#define PAGES_IN_SCROLL_VIEW 4

@implementation WelcomeScrollHolderView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self addSubview:[[NSBundle mainBundle] loadNibNamed:@"WelcomeScrollHolderView" owner:self options:nil][0]];
        self.titleLabel.font = kShelbyFontH2;
        [self initScroller];
        [self showTip:0];
    }
    return self;
}

- (void)initScroller
{
    self.scrollView.delegate = self;

    UIView *page0 = [self pageForImageNamed:@"welcome-page-0" atIndex:0];
    [self.scrollView addSubview:page0];
    UIView *page1 = [self pageForImageNamed:@"welcome-page-1" atIndex:1];
    [self.scrollView addSubview:page1];
    UIView *page2 = [self pageForImageNamed:@"welcome-page-2" atIndex:2];
    [self.scrollView addSubview:page2];

    //TODO: 3a and 3b go into their own little scroller, so they can slide left/right
    UIView *page3a = [self pageForImageNamed:@"welcome-page-3a" atIndex:3];
    [self.scrollView addSubview:page3a];
//    UIView *page3b = [self pageForImageNamed:@"welcome-page-3b" atIndex:3];
//    [self.scrollView addSubview:page3b];
    self.scrollView.contentSize = CGSizeMake(self.scrollView.bounds.size.width, self.scrollView.bounds.size.height * PAGES_IN_SCROLL_VIEW);
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self showTip:0];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self.scrollViewDelegate scrollViewDidScroll:scrollView];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    NSInteger page = scrollView.contentOffset.y / scrollView.bounds.size.height;
    [self showTip:page];
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
    [self.scrollViewDelegate scrollViewWillEndDragging:scrollView withVelocity:velocity targetContentOffset:targetContentOffset];
}

#pragma mark - View Helpers

- (void)showTip:(NSUInteger)tipIdx
{
    for (UIImageView *t in @[self.tip1, self.tip2, self.tip3]) {
        t.hidden = YES;
    }

    switch (tipIdx) {
        case 1:
            //TODO: change title
            self.tip1.hidden = NO;
            break;
        case 2:
            //TODO: change title
            self.tip2.hidden = NO;
            break;
        case 3:
            //TODO: change title
            self.tip3.hidden = NO;
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

@end
