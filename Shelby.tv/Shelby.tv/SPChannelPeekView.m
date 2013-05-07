//
//  SPChannelPeekView.m
//  Shelby.tv
//
//  Created by Keren on 4/17/13.
//  Copyright (c) 2013 Shelby TV. All rights reserved.
//

#import "SPChannelPeekView.h"
#import "UIColor+ColorWithHexAndAlpha.h"

@interface SPChannelPeekView()
@property (nonatomic) UILabel *title;
@end


@implementation SPChannelPeekView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _title = [[UILabel alloc] initWithFrame:CGRectMake(kShelbySPVideoWidth / 2 - 200, 10, 400, 40)];
    }
    return self;
}

- (void)setupWithChannelDisplay:(DisplayChannel *)displayChannel;
{
    [self.title setTextAlignment:NSTextAlignmentCenter];
    NSString *color = nil;
    if (displayChannel.dashboard) {
        [self.title setText:displayChannel.dashboard.displayTitle];
        color = displayChannel.dashboard.displayColor;
    } else {
        [self.title setText:displayChannel.roll.displayTitle];
        color = displayChannel.roll.displayColor;
    }
    [self.title setTextColor:[UIColor whiteColor]];
    [self.title setFont:[UIFont fontWithName:@"Helvetica-Bold" size:28.0]];
    [self.title setBackgroundColor:[UIColor clearColor]];
    
    if (color) {
        UIColor *displayColor = [UIColor colorWithHex:color andAlpha:1];
        [self setBackgroundColor:displayColor];
    }
    
    [self addSubview:self.title];
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    [self.title setFrame:CGRectMake(kShelbySPVideoWidth / 2 - 200, frame.size.height / 2 - 20, self.title.frame.size.width, self.title.frame.size.height)];
}

@end
