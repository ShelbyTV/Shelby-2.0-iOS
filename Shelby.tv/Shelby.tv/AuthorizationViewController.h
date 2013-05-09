//
//  AuthorizationViewController.h
//  Shelby.tv
//
//  Created by Keren on 3/13/13.
//  Copyright (c) 2013 Shelby TV. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol AuthorizationDelegate <NSObject>

//- (void)authorizationDidComplete;
- (void)loginUserWithEmail:(NSString *)email password:(NSString *)password;

//@optional
//- (void)authorizationDidNotComplete;

@end


@interface AuthorizationViewController : GAITrackedViewController <UITextFieldDelegate, UIAlertViewDelegate>

@property (weak, nonatomic) id<AuthorizationDelegate> delegate;

- (void)userLoginFailedWithError:(NSString *)errorMessage;
@end
