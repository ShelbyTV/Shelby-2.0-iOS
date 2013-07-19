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
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic, weak) IBOutlet UILabel *activityLabel;
@property (nonatomic, weak) IBOutlet BlinkingLabel *blinkingLabel;
@property (nonatomic, weak) IBOutlet UILabel *emailLabel;
@property (nonatomic, weak) IBOutlet UIView *backgroundViewForUserInfo;

- (IBAction)signup:(id)sender;

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
    self.backgroundViewForUserInfo.layer.cornerRadius = 5;
    self.backgroundViewForUserInfo.layer.masksToBounds = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.password.text = self.signupDictionary[kShelbySignupPasswordKey];
    self.username.text = self.signupDictionary[kShelbySignupUsernameKey];
    self.emailLabel.text = self.signupDictionary[kShelbySignupEmailKey];

    if ([self.selectedCellsTitlesArray count] > 0) {
        [self.blinkingLabel setupWords:self.selectedCellsTitlesArray andBlinkingTime:5.0 withCompletionText:@"VIDEOS ADDED!" andBlock:^(BOOL done) {
            if (YES) {
                self.activityIndicator.hidden = YES;
                self.activityLabel.hidden = YES;
                self.blinkingLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:14];
                
            }
        }];
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

- (CGRect)nextButtonFrame
{
    return CGRectMake(0.0f, 0.0f, 140.0f, 44.0f);
}

- (IBAction)signup:(id)sender
{
    [self saveValueAndResignActiveTextField];
    
    UIViewController *parent = self.parentViewController;
    if ([parent conformsToProtocol:@protocol(SignupFlowViewDelegate)]) {
        [parent performSelector:@selector(completeSignup)];
    }
    
    // TODO: send avatar & video types
    // TODO: wait for ERRORS from backend
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end