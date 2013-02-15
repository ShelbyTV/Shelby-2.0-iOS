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
    [self.channelName setFont:[UIFont fontWithName:@"Ubuntu-Bold" size:25]];

    [self.channelDescription setFont:[UIFont fontWithName:@"Ubuntu" size:11]];
}

@end
