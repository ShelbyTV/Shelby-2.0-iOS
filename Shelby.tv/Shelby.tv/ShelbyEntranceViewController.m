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
@property (weak, nonatomic) IBOutlet UIButton *getStartedButton;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;

@end

@implementation ShelbyEntranceViewController {
    UIAlertView *_alertView;
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
    self.loginButton.backgroundColor = kShelbyColorAirPlayBlue;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userSignupDidSucceed:) name:kShelbyNotificationUserSignupDidSucceed object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userSignupDidFail:) name:kShelbyNotificationUserSignupDidFail object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [self setButtonsEnabled:YES];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

#pragma mark - Target-Action

- (IBAction)getStartedTapped:(id)sender {
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
}

@end
