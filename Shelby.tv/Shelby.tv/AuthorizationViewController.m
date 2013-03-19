//
//  AuthorizationViewController.m
//  Shelby.tv
//
//  Created by Keren on 3/13/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

#import "AuthorizationViewController.h"
#import <QuartzCore/QuartzCore.h>

#import "LoginView.h"
#import "SignupView.h"
#import "ImageUtilities.h"
#import "ShelbyAPIClient.h"
#import <QuartzCore/QuartzCore.h>

@interface AuthorizationViewController ()

@property (weak, nonatomic) IBOutlet LoginView *loginView;
@property (weak, nonatomic) IBOutlet SignupView *signupView;

// Keep track on what form is currently in use: login or signup.
@property (weak, nonatomic) id currentForm;

- (IBAction)login:(id)sender;
- (IBAction)openSignup:(id)sender;
- (IBAction)signup:(id)sender;
- (IBAction)cancel:(id)sender;

@end

@implementation AuthorizationViewController

#pragma mark - View Lifecycle Methods
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setTrackedViewName:@"Login / Sign Up"];
    [self setCurrentForm:self.loginView];
    
    self.view.layer.cornerRadius = 5;
    self.view.layer.borderColor = [UIColor blackColor].CGColor;
    self.view.layer.borderWidth = 1;
    self.view.clipsToBounds = YES;
}


- (void)setCurrentForm:(id)currentForm
{
    _currentForm = currentForm;
    
    [self.currentForm resetForm];
}

#pragma mark - User Authentication Methods (Private)
- (IBAction)login:(id)sender
{
    [self performAuthentication];
}


- (IBAction)openSignup:(id)sender
{
    
    float yDiff = (self.signupView.frame.size.height - self.loginView.frame.size.height);
    [self.signupView setAlpha:0];
    [self.view bringSubviewToFront:self.signupView];
    [self setCurrentForm:self.signupView];

    [UIView animateWithDuration:0.3 animations:^{
        [self.view.superview setFrame:CGRectMake(self.view.superview.frame.origin.x - yDiff,
                                                 self.view.superview.frame.origin.y   ,
                                                 self.view.superview.frame.size.width + yDiff,
                                                 self.view.superview.frame.size.height )];
        [self.signupView setFrame:CGRectMake(0, 0, self.signupView.frame.size.width, self.signupView.frame.size.height)];
        [self.loginView setAlpha:0];
        [self.signupView setAlpha:1];
    }];
}


- (IBAction)signup:(id)sender
{
    if (![self.currentForm validateFields]) {
        return;
    }

    [self.currentForm processingForm];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(userAuthenticationDidSucceed:)
                                                 name:kShelbyNotificationUserSignupDidSucceed object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(userAuthenticationDidFail:)
                                                 name:kShelbyNotificationUserSignupDidFail object:nil];
    
    
    [ShelbyAPIClient postSignupWithName:self.signupView.fullname.text nickname:self.signupView.username.text password:self.signupView.passwordField.text andEmail:self.signupView.emailField.text];
}


- (IBAction)cancel:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (void)performAuthentication
{
    if ([self.currentForm validateFields]) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(userAuthenticationDidSucceed:)
                                                     name:kShelbyNotificationUserAuthenticationDidSucceed object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(userAuthenticationDidFail:)
                                                     name:kShelbyNotificationUserAuthenticationDidFail object:nil];
        
        [self.currentForm processingForm];
        
        [ShelbyAPIClient postAuthenticationWithEmail:[self.loginView.emailField.text lowercaseString] andPassword:self.loginView.passwordField.text];
    }
}


- (void)userAuthenticationDidFail:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    
    if ([notification isKindOfClass:[NSNotification class]]) {
        id JSONError = [notification object];
        NSString *errorMessage = nil;
        NSDictionary *userErrorDictionary = nil;
        if ([JSONError isKindOfClass:[NSDictionary class]]) {
            errorMessage = JSONError[@"message"];
        
            NSDictionary *errors = JSONError[@"errors"];
            if (errors && [errors isKindOfClass:[NSDictionary class]]) {
                userErrorDictionary = errors[@"user"];
                if (![userErrorDictionary isKindOfClass:[NSDictionary class]]) {
                    userErrorDictionary = nil;
                }
            }
        } else if ([JSONError isKindOfClass:[NSString class]]) {
            errorMessage = JSONError;
            
        }

        [self.currentForm showErrors:userErrorDictionary];
        
        if (!errorMessage || ![errorMessage isKindOfClass:[NSString class]] || [errorMessage isEqualToString:@""]) {
            errorMessage = @"There was a problem. Please try again later.";
        }

        if ([errorMessage isKindOfClass:[NSString class]]) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                message:errorMessage
                                                               delegate:self
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil, nil];
            [alertView show];
        }
    }
}

- (void)userAuthenticationDidSucceed:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(authorizationDidComplete)]) {
        [self.delegate authorizationDidComplete];
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - UITextFieldDelegate Methods
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if ([string isEqualToString:@"\n"]) {
        [self.currentForm selectNextField:textField];
        return NO;
    }
    
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if ([self.currentForm selectNextField:textField]) {
        if (![self.currentForm validateFields]) {
            return NO;
        }
    } else {
        return NO;
    }
    
    
    if (self.currentForm == self.loginView) {
        [self performAuthentication];
    } else {
        [self signup:nil];
    }
    
    return YES;
}

#pragma mark - UIAlertViewDelegate Methods
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    [self.currentForm resetForm];
}

@end
