//
//  TopAlignedLabel.m
//  Shelby Genius
//
//  Created by Arthur Ariel Sabintsev on 8/26/12.
//  Copyright (c) 2012 Shelby TV. All rights reserved.
//

#import "TopAlignedLabel.h"

@implementation TopAlignedLabel

- (void)drawRect:(CGRect)rect
{
    rect.size.height = [self.text sizeWithFont:self.font constrainedToSize:rect.size lineBreakMode:self.lineBreakMode].height;
    
    if (self.numberOfLines != 0) {
        rect.size.height = MIN(rect.size.height, self.numberOfLines * self.font.lineHeight);
    }
    
    [super drawTextInRect:rect];
}


@end
