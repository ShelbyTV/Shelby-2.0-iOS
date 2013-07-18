//
//  SignupFlowViewController.h
//  Shelby.tv
//
//  Created by Keren on 7/8/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SignupUserInfoCell.h"

extern NSString * const kShelbySignupAvatarKey;
extern NSString * const kShelbySignupEmailKey;
extern NSString * const kShelbySignupNameKey;
extern NSString * const kShelbySignupPasswordKey;
extern NSString * const kShelbySignupUsernameKey;
extern NSString * const kShelbySignupVideoTypesKey;

@protocol SignupFlowViewDelegate <NSObject>
- (void)connectToFacebook;
- (void)connectToTwitter;
- (void)signupUser;
- (void)completeSignup;
@end

@interface SignupFlowViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate, SignupUserInfoDelegate, UIActionSheetDelegate>

@property (nonatomic, strong) UIImage *avatarImage;
@property (nonatomic, strong) NSString *fullname;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *nextButton;  // We don't want to lose reference to nextButton.
@property (nonatomic, strong) NSMutableArray *selectedCellsTitlesArray;
@property (nonatomic, weak) NSMutableDictionary *signupDictionary;
@property (nonatomic, weak) IBOutlet UICollectionView *videoTypes;

// Might want to move textfields to corresponding VC, but for now, leaving all TextFields here for now.
@property (nonatomic, weak) IBOutlet UITextField *email;
@property (nonatomic, weak) IBOutlet UITextField *nameField;
@property (nonatomic, weak) IBOutlet UITextField *password;
@property (nonatomic, weak) IBOutlet UITextField *username;

- (void)saveValueAndResignActiveTextField;
- (void)animateOpenEditing;
- (void)animateCloseEditing;
- (NSInteger)yOffsetForEditMode;
@end
