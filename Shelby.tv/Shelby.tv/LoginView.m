//
//  LoginView.m
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 2/9/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

#import "LoginView.h"

@interface LoginView ()

@end

@implementation LoginView

- (void)dealloc
{
    self.cancelButton = nil;
    self.goButton = nil;
    self.emailField = nil;
    self.passwordField = nil;
    self.indicator = nil;
}


- (void)awakeFromNib
{
    
    [self.emailField setFont:[UIFont fontWithName:@"Ubuntu-Bold" size:_emailField.font.pointSize]];
    [self.emailField setTextColor:kColorBlack];

    [self.passwordField setFont:[UIFont fontWithName:@"Ubuntu-Bold" size:_passwordField.font.pointSize]];
    [self.passwordField setTextColor:kColorBlack];
    
    [self.indicator setHidden:YES];
    [self.indicator setHidesWhenStopped:YES];

    
}

- (void)userAuthenticationDidFail
{

    [self.indicator stopAnimating];
    [self.cancelButton setEnabled:YES];
    [self.goButton setEnabled:YES];
    [self.emailField setEnabled:YES];
    [self.passwordField setEnabled:YES];
    
}

@end
