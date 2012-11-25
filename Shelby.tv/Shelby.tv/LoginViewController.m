//
//  LoginViewController.m
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 10/19/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

#import "LoginViewController.h"

@interface LoginViewController ()

@end

@implementation LoginViewController
@synthesize emailField = _emailField;
@synthesize passwordField = _passwordField;
@synthesize loginButton = _loginButton;

#pragma mark - Memory Management
- (void)dealloc
{
    self.emailField = nil;
    self.passwordField = nil;
    self.loginButton = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

#pragma mark - Action Methods
- (void)loginButtonAction:(id)sender
{
    
    if ( self.emailField.isFirstResponder ) [self.emailField resignFirstResponder];
    if ( self.passwordField.isFirstResponder ) [self.passwordField resignFirstResponder];
    
    if ( ![self.emailField text] || ![self.passwordField text] ) {
        
    } else {
        
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:kAPIShelbyPostAuthorizeEmail, self.emailField.text, self.passwordField.text]];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        [request setHTTPMethod:@"POST"];
        
        AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {

            CoreDataUtility *utility = [[CoreDataUtility alloc] initWithRequestType:APIRequestType_PostAuthorization];
            [utility storeUser:JSON];
            
//            [[NSUserDefaults standardUserDefaults] setObject:[kJSONDataReceived valueForKey:@"authentication_token"] forKey:kStoredShelbyAuthToken];
//            [self dismissModalViewControllerAnimated:YES];
            
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
            
            NSLog(@"%@", error);
            
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Login Error"
                                                                message:@"Please try again"
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil, nil];
            [alertView show];
            
        }];
        
        [operation start];
        
    }
    
}

#pragma mark - UITextFieldDelegate Methods
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if ( [string isEqualToString:@"\n"] ) {
        
        [textField resignFirstResponder];
        return NO;
    
    }
        return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if ( textField == self.emailField ) {
        [self.passwordField becomeFirstResponder];
        return NO;
    } else {
        [self loginButtonAction:nil];
        return YES;
    }
}

#pragma mark - UIResponder Methods
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if ( [self.emailField isFirstResponder] ) [self.emailField resignFirstResponder];
    if ( [self.passwordField isFirstResponder] ) [self.passwordField resignFirstResponder];
}

@end