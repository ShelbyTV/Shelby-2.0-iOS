//
//  SPVideoCategoryViewCell.m
//  Shelby.tv
//
//  Created by Keren on 4/4/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

#import "SPVideoCategoryViewCell.h"

@interface SPVideoCategoryViewCell()
@end

@implementation SPVideoCategoryViewCell


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
    }
    return self;
}


- (void)awakeFromNib
{
    [super awakeFromNib];
   [self.title setFont:[UIFont fontWithName:@"Ubuntu-Bold" size:16]];
    
    UIColor *textColor = [UIColor colorWithHex:@"333333" andAlpha:1];
    [self.title setTextColor:textColor];
    [self setCurrentCategory:NO];
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    [self.title setText:@""];
    [self setCurrentCategory:NO];
    DLog(@"size is %f",self.title.frame.size.width)
}



- (void)setCurrentCategory:(BOOL)currentCategory
{
    _currentCategory = currentCategory;
    if (self.currentCategory) {
        [self.title setTextColor:[UIColor redColor]];
    } else {
        UIColor *textColor = [UIColor colorWithHex:@"333333" andAlpha:1];
        [self.title setTextColor:textColor];
    }
}

@end
