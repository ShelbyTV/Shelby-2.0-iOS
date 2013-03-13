//
//  SignupView.m
//  Shelby.tv
//
//  Created by Keren on 3/13/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

#import "SignupView.h"

@interface SignupView()
@property (weak, nonatomic) IBOutlet UITextField *fullname;
@property (weak, nonatomic) IBOutlet UITextField *username;
@property (weak, nonatomic) IBOutlet UITextField *emailField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;
@end

@implementation SignupView

- (void)awakeFromNib
{

    [self setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"authenticationSignupView"]]];
    
    [self.fullname setFont:[UIFont fontWithName:@"Ubuntu-Bold" size:_emailField.font.pointSize]];
    [self.fullname setTextColor:kShelbyColorBlack];
    [self.username setFont:[UIFont fontWithName:@"Ubuntu-Bold" size:_passwordField.font.pointSize]];
    [self.username setTextColor:kShelbyColorBlack];
    [self.emailField setFont:[UIFont fontWithName:@"Ubuntu-Bold" size:_emailField.font.pointSize]];
    [self.emailField setTextColor:kShelbyColorBlack];
    [self.passwordField setFont:[UIFont fontWithName:@"Ubuntu-Bold" size:_passwordField.font.pointSize]];
    [self.passwordField setTextColor:kShelbyColorBlack];
 
}

@end
