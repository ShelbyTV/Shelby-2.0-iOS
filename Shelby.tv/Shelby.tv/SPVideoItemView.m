//
//  SPVideoItemView.m
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 12/7/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

#import "SPVideoItemView.h"

@implementation SPVideoItemView
@synthesize videoTitleLabel = _videoTitleLabel;
@synthesize thumbnailImageView = _thumbnailImageView;
@synthesize invisibleButton = _invisibleButton;

- (void)dealloc
{
    self.videoTitleLabel = nil;
    self.thumbnailImageView = nil;
    self.invisibleButton = nil;
}

- (void)awakeFromNib
{
    self.thumbnailImageView.frame = CGRectMake(10, 40, 200, 147);
}

@end
