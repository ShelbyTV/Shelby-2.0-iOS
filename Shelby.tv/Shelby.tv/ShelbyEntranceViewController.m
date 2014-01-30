//
//  ShelbyEntranceViewController.m
//  Shelby.tv
//
//  Created by Dan Spinosa on 1/22/14.
//  Copyright (c) 2014 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyEntranceViewController.h"
#import "ShelbyDataMediator.h"

@interface ShelbyEntranceViewController ()
@property (weak, nonatomic) IBOutlet UIView *logo;
@property (weak, nonatomic) IBOutlet UIButton *getStartedButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *getStartedSpinner;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@end

@implementation ShelbyEntranceViewController {
    UIAlertView *_alertView;
    CGPoint _logoOffscreenCenter, _logoFinalCenter,
            _getStartedButtonOffscreenCenter, _getStartedButtonFinalCenter,
            _loginButtonOffscreenCenter, _loginButtonFinalCenter;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.getStartedButton.backgroundColor = kShelbyColorGreen;
    self.getStartedButton.layer.cornerRadius = 5.f;
    self.loginButton.backgroundColor = kShelbyColorBlue;
    self.loginButton.layer.cornerRadius = 5.f;
    
    //animation before/after positions
    _logoFinalCenter = self.logo.center;
    _logoOffscreenCenter = CGPointMake(_logoFinalCenter.x, -500);
    _getStartedButtonFinalCenter = self.getStartedButton.center;
    _getStartedButtonOffscreenCenter = CGPointMake(_getStartedButtonFinalCenter.x, 1200);
    _loginButtonFinalCenter = self.loginButton.center;
    _loginButtonOffscreenCenter = CGPointMake(_loginButtonFinalCenter.x, 1000);
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userSignupDidSucceed:) name:kShelbyNotificationUserSignupDidSucceed object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userSignupDidFail:) name:kShelbyNotificationUserSignupDidFail object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self setButtonsEnabled:YES];
    
    self.logo.center = _logoOffscreenCenter;
    self.getStartedButton.center = _getStartedButtonOffscreenCenter;
    self.loginButton.center = _loginButtonOffscreenCenter;
    
    [UIView animateWithDuration:1.0 delay:0 usingSpringWithDamping:.8 initialSpringVelocity:8.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.logo.center = _logoFinalCenter;
        self.getStartedButton.center = _getStartedButtonFinalCenter;
        self.loginButton.center = _loginButtonFinalCenter;
    } completion:^(BOOL finished) {
        //nothing to do just yet... maybe kick off some continuing animations?
    }];
}

- (void)animateDisappearanceWithCompletion:(void (^)())completion
{
    [UIView animateWithDuration:1.0 delay:0 usingSpringWithDamping:.8 initialSpringVelocity:8.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        [self.getStartedSpinner stopAnimating];
        self.logo.center = _logoOffscreenCenter;
        self.getStartedButton.center = _getStartedButtonOffscreenCenter;
        self.loginButton.center = _loginButtonOffscreenCenter;
    } completion:^(BOOL finished) {
        if (completion) {
            completion();
        }
    }];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

#pragma mark - Target-Action

- (IBAction)getStartedTapped:(id)sender {
    [self.getStartedSpinner startAnimating];
    [self setButtonsEnabled:NO];
    [[ShelbyDataMediator sharedInstance] createAnonymousUser];
    //result via notifications, registered above
}

- (IBAction)loginTapped:(id)sender {
    [self.brain presentUserLogin];
}

#pragma mark - Notifications

- (void)userSignupDidSucceed:(NSNotification *)notification
{
    User *anonUser = [[ShelbyDataMediator sharedInstance] fetchAuthenticatedUserOnMainThreadContextWithForceRefresh:NO];
    [self.brain proceedWithAnonymousUser:anonUser];
}

- (void)userSignupDidFail:(NSNotification *)notification
{
    _alertView = [[UIAlertView alloc] initWithTitle:@"Couldn't Get Started" message:@"Please try again in a minute.  Sorry." delegate:nil cancelButtonTitle:@"ok" otherButtonTitles:nil];
    [_alertView show];
    
    double delayInSeconds = 5.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self setButtonsEnabled:YES];
    });
}

#pragma mark - Helpers

- (void)setButtonsEnabled:(BOOL)enabled
{
    self.getStartedButton.enabled = enabled;
    self.loginButton.enabled = enabled;
    if (enabled) {
        [self.getStartedSpinner stopAnimating];
    }
}

@end
