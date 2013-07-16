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
NSString * const kShelbySignupVideoTypesKey      = @"SignupVideoTypes";


typedef NS_ENUM(NSInteger, TextFieldTag) {
    TextFieldTagName,
    TextFieldTagEmail,
    TextFieldTagUsername,
    TextFieldTagPassword
};

typedef NS_ENUM(NSInteger, SignupDialogAlert) {
    SignupDialogAlertNoAvatar
};

@interface SignupFlowViewController ()
@property (weak, nonatomic) IBOutlet UIButton *chooseAvatarButton;
@property (nonatomic, weak) IBOutlet UIImageView *avatar;
@property (nonatomic, weak) IBOutlet UITextField *email;
@property (nonatomic, weak) IBOutlet UILabel *emailLabel;
@property (nonatomic, weak) IBOutlet UITextField *nameField;
@property (nonatomic, weak) IBOutlet UILabel *nameLabel;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *nextButton;
@property (nonatomic, weak) IBOutlet UITextField *password;
@property (nonatomic, weak) IBOutlet UITextField *username;
@property (nonatomic, weak) IBOutlet UICollectionView *videoTypes;
@property (nonatomic, strong) NSMutableArray *selectedCellsTitlesArray;
@property (nonatomic, strong) NSString *fullname;
@property (nonatomic, strong) UIImage *avatarImage;

- (IBAction)assignAvatar:(id)sender;
- (IBAction)signup:(id)sender;
- (IBAction)goBack:(id)sender;
- (IBAction)resignKeyboard:(id)sender;

// Social Actions
- (IBAction)connectoToFacebook:(id)sender;
- (IBAction)connectoToTwitter:(id)sender;

// Initiate Segues
- (IBAction)gotoChooseVideoTypes:(id)sender;
- (IBAction)gotoSocialNetworks:(id)sender;
- (IBAction)gotoMyAccount:(id)sender;
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
    
    // Custom "Back" buttons.
    if (self.navigationItem.leftBarButtonItem && [self.navigationItem.leftBarButtonItem.title isEqualToString:@"Back"]) {
        UIImage *backButtonImage = [UIImage imageNamed:@"navbar_back_button.png"];
        UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
        
        [backButton setImage:backButtonImage forState:UIControlStateNormal];
        
        backButton.frame = CGRectMake(0, 0, backButtonImage.size.width, backButtonImage.size.height);
        
        [backButton addTarget:self action:@selector(popViewController) forControlEvents:UIControlEventTouchUpInside];
        
        UIBarButtonItem *backBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
        self.navigationItem.leftBarButtonItem = backBarButtonItem;
    }
    
    // If we are on First step or Second step - we might want to disable Next
    if (self.nextButton && ([self.nameField.text isEqualToString:@""] || self.videoTypes)) {
        self.nextButton.enabled = NO;
    }
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
        if ([self.view respondsToSelector:@selector(setName:)]) {
            [self.view performSelector:@selector(setName:) withObject:self.fullname];
        }
        if (self.nameField) {
            self.nameField.text = self.fullname;
        }
        if (self.nameLabel) {
            self.nameLabel.text = self.fullname;
        }
    }
    
    if (self.signupDictionary[kShelbySignupPasswordKey] && self.password) {
        self.password.text = self.signupDictionary[kShelbySignupPasswordKey];
    }
    
    if (self.signupDictionary[kShelbySignupUsernameKey] && self.username) {
        self.username.text = self.signupDictionary[kShelbySignupUsernameKey];
    }

    if (self.signupDictionary[kShelbySignupEmailKey] && (self.email || self.emailLabel)) {
        self.email.text = self.signupDictionary[kShelbySignupEmailKey];
        self.emailLabel.text = self.signupDictionary[kShelbySignupEmailKey];
    }

    if (self.signupDictionary[kShelbySignupVideoTypesKey]) {
        self.selectedCellsTitlesArray = self.signupDictionary[kShelbySignupVideoTypesKey];
        NSMutableString *typesString = [[NSMutableString alloc] init];
        NSInteger count = 0;
        for (NSString *type in self.selectedCellsTitlesArray) {
            if (count > 0) {
                [typesString appendString:@", "];
            }
            [typesString appendString:type];
            count++;
        }
        if ([self.view respondsToSelector:@selector(setVideoTypes:)]) {
            [self.view performSelector:@selector(setVideoTypes:) withObject:typesString];
        }
        // If on Second step and more than 3 selected, enable next button
        if (self.videoTypes && [self.selectedCellsTitlesArray count] > 2) {
            self.nextButton.enabled = YES;
        }
    } else {
        self.selectedCellsTitlesArray = [@[] mutableCopy];
    }
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
    UIViewController *viewController = [segue destinationViewController];
    // Passing the Signup Dictionary to the next VC in the Storyboard
    if ([viewController isKindOfClass:[SignupFlowViewController class]]) {
        ((SignupFlowViewController *)viewController).signupDictionary = self.signupDictionary;
    }

    [self saveValueAndResignActiveTextField];
}

- (IBAction)gotoChooseVideoTypes:(id)sender
{
    if (!self.avatarImage) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Add Your Picture" message:@"Don't be anonymous, let other people see your picture" delegate:self cancelButtonTitle:@"Not Now" otherButtonTitles:@"Choose", nil];
        alertView.tag = SignupDialogAlertNoAvatar;
        [alertView show];
    } else {
        [self performSegueWithIdentifier:@"ChooseVideos" sender:self];
    }
}

- (IBAction)gotoSocialNetworks:(id)sender
{
    [self performSegueWithIdentifier:@"SocialNetworks" sender:self];
}

- (IBAction)gotoMyAccount:(id)sender
{
    [self performSegueWithIdentifier:@"MyAccount" sender:self];
}


- (IBAction)goBack:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
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
    [self resignActiveKeyboard:activeTextField];
}
- (void)popViewController
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)markCellAtIndexPath:(NSIndexPath *)indexPath selected:(BOOL)selected
{
    UICollectionViewCell *cell = [self.videoTypes cellForItemAtIndexPath:indexPath];
    [self markCell:cell selected:selected];
}

- (void)markCell:(UICollectionViewCell *)cell selected:(BOOL)selected
{
    SignupVideoTypeViewCell *videoTypeCell = (SignupVideoTypeViewCell *)cell;

    videoTypeCell.overlay.hidden = !selected;

    if (selected) {
        cell.contentView.layer.borderColor = [UIColor greenColor].CGColor;
        cell.contentView.layer.borderWidth = 5;
    } else {
        cell.contentView.layer.borderWidth = 0;
    }
}

- (void)toggleCellSelectionForIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        //can't select the info section
        return;
    }

    BOOL selected = NO;
    SignupVideoTypeViewCell *cell = (SignupVideoTypeViewCell *)[self.videoTypes cellForItemAtIndexPath:indexPath];
    
    if (cell.title.text) {
        if ([self.selectedCellsTitlesArray containsObject:cell.title.text]) {
            selected = YES;
            [self.selectedCellsTitlesArray removeObject:cell.title.text];
        } else {
            [self.selectedCellsTitlesArray addObject:cell.title.text];
        }
        
        [self.videoTypes reloadData];
    }

    if ([self.selectedCellsTitlesArray count] > 2) {
        self.nextButton.enabled = YES;
    } else {
        self.nextButton.enabled = NO;
    }
    
    [self markCellAtIndexPath:indexPath selected:!selected];
}

- (void)openImagePicker
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Camera Roll", @"Take Photo", nil];
    [actionSheet showInView:self.view];
}

#pragma mark - Signup Form Methods
- (IBAction)signup:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)assignAvatar:(id)sender
{
    [self openImagePicker];
}

// KP KP: TODO: commenting out because need to make sure user has an account - after we implement that, uncomemnt
- (IBAction)connectoToFacebook:(id)sender
{
    UIViewController *parent = self.parentViewController;
    if ([parent conformsToProtocol:@protocol(SignupFlowViewDelegate)]) {
//        [parent performSelector:@selector(connectToFacebook)];
    }
}

// KP KP: TODO: commenting out because need to make sure user has an account - after we implement that, uncomemnt
- (IBAction)connectoToTwitter:(id)sender
{
    UIViewController *parent = self.parentViewController;
    if ([parent conformsToProtocol:@protocol(SignupFlowViewDelegate)]) {
//        [parent performSelector:@selector(connectToTwitter)];
    }
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


- (void)resignActiveKeyboard:(UITextField *)textField
{
    if ([self.view respondsToSelector:@selector(textFieldWillReturn:)]) {
        [self.view performSelector:@selector(textFieldWillReturn:) withObject:textField];
    }
}

#pragma mark - UITextFieldDelegate Methods
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    if ([self.view respondsToSelector:@selector(textFieldWillBeginEditing:)]) {
        [self.view performSelector:@selector(textFieldWillBeginEditing:) withObject:textField];
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
        [self resignActiveKeyboard:textField];
    }
    
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    // Varification for Name text Field (Making sure we have at least 2 alphanumeric characters - might to verify only character though
    if (textField == self.nameField || textField == self.email) {
        BOOL nextEnabled = NO;
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
        self.nextButton.enabled = nextEnabled;
    }

    return YES;
}

#pragma mark - UICollectionViewDelegate Methods
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self toggleCellSelectionForIndexPath:indexPath];
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self toggleCellSelectionForIndexPath:indexPath];
}

#pragma mark - UICollectionView Datasource
- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section
{
    if (section == 1) {
        return 10;
    }
    
    return 1; 
}

- (NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView
{
    return 2;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        SignupUserInfoCell *cell =  [cv dequeueReusableCellWithReuseIdentifier:@"SignupUserInfoCell" forIndexPath:indexPath];
        if (self.avatarImage) {
            cell.avatar.image = self.avatarImage;
        }
        cell.name = self.fullname;
        cell.delegate = self;
        return cell;
    }
    
    SignupVideoTypeViewCell *cell = [cv dequeueReusableCellWithReuseIdentifier:@"VideoType" forIndexPath:indexPath];
    
    NSString *title;
    UIImage *image;
    if (indexPath.row == 0) {
        title = @"Buzzfeed";
        image = [UIImage imageNamed:@"buzzfeed"];
    } else if (indexPath.row == 1) {
        title = @"GoPro";
        image = [UIImage imageNamed:@"gopro"];
    } else if (indexPath.row == 2) {
        title = @"GQ";
        image = [UIImage imageNamed:@"gq"];
    } else if (indexPath.row == 3) {
        title = @"The New York Times";
        image = [UIImage imageNamed:@"nytimes"];
    } else if (indexPath.row == 4) {
        title = @"The Onion";
        image = [UIImage imageNamed:@"onion"];
    } else if (indexPath.row == 5) {
        title = @"PitchFork";
        image = [UIImage imageNamed:@"pitchfork"];
    } else if (indexPath.row == 6) {
        title = @"TED";
        image = [UIImage imageNamed:@"ted"];
    } else if (indexPath.row == 7) {
        title = @"Vice";
        image = [UIImage imageNamed:@"vice"];
    } else if (indexPath.row == 8) {
        title = @"Vogue";
        image = [UIImage imageNamed:@"vogue"];
    } else if (indexPath.row == 9) {
        title = @"Wired";
        image = [UIImage imageNamed:@"wired"];
    }

    cell.title.text = title;
    cell.thumbnail.image = image;

    BOOL selected = NO;
    if (title) {
        NSUInteger index = [self.selectedCellsTitlesArray indexOfObject:title];
        if (index != NSNotFound) {
            selected = YES;
            cell.selectionCounter.text = [NSString stringWithFormat:@"%u", index + 1];
        }
    }
    
    [self markCell:cell selected:selected];
    
    return cell;
}

#pragma mark - UICollectionViewFlowLayoutDelegate Methods
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        return CGSizeMake(320, 220);
    }
    
    return CGSizeMake(160, 160);
}

#pragma mark - SignupUserInfoDelegate method
- (void)assignAvatar
{
    [self openImagePicker];
}

#pragma mark - UIAlertViewDialog Methods
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == SignupDialogAlertNoAvatar) {
        if (buttonIndex == 0) {
            [self performSegueWithIdentifier:@"ChooseVideos" sender:self];
        } else {
            [self assignAvatar];
        }
    }
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
