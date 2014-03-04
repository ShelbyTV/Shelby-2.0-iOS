//
//  WelcomeViewController.h
//  Shelby.tv
//
//  Created by Daniel Spinosa on 8/28/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyViewController.h"

typedef NS_ENUM(NSInteger, ShelbyWelcomeStatus)
{
    ShelbyWelcomeStatusUnstarted, // 0
    ShelbyWelcomeStatusComplete
};

@protocol WelcomeViewDelegate;

@interface WelcomeViewController : ShelbyViewController

@property (nonatomic, weak) id<WelcomeViewDelegate>delegate;

+ (BOOL)isWelcomeComplete;
+ (void)setWelcomeScreenComplete:(ShelbyWelcomeStatus)welcomeStatus;

@end

@protocol WelcomeViewDelegate <NSObject>
- (void)welcomeDidTapPreview:(WelcomeViewController *)welcomeVC;
- (void)welcomeDidTapLogin:(WelcomeViewController *)welcomeVC;
- (void)welcomeDidTapSignup:(WelcomeViewController *)welcomeVC;
- (void)welcomeDidTapSignupWithFacebook:(WelcomeViewController *)welcomeVC;
@end
