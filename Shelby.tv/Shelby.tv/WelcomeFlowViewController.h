//
//  WelcomeFlowViewController.h
//  Shelby.tv
//
//  Created by Daniel Spinosa on 7/17/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyViewController.h"
#import "STVParallaxView.h"

@class WelcomeFlowViewController;

@protocol WelcomeFlowDelegate <NSObject>
- (void)welcomeFlowDidTapPreview:(WelcomeFlowViewController *)welcomeFlowVC;
- (void)welcomeFlowDidTapLogin:(WelcomeFlowViewController *)welcomeFlowVC;
- (void)welcomeFlowDidTapSignup:(WelcomeFlowViewController *)welcomeFlowVC;
@end

@interface WelcomeFlowViewController : ShelbyViewController<STVParallaxViewDelegate>

+ (bool)isWelcomeComplete;

@property (weak, nonatomic) id<WelcomeFlowDelegate> delegate;

@end
