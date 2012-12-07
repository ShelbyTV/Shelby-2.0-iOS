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

- (void)dealloc
{
    self.videoTitleLabel = nil;
    self.thumbnailImageView = nil;
}

- (void)awakeFromNib
{
    
}

@end
