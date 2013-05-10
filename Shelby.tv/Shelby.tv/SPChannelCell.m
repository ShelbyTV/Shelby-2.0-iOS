//
//  SPChannelCell.m
//  Shelby.tv
//
//  Created by Keren on 4/15/13.
//  Copyright (c) 2013 Shelby TV. All rights reserved.
//

#import "SPChannelCell.h"

@interface SPChannelCell()
@property (weak, nonatomic) IBOutlet UILabel *channelTitle;
@property (weak, nonatomic) IBOutlet UIView *channelColorView;
@property (weak, nonatomic) IBOutlet UIView *customBackgroundView;

@property (strong, nonatomic) UIColor *colorBeforeRefreshing;
@property (strong, nonatomic) NSString *titleBeforeRefreshing;
@property (assign, nonatomic) CGRect channelCollectionFrameBeforeRefreshing;

@end

@implementation SPChannelCell


- (void)awakeFromNib
{
    [[self selectedBackgroundView] setBackgroundColor:[UIColor clearColor]];
    [self.contentView setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"channelbg.png"]]];
    self.channelCollectionView.parentCell = self;
}

- (void)setColor:(UIColor *)color
{
    _color = color ?: kShelbyColorGreen;
    [self updateDisplayWithColor:_color];
}

- (void)updateDisplayWithColor:(UIColor *)color
{
    self.customBackgroundView.backgroundColor = color;
    self.channelColorView.backgroundColor = color;
    self.channelTitle.backgroundColor = color;
    self.channelCollectionView.channelColor = color;
    self.channelCollectionView.backgroundColor = color;
    self.loadMoreActivityIndicator.color = color;
}

- (void)setProximityToRefreshMode:(float)pct
{
    CGFloat hue, saturation, brightness, alpha;
    if ([_color getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha]) {
        brightness *= (1.0+pct);
        saturation -= (saturation * pct);
        [self updateDisplayWithColor:[UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:alpha]];
    }
}

- (void)setTitle:(NSString *)title
{
    _title = title;
    
    self.channelTitle.text = _title;
    CGSize maxCaptionSize = CGSizeMake(self.frame.size.width - 10, self.channelTitle.frame.size.height);
    CGFloat titleLabelWidth = [title sizeWithFont:[self.channelTitle font]
                                            constrainedToSize:maxCaptionSize
                                                lineBreakMode:NSLineBreakByWordWrapping].width;
    [self.channelTitle setFrame:CGRectMake(self.channelTitle.frame.origin.x, self.channelTitle.frame.origin.y, titleLabelWidth + 10, self.channelTitle.frame.size.height)];
}

- (void) setWillRefresh:(BOOL)willRefresh
{
    if(_willRefresh != willRefresh){
        _willRefresh = willRefresh;
        if(_willRefresh){
            self.titleBeforeRefreshing = self.title;
            self.title = @"Refresh?";
            self.channelTitle.textColor = [UIColor blackColor];
            
            self.colorBeforeRefreshing = self.color;
            self.channelCollectionFrameBeforeRefreshing = self.channelCollectionView.frame;
        } else {
            self.title = self.titleBeforeRefreshing;
            self.channelTitle.textColor = [UIColor whiteColor];
        }
    }
    
}

#define REFRESH_X_PUSH 110
- (void) setIsRefreshing:(BOOL)isRefreshing
{
    _isRefreshing = isRefreshing;
    if (_isRefreshing) {
        [self.refreshActivityIndicator startAnimating];
        self.title = @"Refreshing...";
        self.channelTitle.textColor = [UIColor whiteColor];
        self.color = [UIColor blackColor];
        [UIView animateWithDuration:0.2 animations:^{
            self.channelCollectionView.frame = CGRectMake(self.channelCollectionView.frame.origin.x + REFRESH_X_PUSH, self.channelCollectionView.frame.origin.y, self.channelCollectionView.frame.size.width, self.channelCollectionView.frame.size.height);
        }];
    } else if(_willRefresh) {
        self.willRefresh = NO;
        self.color = self.colorBeforeRefreshing;
        [UIView animateWithDuration:0.5 animations:^{
            self.channelCollectionView.frame = self.channelCollectionFrameBeforeRefreshing;
        }];
    }
}

@end
