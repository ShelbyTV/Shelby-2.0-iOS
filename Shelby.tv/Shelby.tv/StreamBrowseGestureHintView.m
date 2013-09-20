//
//  StreamBrowseGestureHintView.m
//  Shelby.tv
//
//  Created by Daniel Spinosa on 9/20/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "StreamBrowseGestureHintView.h"

@interface StreamBrowseGestureHintView()
@property (weak, nonatomic) IBOutlet UILabel *swipeLabel;
@end

@implementation StreamBrowseGestureHintView

- (void)awakeFromNib
{
    self.swipeLabel.font = kShelbyFontH4Bold;
}

//to allow touch events to pass through the background
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    return NO;
}

- (void)layoutSubviews
{
    
}

@end
