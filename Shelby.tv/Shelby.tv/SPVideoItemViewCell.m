//
//  SPVideoItemViewCell.m
//  Shelby.tv
//
//  Created by Keren on 4/12/13.
//  Copyright (c) 2013 Shelby TV. All rights reserved.
//

#import "SPVideoItemViewCell.h"
#import "SPVideoItemViewCellLabel.h"

@interface SPVideoItemViewCell()

@end

@implementation SPVideoItemViewCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        _thumbnailImageView.contentMode = UIViewContentModeScaleAspectFill;
        _thumbnailImageView.clipsToBounds = YES;
    }
    return self;
}

- (void)prepareForReuse
{
    self.thumbnailImageView.image = nil;
    [self unHighlightItem];
}

- (void)highlightItemWithColor:(UIColor *)color
{
    [self.caption setBackgroundColor:color];
    [self.caption setAlpha:1];
}

- (void)unHighlightItem
{
    [self.caption setBackgroundColor:[UIColor blackColor]];
    [self.caption setAlpha:0.7];
}

@end
