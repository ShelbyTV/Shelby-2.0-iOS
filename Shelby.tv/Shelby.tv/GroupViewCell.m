//
//  GroupViewCell.m
//  Shelby.tv
//
//  Created by Keren on 2/14/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

#import "GroupViewCell.h"
#import "UIColor+ColorWithHexAndAlpha.h"

@implementation GroupViewCell

#pragma mark - Customization on Instantiation
- (void)awakeFromNib
{
    [self.groupTitle setFont:[UIFont fontWithName:@"Ubuntu-Bold" size:20]];
    [self.groupDescription setFont:[UIFont fontWithName:@"Ubuntu" size:14]];
    
    UIColor *textColor = [UIColor colorWithHex:@"333333" andAlpha:1];
    [self.groupDescription setTextColor:textColor];
    [self.groupTitle setTextColor:textColor];
}

- (void)prepareForReuse
{
    [self.groupThumbnailImage setImage:[UIImage imageNamed:@"missingCard"]];
}

#pragma mark - Public Methods
- (void)enableCard:(BOOL)enabled
{
    [self.groupThumbnailImage setAlpha:(enabled ? 1.0f : 0.75f)];
    [self.groupDescription setEnabled:enabled];
    [self.groupTitle setEnabled:enabled];
}

@end
