//
//  SignupFlowStepFourViewController.m
//  Shelby.tv
//
//  Created by Keren on 7/17/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "SignupFlowStepFourViewController.h"
#import "BlinkingLabel.h"

@interface SignupFlowStepFourViewController ()
@property (weak, nonatomic) IBOutlet BlinkingLabel *blinkingLabel;
@property (nonatomic, weak) IBOutlet UILabel *emailLabel;
@end

@implementation SignupFlowStepFourViewController

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
    
    self.password.text = self.signupDictionary[kShelbySignupPasswordKey];
    self.username.text = self.signupDictionary[kShelbySignupUsernameKey];
    self.emailLabel.text = self.signupDictionary[kShelbySignupEmailKey];

    if ([self.selectedCellsTitlesArray count] > 0) {
        [self.blinkingLabel setWords:self.selectedCellsTitlesArray];
    }
    
    if ([self.username.text length] && [self.password.text length]) {
        self.nextButton.enabled = YES;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSString *)signupStepNumber
{
    return @"4";
}

- (NSInteger)yOffsetForEditMode
{
    return (kShelbyFullscreenHeight > 480) ? -100 : -175;
}

@end
