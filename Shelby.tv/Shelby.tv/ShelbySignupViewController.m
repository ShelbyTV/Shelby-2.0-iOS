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
@property (nonatomic, weak) IBOutlet UITextView *stepTwoBio;
@property (nonatomic, weak) IBOutlet UITextField *stepTwoPassword;
@property (nonatomic, weak) IBOutlet UIButton *stepTwoSaveProfile;
@property (nonatomic, weak) IBOutlet UIImageView *avatarImage;

@property (nonatomic, assign) BOOL stepOneActive;

@property (nonatomic, strong) UIPopoverController *popoverVC;
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
        self.stepOneSignUpWithEmail.enabled = [self stepOneFieldsValid];
    } else {
        self.stepOneView.alpha = 0;
        self.stepTwoView.frame = self.stepOneView.frame;
        self.stepTwoSaveProfile.enabled = [self stepTwoFieldsValid];
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
    
    self.stepTwoBio.layer.borderColor = kShelbyColorLightGray.CGColor;
    self.stepTwoBio.layer.borderWidth = 1;
    
    //button backgrounds
    [self.stepOneSignUpWithEmail setBackgroundImage:[[UIImage imageNamed:@"green-button-background"] resizableImageWithCapInsets:UIEdgeInsetsMake(2, 2, 2, 2)] forState:UIControlStateNormal];
    [self.stepOneSignUpWithFacebook setBackgroundImage:[[UIImage imageNamed:@"facebook-button-background"] resizableImageWithCapInsets:UIEdgeInsetsMake(2, 2, 2, 2)] forState:UIControlStateNormal];
    [self.stepTwoSaveProfile setBackgroundImage:[[UIImage imageNamed:@"green-button-background"] resizableImageWithCapInsets:UIEdgeInsetsMake(2, 2, 2, 2)] forState:UIControlStateNormal];
 
    self.avatarImage.layer.cornerRadius = self.avatarImage.frame.size.height / 2;
    self.avatarImage.layer.masksToBounds = YES;
    
    self.stepOneOr.layer.cornerRadius = self.stepOneOr.frame.size.height/2;
    self.stepOneOr.layer.masksToBounds = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    [UIApplication sharedApplication].statusBarHidden = YES;
    
    if (self.stepOneActive) {
        [self.stepOneName becomeFirstResponder];
    } else {
        [self.stepTwoUsername becomeFirstResponder];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [UIApplication sharedApplication].statusBarHidden = NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)assignAvatar:(id)sender
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Camera Roll", @"Take Photo", nil];
    [actionSheet showFromRect:((UIView *)sender).frame inView:self.view animated:YES];
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
    self.stepOneSignUpWithEmail.enabled = NO;
    
    __weak ShelbySignupViewController *weakSelf = self;
    [[ShelbyDataMediator sharedInstance] updateUserWithName:self.stepOneName.text nickname:nil password:self.stepOnePassword.text email:self.stepOneEmail.text avatar:nil rolls:nil completion:^(NSError *error) {
        self.stepOneSignUpWithEmail.enabled = YES;
        if (!error) {
            [weakSelf goToStepTwo];
        } else {
            // KP KP
        }
    }];
}

- (IBAction)saveProfile:(id)sender
{
    self.stepTwoSaveProfile.enabled = NO;
    
    [self addObserversForUpdateType:UserUpdateTypeProfile];
    __weak ShelbySignupViewController *weakSelf = self;
    [[ShelbyDataMediator sharedInstance] updateUserWithName:self.stepOneName.text nickname:self.stepTwoUsername.text password:self.stepOnePassword.text email:self.stepOneEmail.text avatar:nil rolls:nil completion:^(NSError *error) {
        self.stepTwoSaveProfile.enabled = YES;
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

- (void)goToStepTwo
{
    self.stepTwoView.alpha = 0;
    self.stepTwoView.frame = CGRectMake(0, 44, 768, 350);
    
    self.stepTwoSaveProfile.enabled = [self stepTwoFieldsValid];
    self.currentUser = [[ShelbyDataMediator sharedInstance] fetchAuthenticatedUserOnMainThreadContext];
    self.stepTwoEmail.text = self.currentUser.email;
    self.stepTwoName.text = self.currentUser.name;
    self.stepTwoUsername.text = self.currentUser.nickname;
    self.stepTwoBio.text = self.currentUser.bio;
    
    if (self.stepOnePassword.text) {
        self.stepTwoPassword.text = self.stepOnePassword.text;
    }
    
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

- (BOOL)stepOneFieldsValid
{
    NSString *name = self.stepOneName.text;
    NSString *email = self.stepOneEmail.text;
    NSString *password = self.stepOnePassword.text;
    
    return [ShelbyValidationUtility isNameValid:name] && [ShelbyValidationUtility isPasswordValid:password] && [ShelbyValidationUtility isEmailValid:email];
}


- (BOOL)stepTwoFieldsValid
{
    NSString *name = self.stepOneName.text;
    NSString *email = self.stepTwoEmail.text;
    NSString *password = self.stepTwoPassword.text;
    NSString *username = self.stepTwoUsername.text;
    
    return self.stepTwoSaveProfile.enabled = [ShelbyValidationUtility isNameValid:name] && [ShelbyValidationUtility isPasswordValid:password] && [ShelbyValidationUtility isEmailValid:email] && [ShelbyValidationUtility isUsernameValid:username];
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

- (void)dismissImagePicker
{
    if (self.popoverVC) {
        [self.popoverVC dismissPopoverAnimated:YES];
    } else {
        self.stepTwoView.alpha = 0;
        [self.imagePickerVC dismissViewControllerAnimated:YES completion:^{
            self.stepTwoView.frame = CGRectMake(0, 64, self.stepTwoView.frame.size.width, self.stepTwoView.frame.size.height);
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
        self.popoverVC = [[UIPopoverController alloc] initWithContentViewController:self.imagePickerVC];
        [self.popoverVC presentPopoverFromRect:self.avatarImage.frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionLeft animated:YES];
    } else {
        self.popoverVC = nil;
        self.imagePickerVC.modalPresentationStyle = UIModalPresentationFullScreen;
        
        [self presentViewController:self.imagePickerVC animated:YES completion:nil];
    }
}

@end
