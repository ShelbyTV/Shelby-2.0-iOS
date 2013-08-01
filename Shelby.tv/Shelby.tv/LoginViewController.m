//
//  LoginViewController.m
//  Shelby.tv
//
//  Created by Daniel Spinosa on 7/18/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "LoginViewController.h"

@interface LoginViewController ()
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *loginButton;
@property (weak, nonatomic) IBOutlet UITextField *usernameField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;
@property (weak, nonatomic) IBOutlet UIButton *signupButton;

@end

@implementation LoginViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.usernameField.delegate = self;
    self.passwordField.delegate = self;

    [self.usernameField becomeFirstResponder];

    //non-IB view customizations
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bkgd-step1.png"]];

    // Next Button
    NSString *nextTitle = self.navigationItem.rightBarButtonItem.title;
    SEL selector = self.navigationItem.rightBarButtonItem.action;
    UIButton *nextButton = [UIButton buttonWithType:UIButtonTypeCustom];
    nextButton.frame = CGRectMake(0, 0, 60, 44);
    [nextButton setTitleColor:kShelbyColorGreen forState:UIControlStateNormal];
    [nextButton addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];
    [nextButton setTitle:nextTitle forState:UIControlStateNormal];
    nextButton.titleLabel.font = kShelbyFontH4Bold;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:nextButton];
    self.loginButton = self.navigationItem.rightBarButtonItem;

    // Cancel Button
    NSString *cancelTitle = self.navigationItem.leftBarButtonItem.title;
    selector = self.navigationItem.leftBarButtonItem.action;
    UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    cancelButton.frame = CGRectMake(0, 0, 60, 44);
    [cancelButton setTitleColor:kShelbyColorGray forState:UIControlStateNormal];
    [cancelButton addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];
    [cancelButton setTitle:cancelTitle forState:UIControlStateNormal];
    cancelButton.titleLabel.font = kShelbyFontH4Bold;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:cancelButton];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutorotate
{
    return NO;
}

- (IBAction)cancelTapped:(UIBarButtonItem *)sender {
    [self.delegate loginViewControllerDidCancel:self];
}

- (IBAction)loginTapped:(UIBarButtonItem *)sender {
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    spinner.frame = CGRectMake(10, 10, 50, 44);
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:spinner];
    [spinner startAnimating];
    [self.delegate loginViewController:self loginWithUsername:self.usernameField.text password:self.passwordField.text];
}

- (IBAction)signupTapped:(id)sender {
    [self.delegate loginViewControllerWantsSignup:self];
}

- (IBAction)forgotPasswordTapped:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:kShelbyForgotPasswordURL]];
}

- (void)loginFailed:(NSString *)errorMessage
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Login Error"
                                                        message:errorMessage
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil, nil];
    [alertView show];
}

#pragma mark - UIAlertViewDelegate Methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    self.navigationItem.rightBarButtonItem = self.loginButton;
    self.passwordField.text = @"";
    [self.passwordField becomeFirstResponder];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.usernameField) {
        [self.passwordField becomeFirstResponder];
    } else if (textField == self.passwordField) {
        [self loginTapped:nil];
    }
    return YES;
}

@end
