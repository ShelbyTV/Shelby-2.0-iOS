//
//  LoginViewController.h
//  Shelby.tv
//
//  Created by Daniel Spinosa on 7/18/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyViewController.h"

@class LoginViewController;

@protocol LoginViewControllerDelegate <NSObject>
- (void)loginViewControllerDidCancel:(LoginViewController *)loginVC;
- (void)loginViewController:(LoginViewController *)loginVC loginWithUsername:(NSString *)usernameOrEmail password:(NSString *)password;
- (void)loginViewControllerWantsSignup:(LoginViewController *)loginVC;
@end

@interface LoginViewController : ShelbyViewController <UITextFieldDelegate>

@property (weak, nonatomic) id<LoginViewControllerDelegate> delegate;

- (void)loginFailed:(NSString *)errorMessage;

@end
