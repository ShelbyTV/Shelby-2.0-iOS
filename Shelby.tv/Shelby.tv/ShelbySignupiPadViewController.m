//
//  ShelbySignupViewControlleriPad.m
//  Shelby.tv
//
//  Created by Joshua Samberg on 3/27/14.
//  Copyright (c) 2014 Shelby TV, Inc. All rights reserved.
//

#import "ShelbySignupiPadViewController.h"

@interface ShelbySignupiPadViewController ()
@property (weak, nonatomic) IBOutlet UITextField *stepOneNickname;
@property (weak, nonatomic) IBOutlet UITextField *stepTwoUsername;

@end

@implementation ShelbySignupiPadViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [UIApplication sharedApplication].statusBarHidden = YES;
}

- (void)viewDidAppear:(BOOL)animated
{
    if (self.prepareForSignup) {
        [self.stepOneNickname becomeFirstResponder];
    } else {
        [self.stepTwoUsername becomeFirstResponder];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [UIApplication sharedApplication].statusBarHidden = NO;
}

#pragma mark - Overidden Abstract Methods
- (void)presentImageChooserActionSheetForAvatarView:(UIView *)avatarView
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Camera Roll", @"Take Photo", nil];
    [actionSheet showFromRect:avatarView.frame inView:self.view animated:YES];
}

- (void)presentPhotoAlbumImagePickerController:(UIImagePickerController *)imagePickerController forAvatarView:(UIView *)avatarView
{
    self.popoverVC = [[UIPopoverController alloc] initWithContentViewController:imagePickerController];
    [self.popoverVC presentPopoverFromRect:avatarView.frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionLeft animated:YES];
}

@end
