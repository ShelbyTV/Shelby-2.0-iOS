//
//  SignupFlowNavigationViewController.m
//  Shelby.tv
//
//  Created by Keren on 7/8/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "SignupFlowNavigationViewController.h"
#import "DeviceUtilities.h"
#import "SignupFlowStepOneViewController.h"
#import "GAI.h"

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
    [[GAI sharedInstance].defaultTracker sendEventWithCategory:kAnalyticsCategorySignup
                                                    withAction:kAnalyticsSignupStart
                                                     withLabel:nil
                                                     withValue:nil];
    
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

- (void)startWithFacebookSignup
{
    SignupFlowStepOneViewController *stepOne = (SignupFlowStepOneViewController *)self.viewControllers[0];
    STVAssert([stepOne isKindOfClass:[SignupFlowStepOneViewController class]], @"First signup controller must be step one.");
    [stepOne startWithFacebookSignup];
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
    [[GAI sharedInstance].defaultTracker sendEventWithCategory:kAnalyticsCategorySignup
                                                    withAction:kAnalyticsSignupFinish
                                                     withLabel:nil
                                                     withValue:nil];
    
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

@end
