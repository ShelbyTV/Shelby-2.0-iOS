//
//  SignupFlowFirstStepViewController.m
//  Shelby.tv
//
//  Created by Keren on 7/16/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "SignupFlowFirstStepViewController.h"

#define kShelbySignupFlowViewYOffsetEditMode  (kShelbyFullscreenHeight > 480) ? -100 : -200

@interface SignupFlowFirstStepViewController ()
- (IBAction)unwindSegueToStepOne:(UIStoryboardSegue *)segue;
@end

@implementation SignupFlowFirstStepViewController

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

#pragma mark - UITextFieldDelegate Methods
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    //move up so user can see our text fields
    [UIView animateWithDuration:0.2 animations:^{
        self.view.frame = CGRectMake(0, kShelbySignupFlowViewYOffsetEditMode, self.view.frame.size.width, self.view.frame.size.height);
    }];
    return YES;
}

@end
