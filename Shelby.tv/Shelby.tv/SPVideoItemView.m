//
//  SPVideoItemView.m
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 12/7/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

#import "SPVideoItemView.h"

@interface SPVideoItemView ()

@property (weak, nonatomic) IBOutlet UIButton *invisibleButton;

@end

@implementation SPVideoItemView

#pragma mark - View Loading Methods
- (void)awakeFromNib
{
    [self.videoTitleLabel setFont:[UIFont fontWithName:@"Ubuntu-Medium" size:_videoTitleLabel.font.pointSize]];
}

#pragma mark - Class Methods
+ (CGFloat)width
{
    if (DEVICE_IPAD) {
        return 234.0f;
    } else {
        return 100.0f;
    }
}

+ (CGFloat)height
{
    if (DEVICE_IPAD) {
        return 197.0f;
    } else {
        return 100;
    }
}

@end
