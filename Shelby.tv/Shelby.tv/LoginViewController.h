//
//  LoginViewController.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 10/19/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

@interface LoginViewController : UIViewController <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *emailField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UILabel *versionLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *indicator;

- (IBAction)loginButtonAction:(id)sender;

@end
