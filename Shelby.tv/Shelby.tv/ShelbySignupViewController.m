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
#import "UIImageView+AFNetworking.h"
#import <QuartzCore/QuartzCore.h>

@interface ShelbySignupViewController ()
@property (nonatomic, weak) IBOutlet UIView *stepOneView;
@property (nonatomic, weak) IBOutlet UITextField *stepOneNickname;
@property (nonatomic, weak) IBOutlet UITextField *stepOneEmail;
@property (nonatomic, weak) IBOutlet UITextField *stepOnePassword;
@property (nonatomic, weak) IBOutlet UIButton *stepOneSignUpWithFacebook;
@property (nonatomic, weak) IBOutlet UIButton *stepOneSignUpWithEmail;
@property (nonatomic, weak) IBOutlet UILabel *stepOneOr;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *stepOneActivityIndicator;

@property (nonatomic, weak) IBOutlet UIView *stepTwoView;
@property (nonatomic, weak) IBOutlet UITextField *stepTwoUsername;
@property (nonatomic, weak) IBOutlet UITextField *stepTwoName;
@property (nonatomic, weak) IBOutlet UITextField *stepTwoEmail;
@property (nonatomic, weak) IBOutlet UITextView *stepTwoBio;
@property (nonatomic, weak) IBOutlet UITextField *stepTwoPassword;
@property (nonatomic, weak) IBOutlet UIButton *stepTwoSaveProfile;
@property (nonatomic, weak) IBOutlet UIImageView *avatarImage;
@property (nonatomic, weak) IBOutlet UILabel *stepTwoTitle;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *stepTwoActivityIndicator;

@property (nonatomic, weak) IBOutlet UINavigationItem *signupNavigationItem;

@property (nonatomic, strong) UIImagePickerController *imagePickerVC;

@property (nonatomic, strong) User *currentUser;

- (IBAction)assignAvatar:(id)sender;
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

    self.currentUser = [[ShelbyDataMediator sharedInstance] fetchAuthenticatedUserOnMainThreadContext];

    if (self.prepareForSignup) {
        self.stepTwoView.alpha = 0;
        self.stepOneSignUpWithEmail.enabled = [self stepOneFieldsValid];
        self.stepOneEmail.text = self.currentUser.email;
        self.stepOneNickname.text = @"";
    } else {
        self.stepOneView.hidden = YES;
        self.stepTwoEmail.text = self.currentUser.email;
        self.stepTwoName.text = self.currentUser.name;
        self.stepTwoUsername.text = self.currentUser.nickname;
        self.stepTwoBio.text = self.currentUser.bio;
        self.stepTwoTitle.hidden = YES;
        self.signupNavigationItem.title = @"Edit Profile";
        [self doStepTwoCustomSetupForNavItem:self.signupNavigationItem];
    }
    
    UIImage *textFieldBackground = [[UIImage imageNamed:@"textfield-outline-background"] resizableImageWithCapInsets:UIEdgeInsetsMake(2, 2, 2, 2)];
    if (self.prepareForSignup) {
        [self.stepOneNickname setBackground:textFieldBackground];
        [self.stepOnePassword setBackground:textFieldBackground];
        [self.stepOneEmail setBackground:textFieldBackground];
        self.stepOneOr.layer.cornerRadius = self.stepOneOr.frame.size.height/2;
        self.stepOneOr.layer.masksToBounds = YES;

        [self.stepOneSignUpWithEmail setBackgroundImage:[[UIImage imageNamed:@"green-button-background"] resizableImageWithCapInsets:UIEdgeInsetsMake(2, 2, 2, 2)] forState:UIControlStateNormal];
        [self.stepOneSignUpWithFacebook setBackgroundImage:[[UIImage imageNamed:@"facebook-button-background"] resizableImageWithCapInsets:UIEdgeInsetsMake(2, 2, 2, 2)] forState:UIControlStateNormal];
    } else {
        NSURL *avatarURL = [self.currentUser avatarURL];
        [self.avatarImage setImageWithURL:avatarURL placeholderImage:nil];
    }

    [self.stepTwoEmail setBackground:textFieldBackground];
    [self.stepTwoName setBackground:textFieldBackground];
    [self.stepTwoPassword setBackground:textFieldBackground];
    [self.stepTwoUsername setBackground:textFieldBackground];
    self.stepTwoBio.layer.borderColor = kShelbyColorLightGray.CGColor;
    self.stepTwoBio.layer.borderWidth = 1;
    [self.stepTwoSaveProfile setBackgroundImage:[[UIImage imageNamed:@"green-button-background"] resizableImageWithCapInsets:UIEdgeInsetsMake(2, 2, 2, 2)] forState:UIControlStateNormal];
 
    self.avatarImage.layer.cornerRadius = self.avatarImage.frame.size.height / 2;
    self.avatarImage.layer.masksToBounds = YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)doStepTwoCustomSetupForNavItem:(UINavigationItem *)navItem
{
    // don't need to do anything but subclasses can override if they need to
}

- (void)doStepTwoCustomActionsOnSaveProfile
{
    // don't need to do anything but subclasses can override if they need to
}

- (IBAction)assignAvatar:(id)sender
{
    [self presentImageChooserActionSheetForAvatarView:sender];
}

- (IBAction)signupWithFacebook:(id)sender
{
    [self addObserversForUpdateType:UserUpdateTypeFacebook];
    
    [ShelbyAnalyticsClient sendEventWithCategory:kAnalyticsCategorySignup
                                          action:kAnalyticsSignupWithFacebookStart
                                           label:nil];

    [self.view endEditing:YES];
    [self.stepOneActivityIndicator startAnimating];
    self.stepOneView.userInteractionEnabled = NO;
    
    [[ShelbyDataMediator sharedInstance] openFacebookSessionWithAllowLoginUI:YES];
}

- (IBAction)signupWithEmail:(id)sender
{
    [self addObserversForUpdateType:UserUpdateTypeEmail];
    self.stepOneSignUpWithEmail.enabled = NO;
    
    [self.view endEditing:YES];
    [self.stepOneActivityIndicator startAnimating];
    self.view.userInteractionEnabled = NO;
    
    __weak ShelbySignupViewController *weakSelf = self;
    [[ShelbyDataMediator sharedInstance] updateUserWithName:nil nickname:self.stepOneNickname.text password:self.stepOnePassword.text email:self.stepOneEmail.text avatar:nil rolls:nil completion:^(NSError *error) {
        weakSelf.view.userInteractionEnabled = YES;
        [weakSelf.stepOneActivityIndicator stopAnimating];
        if (!error) {
            [weakSelf goToStepTwo];
            [ShelbyAnalyticsClient sendLocalyticsEvent:kLocalyticsAnonymousConvertViaEmail];
        } else {
            weakSelf.stepOneSignUpWithEmail.enabled = YES;
            NSString *errorMessage = nil;
            if ([error isKindOfClass:[NSDictionary class]]) {
                NSDictionary *JSONError = (NSDictionary *)error;
                errorMessage = JSONError[@"message"];
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:errorMessage delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [alertView show];
            }
        }
    }];
}

- (IBAction)saveProfile:(UIButton *)sender
{
    //if fields are invalid, show alert and do nothing
    if (![self stepTwoFieldsValidShowAlert:YES]) {
        return;
    }
    
    self.stepTwoSaveProfile.enabled = NO;
    sender.enabled = NO;
    [self.view endEditing:YES];
    [self.stepTwoActivityIndicator startAnimating];
    self.view.userInteractionEnabled = NO;

    [self doStepTwoCustomActionsOnSaveProfile];

    [self addObserversForUpdateType:UserUpdateTypeProfile];
    __weak ShelbySignupViewController *weakSelf = self;
    [[ShelbyDataMediator sharedInstance] updateUserWithName:self.stepTwoName.text nickname:self.stepTwoUsername.text password:self.stepTwoPassword.text email:self.stepTwoEmail.text avatar:self.avatarImage.image bio:self.stepTwoBio.text completion:^(NSError *error) {
        weakSelf.stepOneSignUpWithEmail.enabled = YES;
        weakSelf.view.userInteractionEnabled = YES;
        [weakSelf.stepTwoActivityIndicator stopAnimating];
        
        weakSelf.stepTwoSaveProfile.enabled = YES;
        if (!error) {
            [weakSelf closeViewController];
        } else {
            // KP KP
        }
    }];
}

- (void)closeViewController
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)cancel:(id)sender
{
    [self closeViewController];
}

- (void)goToStepTwoWithUsername:(NSString *)username fullname:(NSString *)fullname email:(NSString *)email
{
    self.stepTwoView.alpha = 0;
    
    if (!email) {
        email = @"";
    }
    self.stepTwoEmail.text = email;
    
    if (!fullname) {
        fullname = @"";
    }
    self.stepTwoName.text = fullname;
    
    if (!username) {
        username = @"";
    }
    self.stepTwoUsername.text = username;
    self.stepTwoBio.text = self.currentUser.bio;
    
    if (self.stepOnePassword.text) {
        self.stepTwoPassword.text = self.stepOnePassword.text;
    }
    
    NSURL *avatarURL = [self.currentUser avatarURL];
    if (avatarURL) {
        NSURLRequest *imageRequest = [NSURLRequest requestWithURL:avatarURL];
        __weak ShelbySignupViewController *weakSelf = self;
        [self.avatarImage setImageWithURLRequest:imageRequest placeholderImage:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
            weakSelf.avatarImage.image = image;
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
            //
        }];
    }
    
    [UIView animateWithDuration:1 animations:^{
        self.stepTwoView.alpha = 1;
        self.stepOneView.alpha = 0;
    } completion:^(BOOL finished) {
        self.prepareForSignup = NO;
        [self doStepTwoCustomSetupForNavItem:self.signupNavigationItem];
    }];
}

- (void)goToStepTwo
{
    User *user = [[ShelbyDataMediator sharedInstance] fetchAuthenticatedUserOnMainThreadContext];
    [self goToStepTwoWithUsername:user.nickname fullname:user.name email:user.email];
}

- (void)showErrorMessage:(NSString *)errorMessage
{
    if (!errorMessage || ![errorMessage isKindOfClass:[NSString class]] || [errorMessage isEqualToString:@""]) {
        errorMessage = @"There was a problem. Please try again later.";
    }
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:errorMessage
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil, nil];
    [alertView show];
}

- (void)userSignupDidFail:(NSNotification *)notification
{
    self.stepOneView.userInteractionEnabled = YES;
    
    [self removeObservers];
    if ([notification.object isKindOfClass:[NSString class]]) {
        [self showErrorMessage:notification.object];
    } else {
        [self showErrorMessage:nil];
    }
}

- (void)userSignupDidSucceed:(NSNotification *)notification
{
    NSDictionary *facebookUser = notification.object;
    NSString *email = nil;
    NSString *name = nil;
    NSString *nickname = nil;
    if ([facebookUser isKindOfClass:[NSDictionary class]]) {
        email = facebookUser[@"email"];
        name = facebookUser[@"name"];
        nickname = facebookUser[@"username"];
        [ShelbyAnalyticsClient sendLocalyticsEvent:kLocalyticsAnonymousConvertViaFacebook];
    }
    
    [self removeObservers];
    [self goToStepTwoWithUsername:nickname fullname:name email:email];
}

- (void)userUpdateDidFail:(NSNotification *)notification
{
    [self removeObservers];
    
    if ([notification.object isKindOfClass:[NSString class]]) {
        [self showErrorMessage:notification.object];
    } else {
        [self showErrorMessage:nil];
    }
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
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kShelbyNotificationUserSignupDidSucceed object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kShelbyNotificationUserSignupDidFail object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kShelbyNotificationFacebookConnectCompleted object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kShelbyNotificationFacebookAuthorizationCompletedWithError object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kShelbyNotificationUserUpdateDidSucceed object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kShelbyNotificationUserUpdateDidFail object:nil];
}

- (BOOL)stepOneFieldsValid
{
    NSString *nickname = self.stepOneNickname.text;
    NSString *email = self.stepOneEmail.text;
    NSString *password = self.stepOnePassword.text;
    
    return [ShelbyValidationUtility isUsernameValid:nickname] && [ShelbyValidationUtility isPasswordValid:password] && [ShelbyValidationUtility isEmailValid:email];
}


- (BOOL)stepTwoFieldsValidShowAlert:(BOOL)showAlertOnInvalid
{
    BOOL allFieldsValid = YES;
    NSString *alertMessage;
    
    if (![ShelbyValidationUtility isNameValid:self.stepTwoName.text]) {
        allFieldsValid = NO;
        alertMessage = @"Please enter your full name";
    }
    if (![ShelbyValidationUtility isEmailValid:self.stepTwoEmail.text]) {
        allFieldsValid = NO;
        alertMessage = @"Please enter a valid email address";
    }
    if (![ShelbyValidationUtility isUsernameValid:self.stepTwoUsername.text]) {
        allFieldsValid = NO;
        alertMessage = @"Please pick a username";
    }
    // If a user is editing their profile ignore the password field. Unless they are trying to change it
    if (![ShelbyValidationUtility isPasswordValid:self.stepTwoPassword.text] &&
        !(![self.currentUser isAnonymousUser] && [self.stepTwoPassword.text isEqualToString:@""])) {
        allFieldsValid = NO;
        alertMessage = @"Please enter a password";
    }
    
    if (showAlertOnInvalid && !allFieldsValid) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"We need more info"
                                                        message:alertMessage
                                                       delegate:nil
                                              cancelButtonTitle:@"Ok"
                                              otherButtonTitles:nil];
        [alert show];
    }
    return  allFieldsValid;
}

#pragma mark - Abstract Methods
- (void)presentImageChooserActionSheetForAvatarView:(UIView *)avatarView
{
    NSAssert(NO, @"Invoked non-overidden abstract method [ShelbySignupViewController presentImageChooserActionSheet]");
}

- (void)presentPhotoAlbumImagePickerController:(UIImagePickerController *)imagePickerController forAvatarView:(UIView *)avatarView;
{
    NSAssert(NO, @"Invoked non-overidden abstract method [ShelbySignupViewController presentPhotoAlbumImagePickerController]");
}

#pragma mark - Supported Device Orientations
- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - UITextFieldDelegate Methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if ([self.stepOneNickname isFirstResponder]) {
        [self.stepOneEmail becomeFirstResponder];
    } else if ([self.stepOneEmail isFirstResponder]) {
        [self.stepOnePassword becomeFirstResponder];
    } else if ([self.stepOnePassword isFirstResponder] && self.stepOneSignUpWithEmail.enabled) {
        // if all step one fields are valid and we hit the "done" button while in the final field,
        // just go ahead and do the sign up, don't wait for the user to additionally tap the
        // Sign Up button
        [self signupWithEmail:self.stepOneSignUpWithEmail];
    } else if ([self.stepTwoUsername isFirstResponder]) {
        [self.stepTwoName becomeFirstResponder];
    } else if ([self.stepTwoName isFirstResponder]) {
        [self.stepTwoEmail becomeFirstResponder];
    } else if ([self.stepTwoEmail isFirstResponder]) {
        [self.stepTwoPassword becomeFirstResponder];
    } else if ([self.stepTwoPassword isFirstResponder]) {
        [self.stepTwoBio becomeFirstResponder];
    } else {
        [textField resignFirstResponder];
        return YES;
    }
    
    return NO;
}

//NB: confusingly, this is the delegate for name/email on step 1 and username/password on step 4
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (textField == self.stepOneNickname || textField == self.stepOneEmail || textField == self.stepOnePassword) {
        NSString *nickname = self.stepOneNickname.text;
        NSString *email = self.stepOneEmail.text;
        NSString *password = self.stepOnePassword.text;
        if (textField == self.stepOneNickname) {
            nickname = [nickname stringByReplacingCharactersInRange:range withString:string];
        }
        
        if (textField == self.stepOneEmail) {
            email = [email stringByReplacingCharactersInRange:range withString:string];
        }
        
        if (textField == self.stepOnePassword) {
            password = [password stringByReplacingCharactersInRange:range withString:string];
        }
        
        self.stepOneSignUpWithEmail.enabled = [ShelbyValidationUtility isUsernameValid:nickname] && [ShelbyValidationUtility isPasswordValid:password] && [ShelbyValidationUtility isEmailValid:email];
    } else {
        //not checking on step 2 (tapping save will throw up alert error)
    }
    
    return YES;
}

- (void)dismissImagePicker
{
    if (self.popoverVC) {
        [self.popoverVC dismissPopoverAnimated:YES];
    } else {
        self.stepTwoView.alpha = 0;
        [self.imagePickerVC dismissViewControllerAnimated:YES completion:^{
            self.stepTwoView.alpha = 1;
        }];
    }
}

#pragma mark - UIImagePickerControllerDelegate Methods

// This method is called when an image has been chosen from the library or taken from the camera.
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = [info valueForKey:UIImagePickerControllerOriginalImage];
    
    self.avatarImage.image = image;
    
    [self dismissImagePicker];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissImagePicker];
}

#pragma mark - UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 2) {
        return;
    }
    
    UIImagePickerControllerSourceType sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    if (buttonIndex == 1) {
        // This check for camera is for the Simulator - all iOS6 devices that support iOS6 have camera.
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
            sourceType = UIImagePickerControllerSourceTypeCamera;
        }
    }
    
    self.imagePickerVC = [[UIImagePickerController alloc] init];
    self.imagePickerVC.sourceType = sourceType;
    self.imagePickerVC.delegate = self;
    
    if (sourceType == UIImagePickerControllerSourceTypeSavedPhotosAlbum) {
        [self presentPhotoAlbumImagePickerController:self.imagePickerVC forAvatarView:self.avatarImage];
    } else {
        self.popoverVC = nil;
        self.imagePickerVC.modalPresentationStyle = UIModalPresentationFullScreen;
        
        [self presentViewController:self.imagePickerVC animated:YES completion:nil];
    }
}

@end
