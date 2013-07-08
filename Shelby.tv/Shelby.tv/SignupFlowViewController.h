//
//  SignupFlowViewController.h
//  Shelby.tv
//
//  Created by Keren on 7/8/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
extern NSString * const kShelbySignupAvatarKey;
extern NSString * const kShelbySignupEmailKey;
extern NSString * const kShelbySignupNameKey;
extern NSString * const kShelbySignupPasswordKey;
extern NSString * const kShelbySignupUsernameKey;

@interface SignupFlowViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate, UICollectionViewDataSource, UICollectionViewDelegate>
@property (nonatomic, weak) NSMutableDictionary *signupDictionary;
@end
