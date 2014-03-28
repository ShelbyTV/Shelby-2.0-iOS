//
//  ShelbySignupViewControlleriPhone.m
//  Shelby.tv
//
//  Created by Joshua Samberg on 3/28/14.
//  Copyright (c) 2014 Shelby TV, Inc. All rights reserved.
//

#import "ShelbySignupiPhoneViewController.h"
#import "ShelbyCustomNavBarButtoniPhone.h"

@interface ShelbySignupiPhoneViewController ()
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIView *coveringDimmerView;
@property (nonatomic, weak) UIView *activeField;
@property (weak, nonatomic) IBOutlet UIView *stepOneView;
@property (weak, nonatomic) IBOutlet UIView *stepTwoView;
@end

@implementation ShelbySignupiPhoneViewController

- (void)setScrollView:(UIScrollView *)scrollView
{
    _scrollView = scrollView;
    [self setScrollViewContentSize];
}

- (void)viewDidLoad{
    [super viewDidLoad];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification object:self.view.window];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:self.view.window];
}

- (void)viewDidLayoutSubviews
{
    [self setScrollViewContentSize];
}

#pragma mark - Keyboard Notifications
- (void)keyboardWasShown:(NSNotification*)aNotification
{
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;

    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;

    // If active text field is hidden by keyboard, scroll it so it's visible
    CGRect aRect = self.stepOneView.frame;
    aRect.size.height -= kbSize.height;
    CGRect activeFieldRect = self.activeField.frame;
    if (!CGRectContainsPoint(aRect, activeFieldRect.origin) ) {
        [self.scrollView scrollRectToVisible:activeFieldRect animated:YES];
    }
}

- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;
}

- (void)setScrollViewContentSize
{
    UIView *containerView = self.prepareForSignup ? self.stepOneView : self.stepTwoView;
    self.scrollView.contentSize = containerView ? containerView.frame.size : CGSizeZero;
    NSLog(@"Here's the container size, width: %f height: %f", containerView.frame.size.width, containerView.frame.size.height);
    NSLog(@"And here's the container size, width: %f height: %f", self.stepTwoView.frame.size.width, self.stepTwoView.frame.size.height);
}

#pragma mark - Overidden Superclass Methods
- (void)doStepTwoCustomSetupForNavItem:(UINavigationItem *)navItem
{
    UIButton *customNavBarButton = [[ShelbyCustomNavBarButtoniPhone alloc] init];
    [customNavBarButton setTitle:@"DONE" forState:UIControlStateNormal];
    [customNavBarButton sizeToFit];
    [customNavBarButton addTarget:self action:@selector(saveProfile:) forControlEvents:UIControlEventTouchUpInside];

    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithCustomView:customNavBarButton];
    navItem.rightBarButtonItem = doneButton;
}

- (void)doStepTwoCustomActionsOnSaveProfile
{
    self.coveringDimmerView.hidden = nil;
}

#pragma mark - Overidden Abstract Methods
- (void)presentImageChooserActionSheetForAvatarView:(UIView *)avatarView
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Camera Roll", @"Take Photo", nil];
    [actionSheet showInView:self.view];
}

- (void)presentPhotoAlbumImagePickerController:(UIImagePickerController *)imagePickerController forAvatarView:(UIView *)avatarView
{
    self.popoverVC = nil;
    imagePickerController.modalPresentationStyle = UIModalPresentationFullScreen;

    [self presentViewController:imagePickerController animated:YES completion:nil];
}

#pragma mark - UITextFieldDelegate Methods
- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    self.activeField = textField;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    self.activeField = nil;
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    self.activeField = textView;
    [self.scrollView scrollRectToVisible:textView.frame animated:YES];
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    self.activeField = nil;
}

@end
