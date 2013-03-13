//
//  LoginView.m
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 2/9/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

#import "LoginView.h"

@interface LoginView ()
@property (weak, nonatomic) IBOutlet UIButton *signupButton;
@end

@implementation LoginView

- (void)awakeFromNib
{
    
    [self.emailField setFont:[UIFont fontWithName:@"Ubuntu-Bold" size:_emailField.font.pointSize]];
    [self.emailField setTextColor:kShelbyColorBlack];

    [self.passwordField setFont:[UIFont fontWithName:@"Ubuntu-Bold" size:_passwordField.font.pointSize]];
    [self.passwordField setTextColor:kShelbyColorBlack];
    
    [[self.signupButton titleLabel] setFont:[UIFont fontWithName:@"Ubuntu" size:_signupButton.titleLabel.font.pointSize]];

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
