//
//  CategoryViewCell.m
//  Shelby.tv
//
//  Created by Keren on 2/14/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

#import "CategoryViewCell.h"

@implementation CategoryViewCell

#pragma mark - Customization on Instantiation
- (void)awakeFromNib
{
    [self.categoryTitle setFont:[UIFont fontWithName:@"Ubuntu-Bold" size:25]];

    [self.categoryDescription setFont:[UIFont fontWithName:@"Ubuntu" size:14]];
}

- (void)prepareForReuse
{
    [self.categoryThumbnailImage setImage:[UIImage imageNamed:@"missingCard"]];
}

#pragma mark - Public Methods
- (void)enableCard:(BOOL)enabled
{
    [self.categoryThumbnailImage setAlpha:(enabled ? 1.0f : 0.75f)];
    [self.categoryDescription setEnabled:enabled];
    [self.categoryTitle setEnabled:enabled];
}

@end
