//
//  GroupTableViewCell.m
//  Shelby.tv
//
//  Created by Keren on 3/28/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

#import "GroupTableViewCell.h"

@implementation GroupTableViewCell

#pragma mark - Customization on Instantiation
- (void)awakeFromNib
{
    [self.groupTitle setFont:[UIFont fontWithName:@"Ubuntu-Bold" size:20]];
    [self.groupDescription setFont:[UIFont fontWithName:@"Ubuntu" size:14]];
    
    UIColor *textColor = [UIColor colorWithHex:@"f7f7f7" andAlpha:1];
    [self.groupDescription setTextColor:textColor];
    [self.groupTitle setTextColor:textColor];
}

- (void)prepareForReuse
{
 
}

#pragma mark - Public Methods
- (void)enableCard:(BOOL)enabled
{
    [self.groupDescription setEnabled:enabled];
    [self.groupTitle setEnabled:enabled];
    [self setUserInteractionEnabled:enabled];
}

@end
