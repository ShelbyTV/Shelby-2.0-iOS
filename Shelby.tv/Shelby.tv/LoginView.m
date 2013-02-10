//
//  LoginView.m
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 2/9/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

#import "LoginView.h"

@implementation LoginView

- (void)dealloc
{
    self.cancelButton = nil;
    self.goButton = nil;
    self.emailField = nil;
    self.passwordField = nil;
}


- (void)awakeFromNib
{
    
    [self.emailField setFont:[UIFont fontWithName:@"Ubuntu-Bold" size:_emailField.font.pointSize]];
    [self.emailField setTextColor:kColorBlack];

    [self.passwordField setFont:[UIFont fontWithName:@"Ubuntu-Bold" size:_passwordField.font.pointSize]];
    [self.passwordField setTextColor:kColorBlack];
    
}

@end
