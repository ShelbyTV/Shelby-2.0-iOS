//
//  SPVideoItemViewCellLabel.m
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 4/17/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

#import "SPVideoItemViewCellLabel.h"

@implementation SPVideoItemViewCellLabel

- (void)drawTextInRect:(CGRect)rect
{
    UIEdgeInsets insets = {0.0f, 10.0f, 0.0f, 10.0f};
    return [super drawTextInRect:UIEdgeInsetsInsetRect(rect, insets)];
}

@end
