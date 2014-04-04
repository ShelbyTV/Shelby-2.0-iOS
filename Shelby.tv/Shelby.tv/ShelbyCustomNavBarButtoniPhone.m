//
//  ShelbyCustomNavBarButtoniPhone.m
//  Shelby.tv
//
//  Created by Joshua Samberg on 3/31/14.
//  Copyright (c) 2014 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyCustomNavBarButtoniPhone.h"

@implementation ShelbyCustomNavBarButtoniPhone

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (id)init
{
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup
{
    // Setup all the visual properties common to our custom Shelby nav bar buttons for the iPhone
    self.layer.cornerRadius = 5;
    self.layer.masksToBounds = YES;
    self.backgroundColor = kShelbyColorGreen;
    [[self titleLabel] setFont:kShelbyFontH4Bold];
    [self setTitleColor:kShelbyColorWhite forState:UIControlStateNormal];
;
}

- (CGSize)sizeThatFits:(CGSize)size
{
    CGSize newSize = [super sizeThatFits:size];
    // when auto-sizing the button, include some padding around the title
    newSize.width *= 1.25;
    return newSize;
}

@end
