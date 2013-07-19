//
//  SignupFlowViewController.m
//  Shelby.tv
//
//  Created by Keren on 7/8/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "SignupFlowViewController.h"
#import "SignupVideoTypeViewCell.h"
#import "ShelbyDataMediator.h"
#import "User.h"
#import <QuartzCore/QuartzCore.h>

NSString * const kShelbySignupAvatarKey          = @"SignupAvatar";
NSString * const kShelbySignupEmailKey           = @"SignupEmail";
NSString * const kShelbySignupNameKey            = @"SignupName";
NSString * const kShelbySignupPasswordKey        = @"SignupPassword";
NSString * const kShelbySignupUsernameKey        = @"SignupUsername";
NSString * const kShelbySignupVideoTypesKey      = @"SignupVideoTypes";


typedef NS_ENUM(NSInteger, TextFieldTag) {
    TextFieldTagName,
    TextFieldTagEmail,
    TextFieldTagUsername,
    TextFieldTagPassword
};

@interface SignupFlowViewController ()
@property (nonatomic, weak) IBOutlet UIImageView *avatar;
@property (weak, nonatomic) IBOutlet UIButton *chooseAvatarButton;
@property (nonatomic, weak) IBOutlet UILabel *nameLabel;

- (IBAction)assignAvatar:(id)sender;
- (IBAction)resignKeyboard:(id)sender;

@end

@implementation SignupFlowViewController

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
	// Do any additional setup after loading the view.
    
    // Assign Tags to TextFields - So we can differentiate them.
    self.nameField.tag = TextFieldTagName;
    self.email.tag = TextFieldTagEmail;
    self.username.tag = TextFieldTagUsername;
    self.password.tag = TextFieldTagPassword;
    
    // Password field should be secure
    self.password.secureTextEntry = YES;

    self.videoTypes.allowsMultipleSelection = YES;
    [self.videoTypes registerNib:[UINib nibWithNibName:@"SignupVideoTypeViewCell" bundle:nil] forCellWithReuseIdentifier:@"VideoType"];
    [self.videoTypes registerNib:[UINib nibWithNibName:@"SignupUserInfoViewCell" bundle:nil] forCellWithReuseIdentifier:@"SignupUserInfoCell"];
    
    UIBarButtonItem *backBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:[self customLeftButtonView]];
    self.navigationItem.leftBarButtonItem = backBarButtonItem;
    
    // Next Button
    NSString *nextTitle = self.navigationItem.rightBarButtonItem.title;
    SEL selector = self.navigationItem.rightBarButtonItem.action;
    UIButton *nextButton = [UIButton buttonWithType:UIButtonTypeCustom];
    nextButton.frame = [self nextButtonFrame];
    [nextButton setTitleColor:kShelbyColorLightGray forState:UIControlStateDisabled];
    [nextButton setTitleColor:kShelbyColorGreen forState:UIControlStateNormal];
    [nextButton addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];
    [nextButton setTitle:nextTitle forState:UIControlStateNormal];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:nextButton];
    self.nextButton = self.navigationItem.rightBarButtonItem;

    // Round corners for Avatar
    if (self.avatar) {
        self.avatar.layer.cornerRadius = 5;
        self.avatar.layer.masksToBounds = YES;
    }
    
    // Background Image
    NSString *imageNameSuffix = nil;
    if (kShelbyFullscreenHeight > 480) {
        imageNameSuffix = @"-568h";
    } else {
        imageNameSuffix = @"";
    }
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:[NSString stringWithFormat:@"bkgd-step%@%@.png", [self signupStepNumber], imageNameSuffix]]];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.signupDictionary[kShelbySignupAvatarKey]) {
        self.avatarImage = self.signupDictionary[kShelbySignupAvatarKey];
        if (self.avatar) {
            self.avatar.image = self.avatarImage;
        }
    }
    
    if (self.signupDictionary[kShelbySignupNameKey]) {
        self.fullname = self.signupDictionary[kShelbySignupNameKey];
        
        if (self.nameLabel) {
            self.nameLabel.text = self.fullname;
        }
    }

    if (self.signupDictionary[kShelbySignupVideoTypesKey]) {
        self.selectedCellsTitlesArray = self.signupDictionary[kShelbySignupVideoTypesKey];
    } else {
        self.selectedCellsTitlesArray = [@[] mutableCopy];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (NSString *)signupStepNumber
{
    // Should never get here. All Subclasses should implment
    return @"1";
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if (self.selectedCellsTitlesArray) {
        self.signupDictionary[kShelbySignupVideoTypesKey] = self.selectedCellsTitlesArray;
    }
    
    [self saveValueAndResignActiveTextField];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    [super prepareForSegue:segue sender:sender];
    
    [self saveValueAndResignActiveTextField];

    UIViewController *viewController = [segue destinationViewController];
    // Passing the Signup Dictionary to the next VC in the Storyboard
    if ([viewController isKindOfClass:[SignupFlowViewController class]]) {
        ((SignupFlowViewController *)viewController).signupDictionary = self.signupDictionary;
    }
}

- (IBAction)resignKeyboard:(id)sender
{
    UITextField *activeTextField = nil;
    
    if ([self.nameField isFirstResponder]) {
        activeTextField = self.nameField;
    } else if ([self.email isFirstResponder]) {
        activeTextField = self.email;
    } else if ([self.username isFirstResponder]) {
        activeTextField = self.username;
    } else if ([self.password isFirstResponder]) {
        activeTextField = self.password;
    }

    [activeTextField resignFirstResponder];
    [self animateCloseEditing];
}
- (void)popViewController
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)openImagePicker
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Camera Roll", @"Take Photo", nil];
    [actionSheet showInView:self.view];
}


- (IBAction)assignAvatar:(id)sender
{
    [self openImagePicker];
}

- (void)saveValueAndResignActiveTextField
{
    UITextField *activeTextField = nil;
    if ([self.nameField isFirstResponder]) {
        activeTextField = self.nameField;
    } else if ([self.username isFirstResponder]) {
        activeTextField = self.username;
    } else if ([self.password isFirstResponder]) {
        activeTextField = self.password;
    } else if ([self.email isFirstResponder]) {
        activeTextField = self.email;
    }
    
    if (activeTextField) {
        [self modifyDictionaryWithTextFieldValue:activeTextField];
        [activeTextField resignFirstResponder];
        [self animateCloseEditing];
    }
}

- (void)modifyDictionaryWithTextFieldValue:(UITextField *)textField
{
    NSString *value = textField.text;
    if (textField.tag == TextFieldTagName) {
        self.nameField.text = value;
        self.signupDictionary[kShelbySignupNameKey] = value;
    } else if (textField.tag == TextFieldTagEmail) {
        self.email.text = value;
        self.signupDictionary[kShelbySignupEmailKey] = value;
    } else if (textField.tag == TextFieldTagUsername) {
        self.username.text = value;
        self.signupDictionary[kShelbySignupUsernameKey] = value;
    } else if (textField.tag == TextFieldTagPassword) {
        self.password.text = value;
        self.signupDictionary[kShelbySignupPasswordKey] = value;
    }
}

#pragma mark - UIImagePickerControllerDelegate Methods

// This method is called when an image has been chosen from the library or taken from the camera.
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = [info valueForKey:UIImagePickerControllerOriginalImage];
    
    self.avatarImage = image;
    self.avatar.image = self.avatarImage;
    
    if (self.videoTypes) {
        [self.videoTypes reloadData];
    }

    if (self.chooseAvatarButton) {
        [self.chooseAvatarButton setTitle:@"Change" forState:UIControlStateNormal];
    }

    self.signupDictionary[kShelbySignupAvatarKey] = image;
    
    [picker dismissViewControllerAnimated:YES completion:nil];
}


- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)animateCloseEditing
{
    //move up so user can see our text fields
    [UIView animateWithDuration:0.2 animations:^{
        self.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    }];
}

- (void)animateOpenEditing
{
    //move up so user can see our text fields
    [UIView animateWithDuration:0.2 animations:^{
        self.view.frame = CGRectMake(0, [self yOffsetForEditMode], self.view.frame.size.width, self.view.frame.size.height);
    }];
}
- (NSInteger)yOffsetForEditMode
{
    return 0;
}

- (CGRect)nextButtonFrame
{
    return CGRectMake(0.0f, 0.0f, 80.0f, 44.0f);
}

- (UIView *)customLeftButtonView
{
    UIImage *backButtonImage = [UIImage imageNamed:@"navbar_back_button.png"];
    UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [backButton setImage:backButtonImage forState:UIControlStateNormal];
    backButton.frame = CGRectMake(0, 0, backButtonImage.size.width, backButtonImage.size.height);
    [backButton addTarget:self action:@selector(popViewController) forControlEvents:UIControlEventTouchUpInside];

    return backButton;
}

#pragma mark - UITextFieldDelegate Methods
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    if (self.view.frame.origin.x == 0) {
        [self animateOpenEditing];
    }
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [self modifyDictionaryWithTextFieldValue:textField];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self modifyDictionaryWithTextFieldValue:textField];

    [textField resignFirstResponder];

    // Set focus on the next TextField in the form. If last TextField, move view back down.
    //TODO: this should be moved in the individual views, since only they know what order their fields are in
    
    BOOL shouldResign = NO;
    NSInteger tag = textField.tag;
    if (tag == TextFieldTagName) {
        [self.email becomeFirstResponder];
    } else if (tag == TextFieldTagEmail) {
        if (!self.username) {
            shouldResign = YES;
        } else {
            [self.username becomeFirstResponder];
        }
    } else if (tag == TextFieldTagUsername) {
        [self.password becomeFirstResponder];
    } else {
        shouldResign = YES;
    }
    
    if (shouldResign) {
        [self animateCloseEditing];
    }
    
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    // Varification for Name text Field (Making sure we have at least 2 alphanumeric characters - might to verify only character though
    BOOL nextEnabled = NO;
    if (textField == self.nameField || textField == self.email) {
        NSString *text = self.nameField.text;
        if ([text length] > 0) {
            NSString *nonEmptySpaceString = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            
            if ([nonEmptySpaceString length] + [string length] > 1 + range.length) {
                BOOL valid = [[string stringByTrimmingCharactersInSet:[NSCharacterSet alphanumericCharacterSet]] isEqualToString:@""];
                if (valid) {
                    // TODO: Now check email address validity - might need to tweak regex.
                    NSString *emailRegEx = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
                    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegEx];
                    
                    if ([emailTest evaluateWithObject:self.email.text]) {
                        nextEnabled = YES;
                    }
                }
            }
        }
    } else {
        
        // TODO: decide the length of username & password that are acceptable
        NSString *password = self.password.text;
        NSString *username = self.username.text;
        NSInteger passwordLength = [[password stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length];
        NSInteger usernameLength = [[username stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length];
        if (textField == self.password) {
            if ([string isEqualToString:@""]) {
                passwordLength -= range.length;
            } else {
                passwordLength += [string length];
            }
        } else if (textField == self.username) {
            if ([string isEqualToString:@""]) {
                usernameLength -= range.length;
            } else {
                usernameLength += [string length];
            }
        }
        
        if (passwordLength > 0 && usernameLength > 0) {
            nextEnabled = YES;
        }
    }
    self.nextButton.enabled = nextEnabled;

    return YES;
}

#pragma mark - SignupUserInfoDelegate method
- (void)assignAvatar
{
    [self openImagePicker];
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

    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.modalPresentationStyle = UIModalPresentationCurrentContext;
    imagePickerController.sourceType = sourceType;
    imagePickerController.delegate = self;
    [self presentViewController:imagePickerController animated:YES completion:nil];
}

@end
