//
//  LoginViewController.m
//  Shelby.tv
//
//  Created by Daniel Spinosa on 7/18/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "LoginViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface LoginViewController ()
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelButton;
@property (weak, nonatomic) IBOutlet UITextField *usernameField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;
@property (strong, nonatomic) IBOutlet UIButton *loginButton;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UIButton *signupButton;
@property (weak, nonatomic) IBOutlet UIButton *loginWithFacebookButton;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIButton *forgotPasswordButton;
@property (weak, nonatomic) IBOutlet UILabel *orLabel;
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

    // Cancel Button
    NSString *cancelTitle = self.navigationItem.leftBarButtonItem.title;
    SEL selector = self.navigationItem.leftBarButtonItem.action;
    UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    cancelButton.frame = CGRectMake(0, 0, 60, 44);
    [cancelButton setTitleColor:kShelbyColorGray forState:UIControlStateNormal];
    [cancelButton addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];
    [cancelButton setTitle:cancelTitle forState:UIControlStateNormal];
    cancelButton.titleLabel.font = kShelbyFontH4Bold;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:cancelButton];

    //title font
    self.titleLabel.font = kShelbyFontH1Bold;

    //text field backgrounds
    UIImage *textFieldBackground = [[UIImage imageNamed:@"textfield-outline-background"] resizableImageWithCapInsets:UIEdgeInsetsMake(2, 2, 2, 2)];
    [self.usernameField setBackground:textFieldBackground];
    [self.passwordField setBackground:textFieldBackground];

    //button backgrounds
    [self.loginButton setBackgroundImage:[[UIImage imageNamed:@"green-button-background"] resizableImageWithCapInsets:UIEdgeInsetsMake(2, 2, 2, 2)] forState:UIControlStateNormal];
    [self.loginWithFacebookButton setBackgroundImage:[[UIImage imageNamed:@"facebook-button-background"] resizableImageWithCapInsets:UIEdgeInsetsMake(2, 2, 2, 2)] forState:UIControlStateNormal];
    UIImage *secondaryButtonBackground = [[UIImage imageNamed:@"secondary-button-background"] resizableImageWithCapInsets:UIEdgeInsetsMake(2, 2, 2, 2)];
    [self.forgotPasswordButton setBackgroundImage:secondaryButtonBackground forState:UIControlStateNormal];
    [self.signupButton setBackgroundImage:secondaryButtonBackground forState:UIControlStateNormal];
    
    self.orLabel.layer.cornerRadius = self.orLabel.frame.size.height/2;
    self.orLabel.layer.masksToBounds = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    if (DEVICE_IPAD) {
        [self.usernameField becomeFirstResponder];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [ShelbyAnalyticsClient trackScreen:kAnalyticsScreenLogin];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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

- (void)viewEnabled:(BOOL)enabled
{
    self.view.userInteractionEnabled = enabled;
    
    if (enabled) {
        self.navigationItem.rightBarButtonItem = nil;
        if (DEVICE_IPAD) {
            [self.activityIndicator stopAnimating];
        }
    } else {
        if (DEVICE_IPAD) {
            [self.activityIndicator startAnimating];
        } else {
            UIActivityIndicatorView *activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
            [activity startAnimating];
            activity.frame = CGRectMake(10, 10, 50, 44);
            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:activity];
        }
    }
}

- (IBAction)backgroundTapped:(id)sender {
    for (UIView *subview in self.view.subviews) {
        [subview resignFirstResponder];
    }
}

- (IBAction)cancelTapped:(UIBarButtonItem *)sender {
    [self.delegate loginViewControllerDidCancel:self];
}

- (IBAction)loginTapped:(id)sender {
    if (![self.usernameField.text length] || ![self.passwordField.text length]) {
        [self loginFailed:@"Please enter your username (or email address) and password."];
        return;
    }

    [LoginViewController sendEventWithCategory:kAnalyticsCategoryLogin
                                      withAction:kAnalyticsLoginWithEmail
                                       withLabel:nil];

    [self viewEnabled:NO];
    self.loginButton.enabled = NO;

    [self.delegate loginViewController:self loginWithUsername:self.usernameField.text password:self.passwordField.text];
}

- (IBAction)loginWithFacebook:(id)sender
{
    [LoginViewController sendEventWithCategory:kAnalyticsCategoryLogin
                                    withAction:kAnalyticsLoginWithFacebook
                                     withLabel:nil];

    [self viewEnabled:NO];
    [self.delegate loginWithFacebook:self];
}

- (IBAction)signupTapped:(id)sender {
    [self.delegate loginViewControllerWantsSignup:self];
}

- (IBAction)forgotPasswordTapped:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:kShelbyForgotPasswordURL]];
}

- (void)loginFailed:(NSString *)errorMessage
{
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Login Error"
                                                            message:errorMessage
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil, nil];
        [alertView show];
        [self viewEnabled:YES];
    });
}

#pragma mark - UIAlertViewDelegate Methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    self.loginButton.enabled = YES;
    
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

#pragma mark - Keyboard Notification Handlers

- (void)keyboardWillShow:(NSNotification *)note
{
    if (kShelbyFullscreenHeight <= 480) {
        NSDictionary *info = note.userInfo;
        double animationDuration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];

        [UIView animateWithDuration:animationDuration animations:^{
            self.view.center = CGPointMake(self.view.center.x, self.view.center.y - 100);
        }];
    }
}

- (void)keyboardWillHide:(NSNotification *)note
{
    if (kShelbyFullscreenHeight <= 480) {
        NSDictionary *info = note.userInfo;
        double animationDuration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];

        [UIView animateWithDuration:animationDuration animations:^{
            self.view.center = CGPointMake(self.view.center.x, self.view.center.y + 100);
        }];
    }
}

@end
