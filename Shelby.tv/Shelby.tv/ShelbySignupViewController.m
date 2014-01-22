//
//  ShelbySignupViewController.m
//  Shelby.tv
//
//  Created by Keren on 1/21/14.
//  Copyright (c) 2014 Shelby TV, Inc. All rights reserved.
//

#import "ShelbySignupViewController.h"
#import "FacebookHandler.h"
#import "ShelbyValidationUtility.h"
#import "ShelbyAnalyticsClient.h"
#import "ShelbyDataMediator.h"
#import <QuartzCore/QuartzCore.h>

@interface ShelbySignupViewController ()
@property (nonatomic, weak) IBOutlet UIView *stepOneView;
@property (nonatomic, weak) IBOutlet UITextField *stepOneName;
@property (nonatomic, weak) IBOutlet UITextField *stepOneEmail;
@property (nonatomic, weak) IBOutlet UITextField *stepOnePassword;
@property (nonatomic, weak) IBOutlet UIButton *stepOneSignUpWithFacebook;
@property (nonatomic, weak) IBOutlet UIButton *stepOneSignUpWithEmail;
@property (nonatomic, weak) IBOutlet UILabel *stepOneOr;

@property (nonatomic, weak) IBOutlet UIView *stepTwoView;
@property (nonatomic, weak) IBOutlet UITextField *stepTwoUsername;
@property (nonatomic, weak) IBOutlet UITextField *stepTwoName;
@property (nonatomic, weak) IBOutlet UITextField *stepTwoEmail;
@property (nonatomic, weak) IBOutlet UITextField *stepTwoPassword;
@property (nonatomic, weak) IBOutlet UIButton *stepTwoSaveProfile;

@property (nonatomic, assign) BOOL stepOneActive;

@property (nonatomic, strong) User *currentUser;

- (IBAction)signupWithFacebook:(id)sender;
- (IBAction)signupWithEmail:(id)sender;
- (IBAction)saveProfile:(id)sender;
- (IBAction)cancel:(id)sender;
@end

typedef NS_ENUM(NSInteger, UserUpdateType) {
    UserUpdateTypeFacebook,
    UserUpdateTypeEmail,
    UserUpdateTypeProfile
};


@implementation ShelbySignupViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _stepOneActive = YES;
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.currentUser = [[ShelbyDataMediator sharedInstance] fetchAuthenticatedUserOnMainThreadContext];
    self.stepOneEmail.text = self.currentUser.email;
    self.stepOneName.text = self.currentUser.name;
    
    if (self.stepOneActive) {
        self.stepTwoView.alpha = 0;
       [self.stepOneName becomeFirstResponder];
        self.stepOneSignUpWithEmail.enabled = NO;
    } else {
        self.stepOneView.alpha = 0;
        self.stepTwoView.frame = self.stepOneView.frame;
        [self.stepTwoUsername becomeFirstResponder];
        self.stepTwoSaveProfile.enabled = NO;
    }
    
    //title font
//    self.titleLabel.font = kShelbyFontH1Bold;
    
    //text field backgrounds
    UIImage *textFieldBackground = [[UIImage imageNamed:@"textfield-outline-background"] resizableImageWithCapInsets:UIEdgeInsetsMake(2, 2, 2, 2)];
    [self.stepOneName setBackground:textFieldBackground];
    [self.stepOnePassword setBackground:textFieldBackground];
    [self.stepOneEmail setBackground:textFieldBackground];
    [self.stepTwoEmail setBackground:textFieldBackground];
    [self.stepTwoName setBackground:textFieldBackground];
    [self.stepTwoPassword setBackground:textFieldBackground];
    [self.stepTwoUsername setBackground:textFieldBackground];
    
    //button backgrounds
    [self.stepOneSignUpWithEmail setBackgroundImage:[[UIImage imageNamed:@"green-button-background"] resizableImageWithCapInsets:UIEdgeInsetsMake(2, 2, 2, 2)] forState:UIControlStateNormal];
    [self.stepOneSignUpWithFacebook setBackgroundImage:[[UIImage imageNamed:@"facebook-button-background"] resizableImageWithCapInsets:UIEdgeInsetsMake(2, 2, 2, 2)] forState:UIControlStateNormal];
    [self.stepTwoSaveProfile setBackgroundImage:[[UIImage imageNamed:@"green-button-background"] resizableImageWithCapInsets:UIEdgeInsetsMake(2, 2, 2, 2)] forState:UIControlStateNormal];
 
//    UIImage *secondaryButtonBackground = [[UIImage imageNamed:@"secondary-button-background"] resizableImageWithCapInsets:UIEdgeInsetsMake(2, 2, 2, 2)];
//    [self.forgotPasswordButton setBackgroundImage:secondaryButtonBackground forState:UIControlStateNormal];
//    [self.signupButton setBackgroundImage:secondaryButtonBackground forState:UIControlStateNormal];
    
    self.stepOneOr.layer.cornerRadius = self.stepOneOr.frame.size.height/2;
    self.stepOneOr.layer.masksToBounds = YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)signupWithFacebook:(id)sender
{
    [self addObserversForUpdateType:UserUpdateTypeFacebook];
    
    [ShelbyAnalyticsClient sendEventWithCategory:kAnalyticsCategorySignup
                                          action:kAnalyticsSignupWithFacebookStart
                                           label:nil];

    [[ShelbyDataMediator sharedInstance] openFacebookSessionWithAllowLoginUI:YES];
}

- (IBAction)signupWithEmail:(id)sender
{
    [self addObserversForUpdateType:UserUpdateTypeEmail];

    __weak ShelbySignupViewController *weakSelf = self;
    [[ShelbyDataMediator sharedInstance] updateUserWithName:self.stepOneName.text nickname:nil password:self.stepOnePassword.text email:self.stepOneEmail.text avatar:nil rolls:nil completion:^(NSError *error) {
        if (!error) {
            [weakSelf goToStepTwo];
        } else {
            // KP KP
        }
    }];
}

- (IBAction)saveProfile:(id)sender
{

    
    [self addObserversForUpdateType:UserUpdateTypeProfile];
    __weak ShelbySignupViewController *weakSelf = self;
    [[ShelbyDataMediator sharedInstance] updateUserWithName:self.stepOneName.text nickname:nil password:self.stepOnePassword.text email:self.stepOneEmail.text avatar:nil rolls:nil completion:^(NSError *error) {
        if (!error) {
            [weakSelf cancel:nil];
        } else {
            // KP KP
        }
    }];
}

- (IBAction)cancel:(id)sender
{
    if ([[ShelbyDataMediator sharedInstance] fetchAuthenticatedUserOnMainThreadContext]) {
        //a user has been created, need to get rid of it
        [[ShelbyDataMediator sharedInstance] logoutCurrentUser];
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)goToStepTwo
{
    self.stepTwoView.alpha = 0;
    self.stepTwoView.frame = CGRectMake(0, 44, 768, 350);
    
    self.currentUser = [[ShelbyDataMediator sharedInstance] fetchAuthenticatedUserOnMainThreadContext];
    self.stepTwoEmail.text = self.currentUser.email;
    self.stepTwoName.text = self.currentUser.name;
    self.stepTwoUsername.text = self.currentUser.nickname;
    
    [UIView animateWithDuration:1 animations:^{
        self.stepTwoView.alpha = 1;
        self.stepOneView.alpha = 0;
    } completion:^(BOOL finished) {
        self.stepOneActive = NO;
    }];
}

- (void)userSignupDidFail:(NSNotification *)notification
{
    [self removeObservers];
    
//    [self signupErrorWithErrorMessage:notification.object];
}

- (void)userSignupDidSucceed:(NSNotification *)notification
{
    [self removeObservers];
    [self goToStepTwo];
//    self.facebookSignup = NO;
//    [self signupSuccess];
}

- (void)userUpdateDidFail:(NSNotification *)notification
{
    [self removeObservers];
    
//    [self signupErrorWithErrorMessage:notification.object];
}

- (void)userUpdateDidSucceed:(NSNotification *)notification
{
    [self removeObservers];
    
//    [self signupSuccess];
}

- (void)addObserversForUpdateType:(UserUpdateType)userUpdateType
{
    if (userUpdateType == UserUpdateTypeEmail) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userSignupDidSucceed:) name:kShelbyNotificationUserSignupDidSucceed object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userSignupDidFail:) name:kShelbyNotificationUserSignupDidFail object:nil];
    } else if (userUpdateType == UserUpdateTypeFacebook){
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userSignupDidSucceed:) name:kShelbyNotificationFacebookConnectCompleted object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userSignupDidFail:) name:kShelbyNotificationFacebookAuthorizationCompletedWithError object:nil];
    } else { // userUpdateType == UserUpdateTypeProfile
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userUpdateDidSucceed:) name:kShelbyNotificationUserUpdateDidSucceed object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userUpdateDidFail:) name:kShelbyNotificationUserUpdateDidFail object:nil];
    }
}

- (void)removeObservers
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - UITextFieldDelegate Methods
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if ([self.stepOneName isFirstResponder]) {
        [self.stepOneName resignFirstResponder];
        [self.stepOneEmail becomeFirstResponder];
    } else if ([self.stepOneEmail isFirstResponder]) {
        [self.stepOneEmail resignFirstResponder];
        [self.stepOnePassword becomeFirstResponder];
    } else if ([self.stepTwoUsername isFirstResponder]) {
        [self.stepTwoUsername resignFirstResponder];
        [self.stepTwoName becomeFirstResponder];
    } else if ([self.stepTwoName isFirstResponder]) {
        [self.stepTwoName resignFirstResponder];
        [self.stepTwoEmail becomeFirstResponder];
    } else if ([self.stepTwoEmail isFirstResponder]) {
        [self.stepTwoEmail resignFirstResponder];
        [self.stepTwoPassword becomeFirstResponder];
    } else {
        [textField resignFirstResponder];
    }
    
    return YES;
}

//NB: confusingly, this is the delegate for name/email on step 1 and username/password on step 4
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (textField == self.stepOneName || textField == self.stepOneEmail || textField == self.stepOnePassword) {
        NSString *name = self.stepOneName.text;
        NSString *email = self.stepOneEmail.text;
        NSString *password = self.stepOnePassword.text;
        if (textField == self.stepOneName) {
            name = [name stringByReplacingCharactersInRange:range withString:string];
        }
        
        if (textField == self.stepOneEmail) {
            email = [email stringByReplacingCharactersInRange:range withString:string];
        }
        
        if (textField == self.stepOnePassword) {
            password = [password stringByReplacingCharactersInRange:range withString:string];
        }
        
        self.stepOneSignUpWithEmail.enabled = [ShelbyValidationUtility isNameValid:name] && [ShelbyValidationUtility isPasswordValid:password] && [ShelbyValidationUtility isEmailValid:email];
    } else {
        NSString *name = self.stepOneName.text;
        NSString *email = self.stepTwoEmail.text;
        NSString *password = self.stepTwoPassword.text;
        NSString *username = self.stepTwoUsername.text;
        
        if (textField == self.stepTwoName) {
            name = [name stringByReplacingCharactersInRange:range withString:string];
        }
        
        if (textField == self.stepTwoEmail) {
            email = [email stringByReplacingCharactersInRange:range withString:string];
        }
        
        if (textField == self.stepTwoPassword) {
            password = [password stringByReplacingCharactersInRange:range withString:string];
        }

        if (textField == self.stepTwoUsername) {
            username = [username stringByReplacingCharactersInRange:range withString:string];
        }
        
        self.stepTwoSaveProfile.enabled = [ShelbyValidationUtility isNameValid:name] && [ShelbyValidationUtility isPasswordValid:password] && [ShelbyValidationUtility isEmailValid:email] && [ShelbyValidationUtility isUsernameValid:username];
    }
    
    return YES;
}


@end
