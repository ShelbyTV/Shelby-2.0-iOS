//
//  SignupFlowNavigationViewController.m
//  Shelby.tv
//
//  Created by Keren on 7/8/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "SignupFlowNavigationViewController.h"
#import "DeviceUtilities.h"
#import "ShelbyAnalyticsClient.h"

@interface SignupFlowNavigationViewController ()
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
    [ShelbyAnalyticsClient sendEventWithCategory:kAnalyticsCategorySignup action:kAnalyticsSignupStart label:nil];
    [ShelbyAnalyticsClient sendLocalyticsEvent:kLocalyticsStartSignup];
    
    // Create an empty Signup Dictionary
    self.signupDictionary = [@{} mutableCopy];
    
    // Pass the dictionary to the SignupFlowVC
    SignupFlowViewController *rootVC = (SignupFlowViewController *)self.viewControllers[0];
    rootVC.signupDictionary = self.signupDictionary;

    //NB: see AppDelegate for appearance proxy setup
    if ([DeviceUtilities isGTEiOS7]) {
        self.navigationBar.translucent = YES;
    } else {
        self.navigationBar.translucent = NO;
        self.navigationBar.barStyle = UIBarStyleBlackOpaque;
    }
}

- (void)handleDidBecomeActive
{
    SignupFlowViewController *signupVC = (SignupFlowViewController *)[self topViewController];
    [signupVC handleDidBecomeActive];
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

- (void)signupWithFacebook
{
    [self.signupDelegate signupWithFacebook];
}

- (void)signupUser
{
    NSString *name = self.signupDictionary[kShelbySignupNameKey];
    NSString *email = self.signupDictionary[kShelbySignupEmailKey];
    if (name && email) {
        [self.signupDelegate createUserWithName:name andEmail:email];
    }
}

- (void)updateSignupUser
{
    NSString *name = self.signupDictionary[kShelbySignupNameKey];
    NSString *email = self.signupDictionary[kShelbySignupEmailKey];
    if (name && email) {
        [self.signupDelegate updateSignupUserWithName:name email:email];
    }    
}

- (void)completeSignup
{
    SignupFlowViewController *rootVC = (SignupFlowViewController *)self.topViewController;
    self.signupDictionary = rootVC.signupDictionary;
    
    [ShelbyAnalyticsClient sendEventWithCategory:kAnalyticsCategorySignup action:kAnalyticsSignupFinish label:nil];
    [ShelbyAnalyticsClient sendLocalyticsEvent:kLocalyticsFinishSignup];
    
    NSString *name = self.signupDictionary[kShelbySignupNameKey];
    NSString *email = self.signupDictionary[kShelbySignupEmailKey];
    NSString *username = self.signupDictionary[kShelbySignupUsernameKey];
    NSString *password = self.signupDictionary[kShelbySignupPasswordKey];
    UIImage *avatar = self.signupDictionary[kShelbySignupAvatarKey];
 
    NSArray *rollsInfo = self.signupDictionary[kShelbySignupVideoTypesKey];
    NSMutableArray *rollsToFollow = [@[] mutableCopy];
    for (NSDictionary *rollInfo in rollsInfo) {
        [rollsToFollow addObject:rollInfo[@"rollID"]];
    }
    
    [self.signupDelegate completeSignupUserWithName:name username:username password:password email:email avatar:avatar andRolls:rollsToFollow];
}

- (void)wantsLogin
{
    [self.signupDelegate signupFlowNavigationViewControllerWantsLogin:self];
}

- (void)setSignupDelegate:(id<SignupFlowNavigationViewDelegate>)signupDelegate
{
    _signupDelegate = signupDelegate;
    
    // Making sure we don't have a delegate without a valid signupDictionary
    if (!self.signupDictionary) {
        self.signupDictionary = [@{} mutableCopy];
    }
}

@end
