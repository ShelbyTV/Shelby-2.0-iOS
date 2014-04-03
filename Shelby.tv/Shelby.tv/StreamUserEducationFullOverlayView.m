//
//  StreamUserEducationFullOverlayView.m
//  Shelby.tv
//
//  Created by Joshua Samberg on 4/3/14.
//  Copyright (c) 2014 Shelby TV, Inc. All rights reserved.
//

#import "StreamUserEducationFullOverlayView.h"

@interface StreamUserEducationFullOverlayView ()
@property (weak, nonatomic) IBOutlet UILabel *topTextLabel;

@end

@implementation StreamUserEducationFullOverlayView

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
    NSString *topLabelText;
    if (UIDeviceOrientationIsPortrait(currentOrientation))
    {
        topLabelText = @"We'll add videos\nfrom channels\nand people you follow\nto your stream.";
    } else {
        topLabelText = @"We'll add videos from channels\nand people you follow to your stream.";
    }
    [self.topTextLabel setText:topLabelText];

    [super layoutSubviews];
}

@end
