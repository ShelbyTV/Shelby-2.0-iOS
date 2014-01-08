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
    rect.size.height = [self.text boundingRectWithSize:rect.size options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName : self.font} context:nil].size.height;
    
    if (self.numberOfLines != 0) {
        rect.size.height = MIN(rect.size.height, self.numberOfLines * self.font.lineHeight);
    }
    
    [super drawTextInRect:rect];
}


@end
