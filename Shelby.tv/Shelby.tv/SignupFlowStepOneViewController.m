//
//  SignupFlowStepOneViewController.m
//  Shelby.tv
//
//  Created by Keren on 7/16/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "SignupFlowStepOneViewController.h"
#import "ShelbyDataMediator.h"
#import "UIImageView+AFNetworking.h"


@interface SignupFlowStepOneViewController ()
- (IBAction)unwindSegueToStepOne:(UIStoryboardSegue *)segue;

- (IBAction)goBack:(id)sender;

- (IBAction)signupWithFacebook:(id)sender;

// Segue
- (IBAction)gotoChooseVideoTypes:(id)sender;

@property (weak, nonatomic) IBOutlet UIButton *signupWithFacebookButton;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *subtitleLabel;
@end

@implementation SignupFlowStepOneViewController

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

    self.titleLabel.font = kShelbyFontH2;
    self.subtitleLabel.font = kShelbyFontH4Medium;
    
    [self.signupWithFacebookButton setBackgroundImage:[[UIImage imageNamed:@"facebook-button-background"] resizableImageWithCapInsets:UIEdgeInsetsMake(2, 2, 2, 2)] forState:UIControlStateNormal];
    
    [SignupFlowViewController setSignupStatus:ShelbySignupStatusStarted];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // TODO: decide the length of username & password that are acceptable
    if ([self.nameField.text length] && [self.email.text length]) {
        self.nextButton.enabled = YES;
    }
    
    self.nameField.text = self.fullname;
    self.email.text = self.signupDictionary[kShelbySignupEmailKey];
}

- (void)handleDidBecomeActive
{
    [self viewEnabled:YES];
    
    self.navigationItem.rightBarButtonItem = self.nextButton;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    [super prepareForSegue:segue sender:sender];

    [SignupFlowViewController sendEventWithCategory:kAnalyticsCategorySignup
                                         withAction:kAnalyticsSignupStep1Complete
                                          withLabel:nil];

    SignupFlowViewController *stepTwo = [segue destinationViewController];
    stepTwo.facebookSignup = self.facebookSignup;
    
    self.navigationItem.rightBarButtonItem = self.nextButton;
}

- (void)addObserversForSignup:(BOOL)signupNotifications withEmail:(BOOL)withEmail
{
    if (signupNotifications) {
        if (withEmail) {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userSignupDidSucceed:) name:kShelbyNotificationUserSignupDidSucceed object:nil];
        } else {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(signupWithFacebookCompleted:) name:kShelbyNotificationUserSignupDidSucceed object:nil];
        }
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userSignupDidFail:) name:kShelbyNotificationUserSignupDidFail object:nil];
    } else {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userUpdateDidSucceed:) name:kShelbyNotificationUserUpdateDidSucceed object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userUpdateDidFail:) name:kShelbyNotificationUserUpdateDidFail object:nil];
    }
}

- (void)removeObserversForSignup:(BOOL)signupNotifications
{
    if (signupNotifications) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:kShelbyNotificationUserSignupDidSucceed object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:kShelbyNotificationUserSignupDidFail object:nil];
    } else {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:kShelbyNotificationUserUpdateDidSucceed object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:kShelbyNotificationUserUpdateDidFail object:nil];
    }
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)unwindSegueToStepOne:(UIStoryboardSegue *)segue
{
    // Nothing here
}

- (NSString *)signupStepNumber
{
    return @"1";
}

- (NSInteger)yOffsetForEditMode
{
    return -200;
}

- (UIView *)customLeftButtonView
{
    UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    backButton.frame = CGRectMake(0.0f, 0.0f, 80.0f, 44.0f);
    [backButton setTitleColor:kShelbyColorLightGray forState:UIControlStateNormal];
    [backButton setTitle:self.navigationItem.leftBarButtonItem.title forState:UIControlStateNormal];
    [backButton addTarget:self action:self.navigationItem.leftBarButtonItem.action forControlEvents:UIControlEventTouchUpInside];
    [backButton.titleLabel setFont:kShelbyFontH4Bold];
    
    return backButton;
}


- (void)resignActiveKeyboard:(UITextField *)textField
{
    //move back down
    [UIView animateWithDuration:0.2 animations:^{
        self.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    }];
}


- (void)signupWithFacebookCompletedSkipStepOne
{
    [SignupFlowViewController setSignupStatus:ShelbySignupStatusStarted];
    [ShelbyAnalyticsClient sendEventWithCategory:kAnalyticsCategorySignup
                                          action:kAnalyticsSignupWithFacebookInitialSuccess
                                           label:nil];
    
    self.facebookSignup = YES;
    [self cleanupAfterSignupWithFacebook];
}

- (void)startWithFacebookSignup
{
    [self signupWithFacebook:nil];
}

- (IBAction)goBack:(id)sender
{
    if ([[ShelbyDataMediator sharedInstance] fetchAuthenticatedUserOnMainThreadContext]) {
        //a user has been created, need to get rid of that bastard
        [[ShelbyDataMediator sharedInstance] logoutCurrentUser];
    }

    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)signupWithFacebook:(id)sender
{
    [self viewEnabled:NO];
    
    UIActivityIndicatorView *activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    [activity startAnimating];
    activity.frame = CGRectMake(10, 10, 50, 44);
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:activity];
    
    self.navigationItem.leftBarButtonItem.enabled = NO;

    [self addObserversForSignup:YES withEmail:NO];

    [ShelbyAnalyticsClient sendEventWithCategory:kAnalyticsCategorySignup
                                          action:kAnalyticsSignupWithFacebookStart
                                           label:nil];

    UIViewController *parent = self.parentViewController;
    if ([parent conformsToProtocol:@protocol(SignupFlowViewDelegate)]) {
        [parent performSelector:@selector(signupWithFacebook)];
    }
}

- (IBAction)loginTapped:(UIButton *)sender {
    [self viewEnabled:NO];
    
    //DS to KP: I'm not as familiar with iOS paradigms as you... why are we using parent like this, instead of explicity setting delegate?
    UIViewController *parent = self.parentViewController;
    if ([parent conformsToProtocol:@protocol(SignupFlowViewDelegate)]) {
        [(id<SignupFlowViewDelegate>)parent wantsLogin];
    };
}

- (IBAction)gotoChooseVideoTypes:(id)sender
{
    [self saveValueAndResignActiveTextField];
    
    if (!self.avatarImage) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Add Your Picture" message:@"Don't be anonymous, let other people see your picture" delegate:self cancelButtonTitle:@"Not Now" otherButtonTitles:@"Choose", nil];
        [alertView show];
    } else {
        [self startSignupUser];
    }
}

- (void)cleanupAfterSignupWithFacebook
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kShelbyNotificationUserSignupDidSucceed object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kShelbyNotificationUserSignupDidFail object:nil];
}
- (void)signupWithFacebookCompleted:(NSNotification *)notification
{
    [self cleanupAfterSignupWithFacebook];
    
    [ShelbyAnalyticsClient sendEventWithCategory:kAnalyticsCategorySignup
                                          action:kAnalyticsSignupWithFacebookInitialSuccess
                                           label:nil];

    dispatch_async(dispatch_get_main_queue(), ^{
        User *user = [[ShelbyDataMediator sharedInstance] fetchAuthenticatedUserOnMainThreadContext];
        self.signupDictionary[kShelbySignupNameKey] = user.name;
        self.signupDictionary[kShelbySignupUsernameKey] = user.facebookNickname;
        // User might not have an email account. (in the case that the email account was used to signup with another user.
        if (user.email) {
            self.signupDictionary[kShelbySignupEmailKey] = user.email;
        }
        self.facebookSignup = YES;
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[user avatarURL]];
        __weak SignupFlowStepOneViewController *weakself = self;
        [self.avatar setImageWithURLRequest:request placeholderImage:self.avatar.image success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
            weakself.signupDictionary[kShelbySignupAvatarKey] = image;
            [weakself signupSuccess];
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
            // No big deal, continue signup without user's avatar.
            [weakself signupSuccess];
        }];
    });
}

- (void)startSignupUser
{

    UIViewController *parent = self.parentViewController;
    if ([parent conformsToProtocol:@protocol(SignupFlowViewDelegate)]) {
        [self viewEnabled:NO];
        // Change Right Button with Activity Indicator
        UIActivityIndicatorView *activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        [activity startAnimating];
        activity.frame = CGRectMake(10, 10, 50, 44);
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:activity];

        self.navigationItem.leftBarButtonItem.enabled = NO;

        User *user = [[ShelbyDataMediator sharedInstance] fetchAuthenticatedUserOnMainThreadContext];
        // If user exists, just update the values. Otherwise, create new user
        if (user) {
            [self addObserversForSignup:NO withEmail:NO];
            
            [parent performSelector:@selector(updateSignupUser)];
        } else {
            [self addObserversForSignup:YES withEmail:YES];

            [parent performSelector:@selector(signupUser)];
        }
    }
}

- (void)signupSuccess
{
    [self viewEnabled:YES];
    
    [self performSegueWithIdentifier:@"ChooseVideos" sender:self];
    self.navigationItem.rightBarButtonItem = self.nextButton;
    self.navigationItem.leftBarButtonItem.enabled = YES;
}

- (void)signupErrorWithErrorMessage:(NSString *)errorMessage
{
    [self viewEnabled:YES];
    
    if (!errorMessage || ![errorMessage isKindOfClass:[NSString class]] || [errorMessage isEqualToString:@""]) {
        errorMessage = @"There was a problem. Please try again later.";
    }
    
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:errorMessage
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil, nil];
    [alertView show];
    
    self.navigationItem.rightBarButtonItem = self.nextButton;
    self.navigationItem.leftBarButtonItem.enabled = YES;

}

- (void)viewEnabled:(BOOL)enabled
{
    self.view.userInteractionEnabled = enabled;
    self.view.alpha = enabled ? 1.0 : 0.8;
}

- (void)userSignupDidFail:(NSNotification *)notification
{
    [self removeObserversForSignup:YES];
    
    [self signupErrorWithErrorMessage:notification.object];
}

- (void)userSignupDidSucceed:(NSNotification *)notification
{
    [self removeObserversForSignup:YES];
    self.facebookSignup = NO;
    [self signupSuccess];
}

- (void)userUpdateDidFail:(NSNotification *)notification
{
    [self removeObserversForSignup:NO];
    
    [self signupErrorWithErrorMessage:notification.object];
}

- (void)userUpdateDidSucceed:(NSNotification *)notification
{
    [self removeObserversForSignup:NO];
    
    [self signupSuccess];
}

#pragma mark - UIAlertViewDialog Methods
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        [self startSignupUser];
    } else {
        [self assignAvatar];
    }
}
@end
