//
//  SPChannelPeekView.m
//  Shelby.tv
//
//  Created by Keren on 4/17/13.
//  Copyright (c) 2013 Shelby TV. All rights reserved.
//

#import "SPChannelPeekView.h"
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

- (void)setupWithChannelDisplay:(SPChannelDisplay *)channelDisplay;
{
    [self.title setTextAlignment:NSTextAlignmentCenter];
    [self.title setText:[NSString stringWithFormat:@"# %@",[channelDisplay channelDisplayTitle]]];
    [self.title setTextColor:[UIColor whiteColor]];
    [self.title setFont:[UIFont fontWithName:@"Helvetica-Bold" size:28.0]];
    [self.title setBackgroundColor:[UIColor clearColor]];
    
    [self addSubview:self.title];
    [self setBackgroundColor:[channelDisplay channelDisplayColor]];
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    [self.title setFrame:CGRectMake(kShelbySPVideoWidth / 2 - 200, frame.size.height / 2 - 20, self.title.frame.size.width, self.title.frame.size.height)];
}

@end
