//
//  SPCategoryViewCell.m
//  Shelby.tv
//
//  Created by Keren on 4/4/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

#import "SPCategoryViewCell.h"

@interface SPCategoryViewCell()
@end

@implementation SPCategoryViewCell


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
        [self.title setTextColor:[UIColor whiteColor]];
        [self setBackgroundColor:kShelbyColorGreen];
    } else {
        UIColor *textColor = [UIColor colorWithHex:@"333333" andAlpha:1];
        [self.title setTextColor:textColor];
        [self setBackgroundColor:kShelbyColorWhite];
    }
}

@end
