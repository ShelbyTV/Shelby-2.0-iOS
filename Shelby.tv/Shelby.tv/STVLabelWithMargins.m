//
//  STVLabelWithMargins.m
//  Shelby.tv
//
//  Created by Dan Spinosa on 1/2/14.
//  Copyright (c) 2014 Shelby TV, Inc. All rights reserved.
//

#import "STVLabelWithMargins.h"

@implementation STVLabelWithMargins

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _margins = CGSizeZero;
    }
    return self;
}

- (CGSize)intrinsicContentSize
{
    CGSize orig = [super intrinsicContentSize];
    return CGSizeMake(orig.width + self.margins.width, orig.height + self.margins.height);
}

@end
