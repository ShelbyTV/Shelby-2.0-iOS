//
//  WelcomeViewController.m
//  Shelby.tv
//
//  Created by Daniel Spinosa on 8/28/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "WelcomeViewController.h"
#import "WelcomeLoginView.h"

NSString * const kShelbyWelcomeStatusKey = @"welcome_status";

@interface WelcomeViewController ()
@property (nonatomic, strong) WelcomeLoginView *welcomeLoginView;
@end

@implementation WelcomeViewController {
    NSDate *_viewLoadedAt;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        //init
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [WelcomeViewController sendEventWithCategory:kAnalyticsCategoryWelcome
                                      withAction:kAnalyticsWelcomeStart
                                       withLabel:nil];
    
    _viewLoadedAt = [NSDate date];

    //just the simple login/signup/preview view
    self.welcomeLoginView = [[NSBundle mainBundle] loadNibNamed:@"WelcomeLoginView" owner:self options:nil][0];
    self.welcomeLoginView.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
    [self.view addSubview:self.welcomeLoginView];
    self.welcomeLoginView.runBackgroundAnimation = YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (BOOL)shouldAutorotate
{
    return NO;
}

+ (BOOL)isWelcomeComplete
{
    return [[NSUserDefaults standardUserDefaults] integerForKey:kShelbyWelcomeStatusKey] == ShelbyWelcomeStatusComplete;
}

// This is called from the delegate and not from the welcomeComplete method.
// That is because we want to reset Signup Started values, if user:
// Go thru welcome, hit signup, kill the app
// Open the app, go thru welcome again and now hit Preview app.
// We want to make sure that next time they don't get welcome reset.
+ (void)setWelcomeScreenComplete:(ShelbyWelcomeStatus)welcomeStatus
{
    [[NSUserDefaults standardUserDefaults] setInteger:welcomeStatus forKey:kShelbyWelcomeStatusKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - WelcomeLoginView's IBActions

- (IBAction)signupWithFacebookTapped:(id)sender
{
    [WelcomeViewController sendEventWithCategory:kAnalyticsCategoryWelcome
                                      withAction:kAnalyticsWelcomeTapSignupWithFacebook
                                       withLabel:[self welcomeDuration]];

    [self welcomeComplete];
    [self.delegate welcomeDidTapSignupWithFacebook:self];
}

- (IBAction)createAccountTapped:(id)sender {
    [WelcomeViewController sendEventWithCategory:kAnalyticsCategoryWelcome
                                      withAction:kAnalyticsWelcomeTapSignup
                                       withLabel:[self welcomeDuration]];
    [self welcomeComplete];
    [self.delegate welcomeDidTapSignup:self];
}

- (IBAction)loginTapped:(id)sender {
    [WelcomeViewController sendEventWithCategory:kAnalyticsCategoryWelcome
                                      withAction:kAnalyticsWelcomeTapLogin
                                       withLabel:[self welcomeDuration]];
    [self welcomeComplete];
    [self.delegate welcomeDidTapLogin:self];
}

- (IBAction)previewTapped:(id)sender {
    [WelcomeViewController sendEventWithCategory:kAnalyticsCategoryWelcome
                                      withAction:kAnalyticsWelcomeTapPreview
                                       withLabel:[self welcomeDuration]];
    [ShelbyAnalyticsClient sendLocalyticsEvent:kLocalyticsDidPreview];
    [self welcomeComplete];
    [self.delegate welcomeDidTapPreview:self];
}

#pragma mark - Helpers

- (void)welcomeComplete
{
    [WelcomeViewController sendEventWithCategory:kAnalyticsCategoryWelcome
                                      withAction:kAnalyticsWelcomeFinish
                                       withLabel:[self welcomeDuration]];
}

- (NSString *)welcomeDuration
{
    return [NSString stringWithFormat:@"%f", -[_viewLoadedAt timeIntervalSinceNow]];
}

@end
