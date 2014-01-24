//
//  SignupHeaderView.m
//  Shelby.tv
//
//  Created by Keren on 1/24/14.
//  Copyright (c) 2014 Shelby TV, Inc. All rights reserved.
//

#import "SignupHeaderView.h"
@interface SignupHeaderView()
- (IBAction)signupUser:(id)sender;
@end

@implementation SignupHeaderView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (IBAction)signupUser:(id)sender
{
    [self.delegate signupUser];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
