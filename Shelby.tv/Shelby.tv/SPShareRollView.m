//
//  SPShareRollView.m
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 2/20/13.
//  Copyright (c) 2013 Shelby TV. All rights reserved.
//

#import "SPShareRollView.h"

@implementation SPShareRollView

- (void)awakeFromNib
{
    [self.videoTitleLabel setFont:[UIFont fontWithName:@"Ubuntu-Bold" size:_videoTitleLabel.font.pointSize]];
}

@end
