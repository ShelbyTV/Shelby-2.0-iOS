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

    //Hey KP KP, you should uncomment the following line, then adjust the views to take their new height into account
    //it looks hot.  -DJS
//    self.navigationBar.translucent = YES;
    //NB: see AppDelegate for appearance proxy setup
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
    NSString *username = self.signupDictionary[kShelbySignupUsernameKey];
    NSString *password = self.signupDictionary[kShelbySignupPasswordKey];
    if (username && password) {
        [self.signupDelegate completeSignupUserWithUsername:username andPassword:password];
    }
}

@end
