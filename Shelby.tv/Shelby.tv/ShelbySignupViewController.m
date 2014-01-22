//
//  ShelbySignupViewController.m
//  Shelby.tv
//
//  Created by Keren on 1/21/14.
//  Copyright (c) 2014 Shelby TV, Inc. All rights reserved.
//

#import "ShelbySignupViewController.h"
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

- (IBAction)signupWithFacebook:(id)sender;
- (IBAction)signupWithEmail:(id)sender;
- (IBAction)saveProfile:(id)sender;
- (IBAction)cancel:(id)sender;
@end

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

    if (self.stepOneActive) {
        self.stepTwoView.alpha = 0;
       [self.stepOneName becomeFirstResponder];
    } else {
        self.stepOneView.alpha = 0;
        self.stepTwoView.frame = self.stepOneView.frame;
        [self.stepTwoUsername becomeFirstResponder];
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
    [self addObserversForSignup:YES withEmail:NO];
    
    [ShelbyAnalyticsClient sendEventWithCategory:kAnalyticsCategorySignup
                                          action:kAnalyticsSignupWithFacebookStart
                                           label:nil];

     [[ShelbyDataMediator sharedInstance] createUserWithFacebook];
}

- (IBAction)signupWithEmail:(id)sender
{
    [self addObserversForSignup:YES withEmail:YES];

    [self goToStepTwo];
//     [[ShelbyDataMediator sharedInstance] createUserWithName:name andEmail:email];
}

- (IBAction)saveProfile:(id)sender
{
    [self addObserversForSignup:NO withEmail:NO];

//    [[ShelbyDataMediator sharedInstance] updateUserWithName:name nickname:nil password:nil email:email avatar:nil rolls:nil completion:nil];
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
    
    [UIView animateWithDuration:1 animations:^{
        self.stepTwoView.alpha = 1;
        self.stepOneView.alpha = 0;
    }];
}

- (void)userSignupDidFail:(NSNotification *)notification
{
    [self removeObserversForSignup:YES];
    
//    [self signupErrorWithErrorMessage:notification.object];
}

- (void)userSignupDidSucceed:(NSNotification *)notification
{
    [self removeObserversForSignup:YES];
//    self.facebookSignup = NO;
//    [self signupSuccess];
}

- (void)userUpdateDidFail:(NSNotification *)notification
{
    [self removeObserversForSignup:NO];
    
//    [self signupErrorWithErrorMessage:notification.object];
}

- (void)userUpdateDidSucceed:(NSNotification *)notification
{
    [self removeObserversForSignup:NO];
    
//    [self signupSuccess];
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


#pragma mark - UITextFieldDelegate Methods
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    if (self.view.frame.origin.x == 0) {
//        [self animateOpenEditing];
    }
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
//    [self modifyDictionaryWithTextFieldValue:textField];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
//    [self modifyDictionaryWithTextFieldValue:textField];
    
    [textField resignFirstResponder];
    
    // Set focus on the next TextField in the form. If last TextField, move view back down.
    //TODO: this should be moved in the individual views, since only they know what order their fields are in
    
//    BOOL shouldResign = NO;
//    if (textField == TextFieldTagName) {
//        [self.email becomeFirstResponder];
//    } else if (tag == TextFieldTagEmail) {
//        if (!self.username) {
//            shouldResign = YES;
//        } else {
//            [self.username becomeFirstResponder];
//        }
//    } else if (tag == TextFieldTagUsername) {
//        [self.password becomeFirstResponder];
//    } else {
//        shouldResign = YES;
//    }
//    
//    if (shouldResign) {
//        [self animateCloseEditing];
//    }
    
    return YES;
}

//NB: confusingly, this is the delegate for name/email on step 1 and username/password on step 4
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
//    BOOL nextEnabled = NO;
//    if (textField == self.nameField || textField == self.email) {
//        NSString *name = self.nameField.text;
//        NSString *email = self.email.text;
//        if (textField == self.nameField) {
//            name = [name stringByReplacingCharactersInRange:range withString:string];
//        }
//        if (textField == self.email) {
//            email = [email stringByReplacingCharactersInRange:range withString:string];
//        }
//        nextEnabled = [ShelbyValidationUtility isNameValid:name] && [ShelbyValidationUtility isEmailValid:email];
//        
//    } else {
//        NSString *username = self.username.text;
//        NSString *password = self.password.text;
//        if (textField == self.username) {
//            username = [username stringByReplacingCharactersInRange:range withString:string];
//        }
//        if (textField == self.password) {
//            password = [password stringByReplacingCharactersInRange:range withString:string];
//        }
//        nextEnabled = [ShelbyValidationUtility isUsernameValid:username] && [ShelbyValidationUtility isPasswordValid:password];
//    }
//    self.nextButton.enabled = nextEnabled;
    
    return YES;
}


@end
