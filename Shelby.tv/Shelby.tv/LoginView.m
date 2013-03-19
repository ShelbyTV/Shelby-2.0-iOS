//
//  LoginView.m
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 2/9/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

#import "LoginView.h"
#import <QuartzCore/QuartzCore.h>

@interface LoginView ()
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *goButton;
@property (weak, nonatomic) IBOutlet UIButton *signupButton;
@end

@implementation LoginView

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"authenticationLoginView.png"]]];

    [self.emailField setFont:[UIFont fontWithName:@"Ubuntu-Bold" size:_emailField.font.pointSize]];
    [self.emailField setTextColor:kShelbyColorBlack];

    [self.passwordField setFont:[UIFont fontWithName:@"Ubuntu-Bold" size:_passwordField.font.pointSize]];
    [self.passwordField setTextColor:kShelbyColorBlack];
    
    [[self.signupButton titleLabel] setFont:[UIFont fontWithName:@"Ubuntu" size:_signupButton.titleLabel.font.pointSize]];
}


- (void)processingForm
{
    [super processingForm];
    [self resetTextField:self.emailField];
    [self resetTextField:self.passwordField];
}

- (void)resetForm
{
    [super resetForm];
    
    [self.emailField becomeFirstResponder];

}


- (BOOL)selectNextField:(UITextField *)textField
{
    BOOL lastTextField = [super selectNextField:textField];
    
    if (textField == self.emailField) {
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
    
    return valid;
}

- (void)showErrors:(NSDictionary *)errors
{
    [self markTextField:self.emailField];
    [self markTextField:self.passwordField];
}

@end
