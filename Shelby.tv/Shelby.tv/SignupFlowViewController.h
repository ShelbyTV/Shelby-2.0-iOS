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

@interface SignupFlowViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, SignupUserInfoDelegate, UIActionSheetDelegate>

@property (nonatomic, strong) UIImage *avatarImage;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *nextButton;  // We don't want to lose reference to nextButton.
@property (nonatomic, weak) NSMutableDictionary *signupDictionary;

- (void)saveValueAndResignActiveTextField;
- (void)animateOpenEditing;
- (void)animateCloseEditing;
@end
