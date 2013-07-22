//
//  SignupFlowNavigationViewController.h
//  Shelby.tv
//
//  Created by Keren on 7/8/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SignupFlowViewController.h"

@protocol SignupFlowNavigationViewDelegate <NSObject>
// KP KP: TODO: take these protocol and make a new protocol out of it (SocialDelegate) and have both, settings and SignupFlow use it.
- (void)connectToFacebook;
- (void)connectToTwitter;
- (void)createUserWithName:(NSString *)name
                  andEmail:(NSString *)email;
- (void)completeSignupUserWithName:(NSString *)name
                          username:(NSString *)username
                          password:(NSString *)password
                             email:(NSString *)email
                            avatar:(UIImage *)image
                          andRolls:(NSArray *)rolls;
@end


@interface SignupFlowNavigationViewController : UINavigationController <SignupFlowViewDelegate>

@property (nonatomic, weak) id<SignupFlowNavigationViewDelegate> signupDelegate;
@end
