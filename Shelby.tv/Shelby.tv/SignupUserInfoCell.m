//
//  SignupUserInfoCell.m
//  Shelby.tv
//
//  Created by Keren on 7/10/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "SignupUserInfoCell.h"

@interface SignupUserInfoCell()
- (IBAction)assignAvatar:(id)sender;
@end

@implementation SignupUserInfoCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (IBAction)assignAvatar:(id)sender
{
    [self.delegate assignAvatar];
}

@end
