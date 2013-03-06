//
//  PersonalRollViewCell.,
//  Shelby.tv
//
//  Created by Keren on 2/15/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

#import "PersonalRollViewCell.h"

@interface PersonalRollViewCell ()

@end


@implementation PersonalRollViewCell

#pragma mark - Customization on Instantiation
- (void)awakeFromNib
{
    [super awakeFromNib];
    [self.personalRollUsernameLabel setFrame:CGRectMake(703, 130, 278, 52)];
    [self.personalRollUsernameLabel setFont:[UIFont fontWithName:@"Ubuntu-Bold" size:_personalRollUsernameLabel.font.pointSize]];
    [self.personalRollUsernameLabel setTextColor:[UIColor colorWithHex:@"ffffff" andAlpha:1.0f]];
    [self.groupTitle setText:@"My Roll"];
    [self.groupDescription setText:@"Ever want to curate your own channel? Now you can with Shelby. Roll Videos to your .TV today."];
    [self.groupThumbnailImage setImage:[UIImage imageNamed:@"personalRollCard"]];
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    [self.groupThumbnailImage setImage:[UIImage imageNamed:@"personalRollCard"]];
}

#pragma mark - Public Methods
- (void)enableCard:(BOOL)enabled
{
    [super enableCard:enabled];
    
    [self.personalRollUsernameLabel setAlpha:(enabled ? 1.0f : 0.75f)]; // Change alpha when enabling card (instead of setting isEnabled)
}

@end
