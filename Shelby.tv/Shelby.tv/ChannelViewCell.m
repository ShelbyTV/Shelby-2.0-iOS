//
//  ChannelViewCell.m
//  Shelby.tv
//
//  Created by Keren on 2/14/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

#import "ChannelViewCell.h"

@implementation ChannelViewCell

#pragma mark - Customization on Instantiation
- (void)awakeFromNib
{
    [self.channelName setFont:[UIFont fontWithName:@"Ubuntu-Medium" size:_channelName.font.pointSize]];

    [self.channelDescription    setFont:[UIFont fontWithName:@"Ubuntu" size:_channelDescription.font.pointSize]];
}

@end
