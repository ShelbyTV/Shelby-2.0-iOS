//
//  SignupFlowViewController.m
//  Shelby.tv
//
//  Created by Keren on 7/8/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "SignupFlowViewController.h"
#import "SignupVideoTypeViewCell.h"

NSString * const kShelbySignupAvatarKey          = @"SignupAvatar";
NSString * const kShelbySignupEmailKey           = @"SignupEmail";
NSString * const kShelbySignupNameKey            = @"SignupName";
NSString * const kShelbySignupPasswordKey        = @"SignupPassword";
NSString * const kShelbySignupUsernameKey        = @"SignupUsername";


typedef NS_ENUM(NSInteger, TextFieldTag) {
    TextFieldTagName,
    TextFieldTagEmail,
    TextFieldTagUsername,
    TextFieldTagPassword
};

#define kShelbySignupFlowViewYOriginEditMode -180

@interface SignupFlowViewController ()
@property (nonatomic, weak) IBOutlet UIImageView *avatar;
@property (nonatomic, weak) IBOutlet UITextField *email;
@property (nonatomic, weak) IBOutlet UITextField *name;
@property (nonatomic, weak) IBOutlet UILabel *nameLabel;
@property (nonatomic, weak) IBOutlet UITextField *password;
@property (nonatomic, weak) IBOutlet UIButton *skipSocial;
@property (nonatomic, weak) IBOutlet UITextField *username;
@property (nonatomic, weak) IBOutlet UICollectionView *videoTypes;

- (IBAction)assignAvatar:(id)sender;
- (IBAction)signup:(id)sender;
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
    
    // Assign Tags to TextFields - So we can differenciate them.
    self.name.tag = TextFieldTagName;
    self.email.tag = TextFieldTagEmail;
    self.username.tag = TextFieldTagUsername;
    self.password.tag = TextFieldTagPassword;
    
    // Password field should be secure
    self.password.secureTextEntry = YES;
    
    // Underline text
    if (self.skipSocial) {
        NSMutableAttributedString *attributeString = [[NSMutableAttributedString alloc] initWithString:self.skipSocial.titleLabel.text];
        [attributeString addAttribute:NSUnderlineStyleAttributeName
                                value:[NSNumber numberWithInt:1]
                                range:(NSRange){0,[attributeString length]}];
        self.skipSocial.titleLabel.attributedText = attributeString;
    }

    self.videoTypes.allowsMultipleSelection = YES;
    [self.videoTypes registerNib:[UINib nibWithNibName:@"SignupVideoTypeViewCell" bundle:nil] forCellWithReuseIdentifier:@"VideoType"];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if (self.signupDictionary[kShelbySignupAvatarKey]) {
        self.avatar.image = self.signupDictionary[kShelbySignupAvatarKey];
    }
    
    if (self.signupDictionary[kShelbySignupNameKey]) {
        self.name.text = self.signupDictionary[kShelbySignupNameKey];
        self.nameLabel.text = self.signupDictionary[kShelbySignupNameKey];
    }
    
    if (self.signupDictionary[kShelbySignupPasswordKey]) {
        self.password.text = self.signupDictionary[kShelbySignupPasswordKey];
    }
    
    if (self.signupDictionary[kShelbySignupUsernameKey]) {
        self.username.text = self.signupDictionary[kShelbySignupUsernameKey];
    }

    if (self.signupDictionary[kShelbySignupEmailKey]) {
        self.email.text = self.signupDictionary[kShelbySignupEmailKey];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    UIViewController *viewController = [segue destinationViewController];
    // Passing the Signup Dictionary to the next VC in the Storyboard
    if ([viewController isKindOfClass:[SignupFlowViewController class]]) {
        ((SignupFlowViewController *)viewController).signupDictionary = self.signupDictionary;
    }
}

#pragma mark - Signup Form Methods
- (IBAction)signup:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)assignAvatar:(id)sender
{
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeSavedPhotosAlbum]) {
        UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
        imagePickerController.modalPresentationStyle = UIModalPresentationCurrentContext;
        imagePickerController.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
        imagePickerController.delegate = self;
        [self presentViewController:imagePickerController animated:YES completion:nil];
    } else {
        // Error message - should not get here. All supported deviced should have a camera - and hence a saved photo album
    }
}

- (void)modifyDictionaryWithTextFieldValue:(UITextField *)textField
{
    NSString *value = textField.text;
    if (textField.tag == TextFieldTagName) {
        self.name.text = value;
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
    
    self.avatar.image = image;

    self.signupDictionary[kShelbySignupAvatarKey] = image;
    
    [picker dismissViewControllerAnimated:YES completion:nil];
}


- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITextFieldDelegate Methods
// If in last Signup Flow Form, make sure to animate the view up so the keyboard will not block
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    
    NSInteger tag = textField.tag;
    if (self.view.frame.origin.y != kShelbySignupFlowViewYOriginEditMode && (tag == TextFieldTagEmail || tag == TextFieldTagUsername || tag == TextFieldTagPassword)) {
        [UIView animateWithDuration:0.2 animations:^{
            self.view.frame = CGRectMake(0, kShelbySignupFlowViewYOriginEditMode, self.view.frame.size.width, self.view.frame.size.height);
        }];
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
    NSInteger tag = textField.tag;
    if (tag == TextFieldTagEmail) {
        [self.username becomeFirstResponder];
    } else if (tag == TextFieldTagUsername) {
        [self.password becomeFirstResponder];
    } else if (tag == TextFieldTagPassword && self.view.frame.origin.y == kShelbySignupFlowViewYOriginEditMode) {
        [UIView animateWithDuration:0.2 animations:^{
            self.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
        }];
    }
    
    return YES;
}

#pragma mark - UICollectionViewDelegate Methods
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    
    cell.contentView.layer.borderColor = [UIColor blackColor].CGColor;
    cell.contentView.layer.borderWidth = 5;
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    
    cell.contentView.layer.borderWidth = 0;
}

#pragma mark - UICollectionView Datasource
- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section
{
    if (section == 0) {
        return 6;
    }
    
    return 0; // Right now, 1 section
}

- (NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView
{
    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    SignupVideoTypeViewCell *cell = [cv dequeueReusableCellWithReuseIdentifier:@"VideoType" forIndexPath:indexPath];
    
    UIColor *color;
    if (indexPath.row == 0) {
        color = [UIColor greenColor];
    } else if (indexPath.row == 1) {
        color = [UIColor blueColor];
    } else if (indexPath.row == 2) {
        color = [UIColor redColor];
    } else if (indexPath.row == 3) {
        color = [UIColor orangeColor];
    } else if (indexPath.row == 4) {
        color = [UIColor purpleColor];
    } else if (indexPath.row == 5) {
        color = [UIColor grayColor];
    }
    
    cell.contentView.backgroundColor = color;
    
    return cell;
}

@end
