//
//  WelcomeViewController.h
//  Shelby.tv
//
//  Created by Daniel Spinosa on 8/28/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyViewController.h"

@protocol WelcomeViewDelegate;

@interface WelcomeViewController : ShelbyViewController <UIScrollViewDelegate>

@property (nonatomic, weak) id<WelcomeViewDelegate>delegate;

+ (bool)isWelcomeComplete;

@end

@protocol WelcomeViewDelegate <NSObject>
- (void)welcomeDidTapPreview:(WelcomeViewController *)welcomeVC;
- (void)welcomeDidTapLogin:(WelcomeViewController *)welcomeVC;
- (void)welcomeDidTapSignup:(WelcomeViewController *)welcomeVC;
- (void)welcomeDidTapSignupWithFacebook:(WelcomeViewController *)welcomeVC;
@end
