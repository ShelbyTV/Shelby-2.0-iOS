//
//  PageControl.m
//  Shelby.tv
//
//  Created by Keren on 2/18/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

#import "PageControl.h"

#define kShelbyPageControlSpacing 8.0

@interface PageControl()

@end

@implementation PageControl

- (void) awakeFromNib {
    // Removing regular dots
    for (UIView *view in self.subviews) {
        [view removeFromSuperview];
    }
    
    // Make sure the view is redrawn not scaled when the device is rotated
    self.contentMode = UIViewContentModeRedraw;
}

- (void)drawRect:(CGRect)iRect {
    iRect = self.bounds;
    
    if (self.opaque) {
        [self.backgroundColor set];
        UIRectFill(iRect);
    }
    
    if (self.hidesForSinglePage && self.numberOfPages == 1) {
        return;
    }
    
    UIImage *dotSelected = [UIImage imageNamed: @"dotSelected.png"];
    UIImage *dotNotSelected = [UIImage imageNamed: @"dotNotSelected.png"];

    CGRect rect;
    rect.size.height = dotSelected.size.height;
    rect.size.width = self.numberOfPages * dotSelected.size.width + (self.numberOfPages - 1) * kShelbyPageControlSpacing;
    rect.origin.x = floorf((iRect.size.width - rect.size.width) / 2.0);
    rect.origin.y = floorf((iRect.size.height - rect.size.height) / 2.0);
    rect.size.width = dotSelected.size.width;
    
    UIImage *image = nil;
    for (int i = 0; i < self.numberOfPages; ++i) {
        if (i == self.currentPage) {
            if (i == 0) {
                image = [UIImage imageNamed:@"meSelected.png"];
            } else {
                image = dotSelected;
            }
        } else {
            if (i == 0) {
                image = [UIImage imageNamed:@"meNotSelected.png"];
            } else {
                image = dotNotSelected;
            }
        }
        
        [image drawInRect: rect];
        
        rect.origin.x += dotSelected.size.width + kShelbyPageControlSpacing;
    }
}


#pragma mark UIPageControl Methods
- (void)setCurrentPage:(NSInteger)page {
    [super setCurrentPage:page];
    [self setNeedsDisplay];
}


- (void)setNumberOfPages:(NSInteger)pages {
    [super setNumberOfPages:pages];
    [self setNeedsDisplay];
}

@end
