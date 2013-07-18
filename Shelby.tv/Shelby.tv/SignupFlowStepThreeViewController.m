//
//  SignupFlowStepThreeViewController.m
//  Shelby.tv
//
//  Created by Keren on 7/17/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "SignupFlowStepThreeViewController.h"
#import "ShelbyDataMediator.h"

@interface SignupFlowStepThreeViewController ()
@property (nonatomic, weak) IBOutlet UIButton *facebookButton;
@property (nonatomic, weak) IBOutlet UIButton *twitterButton;

// Social Actions
- (IBAction)connectoToFacebook:(id)sender;
- (IBAction)connectoToTwitter:(id)sender;

// Segue
- (IBAction)gotoMyAccount:(id)sender;

@end

@implementation SignupFlowStepThreeViewController

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

    if (self.facebookButton) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshSocialButtons) name:kShelbyNotificationTwitterConnectCompleted object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshSocialButtons) name:kShelbyNotificationFacebookConnectCompleted object:nil];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self refreshSocialButtons];
}

- (void)refreshSocialButtons
{
    // We might come from a background thread - so make sure we switch to main thread.
    dispatch_async(dispatch_get_main_queue(), ^{
        User *user = [[ShelbyDataMediator sharedInstance] fetchAuthenticatedUserOnMainThreadContext];
        if (user.facebookUID) {
            self.facebookButton.enabled = NO;
        }
        if (user.twitterNickname) {
            self.twitterButton.enabled = NO;
        }
    });
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSString *)signupStepNumber
{
    return @"3";
}

// KP KP: TODO: commenting out because need to make sure user has an account - after we implement that, uncomemnt
- (IBAction)connectoToFacebook:(id)sender
{
    UIViewController *parent = self.parentViewController;
    if ([parent conformsToProtocol:@protocol(SignupFlowViewDelegate)]) {
        [parent performSelector:@selector(connectToFacebook)];
    }
}

// KP KP: TODO: commenting out because need to make sure user has an account - after we implement that, uncomemnt
- (IBAction)connectoToTwitter:(id)sender
{
    UIViewController *parent = self.parentViewController;
    if ([parent conformsToProtocol:@protocol(SignupFlowViewDelegate)]) {
        [parent performSelector:@selector(connectToTwitter)];
    }
}

- (IBAction)gotoMyAccount:(id)sender
{
    [self performSegueWithIdentifier:@"MyAccount" sender:self];
}

@end
