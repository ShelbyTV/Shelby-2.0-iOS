//
//  MyRollViewCell.m
//  Shelby.tv
//
//  Created by Keren on 2/15/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

#import "MyRollViewCell.h"

@interface MyRollViewCell()

@end


@implementation MyRollViewCell

#pragma mark - Customization on Instantiation
- (void)awakeFromNib
{
    [super awakeFromNib];
    [self.personalRollUsernameLabel setFrame:CGRectMake(703, 130, 278, 52)];
    [self.personalRollUsernameLabel setFont:[UIFont fontWithName:@"Ubuntu-Bold" size:_personalRollUsernameLabel.font.pointSize]];
    [self.personalRollUsernameLabel setTextColor:[UIColor colorWithHex:@"ffffff" andAlpha:1.0f]];
    [self.channelName setText:@"My Roll"];
    [self.channelDescription setText:@"Ever want to curate your own channel? Now you can with Shelby. Roll Videos to your .TV today."];
    [self.channelImage setImage:[UIImage imageNamed:@"personalRollCard.png"]];
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    [self.channelImage setImage:[UIImage imageNamed:@"personalRollCard.png"]];
}

#pragma mark - Public Methods
- (void)enableCard:(BOOL)enabled
{
    [super enableCard:enabled];
    
    [self.personalRollUsernameLabel setAlpha:(enabled ? 1.0f : 0.75f)]; // Change alpha when enabling card (instead of setting isEnabled)
}

@end
