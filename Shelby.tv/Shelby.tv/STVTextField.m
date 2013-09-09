//
//  STVTextField.m
//  Shelby.tv
//
//  Created by Daniel Spinosa on 7/18/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "STVTextField.h"

@implementation STVTextField

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self updateAppearance];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self updateAppearance];
    }
    return self;
}

- (void)updateAppearance
{
    UIImage *textFieldBackground = [[UIImage imageNamed:@"textfield-outline-background"] resizableImageWithCapInsets:UIEdgeInsetsMake(2, 2, 2, 2)];
    [self setBackground:textFieldBackground];

    self.layer.cornerRadius = 2.0;
    self.borderStyle = UITextBorderStyleNone;
}

- (CGRect)placeholderRectForBounds:(CGRect)bounds
{
    return [self editingRectForBounds:bounds];
}

-(CGRect)textRectForBounds:(CGRect)bounds
{
    return [self editingRectForBounds:bounds];
}

- (CGRect)editingRectForBounds:(CGRect)bounds
{
    return CGRectInset(bounds, 14, 0);
}

@end
