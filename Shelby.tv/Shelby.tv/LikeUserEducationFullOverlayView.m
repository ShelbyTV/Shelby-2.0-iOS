//
//  LikeUserEducationFullOverlayView.m
//  Shelby.tv
//
//  Created by Joshua Samberg on 4/7/14.
//  Copyright (c) 2014 Shelby TV, Inc. All rights reserved.
//

#import "LikeUserEducationFullOverlayView.h"

@interface LikeUserEducationFullOverlayView ()
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *paragraphToImageVerticalSpaceConstraint;

@end

@implementation LikeUserEducationFullOverlayView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {

    }
    return self;
}



-(void)layoutSubviews
{
    UIDeviceOrientation currentOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (UIDeviceOrientationIsPortrait(currentOrientation))
    {
        self.paragraphToImageVerticalSpaceConstraint.constant = 50;
    } else {
        self.paragraphToImageVerticalSpaceConstraint.constant = 10;
    }

    [super layoutSubviews];
}

@end
