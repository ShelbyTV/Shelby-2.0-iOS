//
//  LoginView.m
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 2/9/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

#import "LoginView.h"

@interface LoginView ()
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *goButton;
@property (weak, nonatomic) IBOutlet UIButton *signupButton;
@end

@implementation LoginView

- (void)awakeFromNib
{
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
}

- (void)resetForm
{
    [super resetForm];
    
    [self.emailField becomeFirstResponder];

}


- (void)selectNextField:(UITextField *)textField
{
    [super selectNextField:textField];
    
    if (textField == self.emailField) {
        [self.passwordField becomeFirstResponder];
    }
}

- (BOOL)validateFields
{
    if ([[self.emailField text] length] && [[self.passwordField text] length]) {
        return YES;
    }
    
    return NO;
}

@end
