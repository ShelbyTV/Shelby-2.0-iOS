//
//  SignupFlowFirstStepViewController.m
//  Shelby.tv
//
//  Created by Keren on 7/16/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "SignupFlowStepOneViewController.h"
#import "ShelbyDataMediator.h"


@interface SignupFlowStepOneViewController ()
- (IBAction)unwindSegueToStepOne:(UIStoryboardSegue *)segue;

// Segue
- (IBAction)gotoChooseVideoTypes:(id)sender;
@end

@implementation SignupFlowStepOneViewController

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

    self.nextButton.enabled = NO;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // TODO: decide the length of username & password that are acceptable
    if ([self.nameField.text length] && [self.email.text length]) {
        self.nextButton.enabled = YES;
    }
    
    self.nameField.text = self.fullname;
    self.email.text = self.signupDictionary[kShelbySignupEmailKey];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    [super prepareForSegue:segue sender:sender];
    
    self.navigationItem.rightBarButtonItem = self.nextButton;
    [self removeObservers];
}

- (void)removeObservers
{
    [[NSNotificationCenter defaultCenter] removeObserver:kShelbyNotificationUserSignupDidSucceed];
    [[NSNotificationCenter defaultCenter] removeObserver:kShelbyNotificationUserSignupDidFail];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)unwindSegueToStepOne:(UIStoryboardSegue *)segue
{
    // Nothing here
}

- (NSString *)signupStepNumber
{
    return @"1";
}

- (NSInteger)yOffsetForEditMode
{
    return (kShelbyFullscreenHeight > 480) ? -100 : -200;
}

- (UIView *)customLeftButtonView
{
    UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    backButton.frame = CGRectMake(0.0f, 0.0f, 80.0f, 44.0f);
    [backButton setTitleColor:[UIColor colorWithHex:@"888888" andAlpha:1] forState:UIControlStateNormal];
    [backButton setTitle:self.navigationItem.leftBarButtonItem.title forState:UIControlStateNormal];
    [backButton addTarget:self action:self.navigationItem.leftBarButtonItem.action forControlEvents:UIControlEventTouchUpInside];
    
    return backButton;
}


- (void)resignActiveKeyboard:(UITextField *)textField
{
    //move back down
    [UIView animateWithDuration:0.2 animations:^{
        self.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    }];
}

- (IBAction)gotoChooseVideoTypes:(id)sender
{
    [self saveValueAndResignActiveTextField];
    
    if (!self.avatarImage) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Add Your Picture" message:@"Don't be anonymous, let other people see your picture" delegate:self cancelButtonTitle:@"Not Now" otherButtonTitles:@"Choose", nil];
        [alertView show];
    } else {
        [self signupUser];
    }
}

- (void)signupUser
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(userSignupDidSucceed:)
                                                 name:kShelbyNotificationUserSignupDidSucceed object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(userSignupDidFail:)
                                                 name:kShelbyNotificationUserSignupDidFail object:nil];

    UIViewController *parent = self.parentViewController;
    if ([parent conformsToProtocol:@protocol(SignupFlowViewDelegate)]) {
        // Change Right Button with Activity Indicator
        UIActivityIndicatorView *activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [activity startAnimating];
        activity.frame = CGRectMake(10, 10, 50, 44);
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:activity];
 
        [parent performSelector:@selector(signupUser)];
    }
}

- (void)userSignupDidFail:(NSNotification *)notification
{
    NSString *errorMessage = [notification object];
    if (!errorMessage || ![errorMessage isKindOfClass:[NSString class]] || [errorMessage isEqualToString:@""]) {
        errorMessage = @"There was a problem. Please try again later.";
    }
    
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:errorMessage
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil, nil];
    [alertView show];
    
    self.navigationItem.rightBarButtonItem = self.nextButton;
    [self removeObservers];
    
}

- (void)userSignupDidSucceed:(NSNotification *)notification
{
    [self performSegueWithIdentifier:@"ChooseVideos" sender:self];
    self.navigationItem.rightBarButtonItem = self.nextButton;

    [self removeObservers];
}

#pragma mark - UIAlertViewDialog Methods
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        [self signupUser];
    } else {
        [self assignAvatar];
    }
}
@end
