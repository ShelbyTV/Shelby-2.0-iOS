//
//  SignupFlowNavigationViewController.m
//  Shelby.tv
//
//  Created by Keren on 7/8/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "SignupFlowNavigationViewController.h"

@interface SignupFlowNavigationViewController ()
@property (nonatomic, strong) NSMutableDictionary *signupDictionary;
@end


@implementation SignupFlowNavigationViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}



- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Create an empty Signup Dictionary
    self.signupDictionary = [@{} mutableCopy];
    
    // Pass the dictionary to the SignupFlowVC
    SignupFlowViewController *rootVC = (SignupFlowViewController *)self.viewControllers[0];
    rootVC.signupDictionary = self.signupDictionary;

    //NB: see AppDelegate for appearance proxy setup
    self.navigationBar.translucent = YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

-(BOOL) shouldAutorotate {
    return YES;
}

#pragma mark - SignupFlowViewDelegate
- (void)connectToFacebook
{
    [self.signupDelegate connectToFacebook];
}

- (void)connectToTwitter
{
    [self.signupDelegate connectToTwitter];
}

- (void)signupUser
{
    NSString *name = self.signupDictionary[kShelbySignupNameKey];
    NSString *email = self.signupDictionary[kShelbySignupEmailKey];
    if (name && email) {
        [self.signupDelegate signupUserWithName:name andEmail:email];
    }
}

- (void)completeSignup
{
    NSString *email = self.signupDictionary[kShelbySignupEmailKey];
    NSString *username = self.signupDictionary[kShelbySignupUsernameKey];
    NSString *password = self.signupDictionary[kShelbySignupPasswordKey];
    
    [self.signupDelegate completeSignupUserWithUsername:username password:password email:email andAvatar:nil];
}

@end
