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
@property (nonatomic, weak) IBOutlet UILabel *videoTypesLabel;
@property (nonatomic, strong) NSMutableSet *selectedCellsTitlesSet;
@property (nonatomic, strong) NSString *fullname;
@property (nonatomic, strong) UIImage *avatarImage;

- (IBAction)assignAvatar:(id)sender;
- (IBAction)signup:(id)sender;
- (IBAction)goBack:(id)sender;
- (IBAction)connectoToFacebook:(id)sender;
- (IBAction)connectoToTwitter:(id)sender;
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
        if (self.name) {
            self.name.text = self.fullname;
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

    if (self.signupDictionary[kShelbySignupEmailKey] && self.email) {
        self.email.text = self.signupDictionary[kShelbySignupEmailKey];
    }

    if (self.signupDictionary[kShelbySignupVideoTypesKey]) {
        self.selectedCellsTitlesSet = self.signupDictionary[kShelbySignupVideoTypesKey];
        NSMutableString *typesString = [[NSMutableString alloc] init];
        NSInteger count = 0;
        for (NSString *type in self.selectedCellsTitlesSet) {
            if (count > 0) {
                [typesString appendString:@", "];
            }
            [typesString appendString:type];
            count++;
        }
        self.videoTypesLabel.text = typesString;
        
    } else {
        self.selectedCellsTitlesSet = [[NSMutableSet alloc] init];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if (self.selectedCellsTitlesSet) {
        self.signupDictionary[kShelbySignupVideoTypesKey] = self.selectedCellsTitlesSet;
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

- (IBAction)goBack:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
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
    if (selected) {
        cell.contentView.layer.borderColor = [UIColor blackColor].CGColor;
        cell.contentView.layer.borderWidth = 5;
    } else {
        cell.contentView.layer.borderWidth = 0;
    }
}

- (void)toggleCellSelectionForIndexPath:(NSIndexPath *)indexPath
{
    BOOL selected = NO;
    SignupVideoTypeViewCell *cell = (SignupVideoTypeViewCell *)[self.videoTypes cellForItemAtIndexPath:indexPath];
    
    if (cell.title.text) {
        if ([self.selectedCellsTitlesSet containsObject:cell.title.text]) {
            selected = YES;
            [self.selectedCellsTitlesSet removeObject:cell.title.text];
        } else {
            [self.selectedCellsTitlesSet addObject:cell.title.text];
        }
    }

    [self markCellAtIndexPath:indexPath selected:!selected];
}

- (void)openImagePicker
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
    if ([self.name isFirstResponder]) {
        activeTextField = self.name;
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
    
    self.avatarImage = image;
    self.avatar.image = self.avatarImage;
    
    if (self.videoTypes) {
        [self.videoTypes reloadData];
    }

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
        return 6;
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
        cell.name.text = self.fullname;
        cell.delegate = self;
        return cell;
    }
    
    SignupVideoTypeViewCell *cell = [cv dequeueReusableCellWithReuseIdentifier:@"VideoType" forIndexPath:indexPath];
    
    UIColor *color;
    NSString *title;
    if (indexPath.row == 0) {
        color = [UIColor greenColor];
        title = @"News";
    } else if (indexPath.row == 1) {
        color = [UIColor blueColor];
        title = @"Music";
    } else if (indexPath.row == 2) {
        color = [UIColor redColor];
        title = @"Beatles";
    } else if (indexPath.row == 3) {
        color = [UIColor orangeColor];
        title = @"Sports";
    } else if (indexPath.row == 4) {
        color = [UIColor purpleColor];
        title = @"Apple";
    } else if (indexPath.row == 5) {
        color = [UIColor grayColor];
        title = @"Movies";
    }
    
    cell.contentView.backgroundColor = color;
    cell.title.text = title;

    BOOL selected = NO;
    if ([self.selectedCellsTitlesSet containsObject:title]) {
        selected = YES;
    }
    
    [self markCell:cell selected:selected];
    
    return cell;
}

#pragma mark - UICollectionViewFlowLayoutDelegate Methods
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        return CGSizeMake(320, 200);
    }
    
    return CGSizeMake(160, 160);
}

#pragma mark - SignupUserInfoDelegate method
- (void)assignAvatar
{
    [self openImagePicker];
}
@end
