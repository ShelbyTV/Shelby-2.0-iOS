//
//  SPVideoItemView.m
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 12/7/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

#import "SPVideoItemView.h"

@implementation SPVideoItemView
@synthesize videoCaptionLabel = _videoCaptionLabel;
@synthesize thumbnailImageView = _thumbnailImageView;
@synthesize invisibleButton = _invisibleButton;


#pragma mark - Memory Mangement Methods
- (void)dealloc
{
    self.videoCaptionLabel = nil;
    self.thumbnailImageView = nil;
    self.invisibleButton = nil;
}

#pragma mark - View Loading Methods
- (void)awakeFromNib
{
    [self.videoCaptionLabel setFont:[UIFont fontWithName:@"Ubuntu-Medium" size:self.videoCaptionLabel.font.pointSize]];
}

#pragma mark - Class Methods
+ (CGFloat)width
{
    return 234.0f;
}

@end