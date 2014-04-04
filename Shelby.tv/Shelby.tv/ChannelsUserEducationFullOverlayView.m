//
//  ChannelsUserEducationFullOverlayView.m
//  Shelby.tv
//
//  Created by Joshua Samberg on 4/4/14.
//  Copyright (c) 2014 Shelby TV, Inc. All rights reserved.
//

#import "ChannelsUserEducationFullOverlayView.h"

@interface ChannelsUserEducationFullOverlayView ()
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *welcomeToParagraphBottomConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *paragraphVerticalCenterConstraint;

@end

@implementation ChannelsUserEducationFullOverlayView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

-(void)layoutSubviews
{
    UIDeviceOrientation currentOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (UIDeviceOrientationIsPortrait(currentOrientation))
    {
        self.welcomeToParagraphBottomConstraint.constant = 30;
        self.paragraphVerticalCenterConstraint.constant = 0;
    } else {
        self.welcomeToParagraphBottomConstraint.constant = 2;
        self.paragraphVerticalCenterConstraint.constant = -10;
    }

    [super layoutSubviews];
}

@end
