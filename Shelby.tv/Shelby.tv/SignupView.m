//
//  SignupView.m
//  Shelby.tv
//
//  Created by Keren on 3/13/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

#import "SignupView.h"

@interface SignupView()

@end

@implementation SignupView

- (void)awakeFromNib
{

    [super awakeFromNib];
    [self setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"authenticationSignupView.png"]]];
    
    [self.fullname setFont:[UIFont fontWithName:@"Ubuntu-Bold" size:_emailField.font.pointSize]];
    [self.fullname setTextColor:kShelbyColorBlack];
    [self.username setFont:[UIFont fontWithName:@"Ubuntu-Bold" size:_passwordField.font.pointSize]];
    [self.username setTextColor:kShelbyColorBlack];
    [self.emailField setFont:[UIFont fontWithName:@"Ubuntu-Bold" size:_emailField.font.pointSize]];
    [self.emailField setTextColor:kShelbyColorBlack];
    [self.passwordField setFont:[UIFont fontWithName:@"Ubuntu-Bold" size:_passwordField.font.pointSize]];
    [self.passwordField setTextColor:kShelbyColorBlack];
 
}


- (void)processingForm
{
    [super processingForm];
}

- (void)resetForm
{
    [super resetForm];
    
    [self.fullname becomeFirstResponder];
}

- (BOOL)selectNextField:(UITextField *)textField
{
    BOOL lastTextField = [super selectNextField:textField];
    
    if (textField == self.fullname) {
        [self.emailField becomeFirstResponder];
    } else if (textField == self.emailField) {
        [self.username becomeFirstResponder];
    } else if (textField == self.username) {
        [self.passwordField becomeFirstResponder];
    } else {
        lastTextField = YES;
    }
    
    return lastTextField;
}

- (BOOL)validateFields
{
    BOOL valid = YES;
    
    if (![[self.emailField text] length]) {
        valid = NO;
        [self markTextField:self.emailField];
    }
    
    if (![[self.passwordField text] length]) {
        valid = NO;
        [self markTextField:self.passwordField];
    }

    if (![[self.fullname text] length]) {
        valid = NO;
        [self markTextField:self.fullname];
    }
    
    if (![[self.username text] length]) {
        valid = NO;
        [self markTextField:self.username];
    }
    
    return valid;
}


@end
