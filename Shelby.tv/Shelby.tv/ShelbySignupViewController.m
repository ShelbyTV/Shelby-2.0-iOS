//
//  ShelbySignupViewController.m
//  Shelby.tv
//
//  Created by Keren on 1/21/14.
//  Copyright (c) 2014 Shelby TV, Inc. All rights reserved.
//

#import "ShelbySignupViewController.h"

@interface ShelbySignupViewController ()
@property (nonatomic, weak) IBOutlet UIView *stepOneView;
@property (nonatomic, weak) IBOutlet UITextField *stepOneName;
@property (nonatomic, weak) IBOutlet UITextField *stepOneEmail;
@property (nonatomic, weak) IBOutlet UITextField *stepOnePassword;
@property (nonatomic, weak) IBOutlet UIButton *stepOneSignUpWithFacebook;
@property (nonatomic, weak) IBOutlet UIButton *stepOneSignUpWithEmail;

@property (nonatomic, weak) IBOutlet UIView *stepTwoView;
@property (nonatomic, weak) IBOutlet UITextField *stepTwoUsername;
@property (nonatomic, weak) IBOutlet UITextField *stepTwoName;
@property (nonatomic, weak) IBOutlet UITextField *stepTwoEmail;
@property (nonatomic, weak) IBOutlet UITextField *stepTwoPassword;
@property (nonatomic, weak) IBOutlet UIButton *stepTwoSaveProfile;

- (IBAction)signupWithFacebook:(id)sender;
- (IBAction)signupWithEmail:(id)sender;
- (IBAction)saveProfile:(id)sender;
@end

@implementation ShelbySignupViewController

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

- (IBAction)signupWithFacebook:(id)sender
{
    
}

- (IBAction)signupWithEmail:(id)sender
{
    
}

- (IBAction)saveProfile:(id)sender
{
    
}

@end
