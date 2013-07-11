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
@end

@interface SignupFlowViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, SignupUserInfoDelegate, UIAlertViewDelegate>
@property (nonatomic, weak) NSMutableDictionary *signupDictionary;
@end
