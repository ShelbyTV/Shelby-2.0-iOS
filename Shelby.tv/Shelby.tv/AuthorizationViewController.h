//
//  AuthorizationViewController.h
//  Shelby.tv
//
//  Created by Keren on 3/13/13.
//  Copyright (c) 2013 Shelby TV. All rights reserved.
//
//  This entire thing is DEPRECATED.
//  Replaced by LoginVC and SignupFlowVC

#import <UIKit/UIKit.h>
#import "ShelbyViewController.h"

//DEPRECATED
@protocol AuthorizationDelegate <NSObject>

//- (void)authorizationDidComplete;
- (void)loginUserWithEmail:(NSString *)email password:(NSString *)password;

//@optional
//- (void)authorizationDidNotComplete;

@end


//DEPRECATED
@interface AuthorizationViewController : ShelbyViewController <UITextFieldDelegate, UIAlertViewDelegate>

//DEPRECATED
@property (weak, nonatomic) id<AuthorizationDelegate> delegate;

//DEPRECATED
- (void)userLoginFailedWithError:(NSString *)errorMessage;

@end
