//
//  SignupFlowFirstStepViewController.m
//  Shelby.tv
//
//  Created by Keren on 7/16/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "SignupFlowStepOneViewController.h"
#import "ShelbyDataMediator.h"

#define kShelbySignupFlowViewYOffsetEditMode  (kShelbyFullscreenHeight > 480) ? -100 : -200

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
	// Do any additional setup after loading the view.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    [super prepareForSegue:segue sender:sender];
    
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
        [parent performSelector:@selector(signupUser)];
    }
    
    UIActivityIndicatorView *activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [activity startAnimating];
    activity.frame = CGRectMake(10, 10, 50, 44);
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:activity];
    
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

- (void)animateOpenEditing
{
    //move up so user can see our text fields
    [UIView animateWithDuration:0.2 animations:^{
        self.view.frame = CGRectMake(0, kShelbySignupFlowViewYOffsetEditMode, self.view.frame.size.width, self.view.frame.size.height);
    }];
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
