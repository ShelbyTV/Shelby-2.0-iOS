//
//  WelcomeLoginView.m
//  Shelby.tv
//
//  Created by Daniel Spinosa on 8/28/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "WelcomeLoginView.h"

@interface WelcomeLoginView()
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIButton *signupWithFacebookButton;
@property (weak, nonatomic) IBOutlet UIButton *createAccountButton;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UIButton *previewButton;
@end

@implementation WelcomeLoginView

- (void)awakeFromNib
{
    self.titleLabel.font = kShelbyFontH2;

    //button backgrounds
    [self.loginButton setBackgroundImage:[[UIImage imageNamed:@"green-button-background"] resizableImageWithCapInsets:UIEdgeInsetsMake(2, 2, 2, 2)] forState:UIControlStateNormal];
    [self.signupWithFacebookButton setBackgroundImage:[[UIImage imageNamed:@"facebook-button-background"] resizableImageWithCapInsets:UIEdgeInsetsMake(2, 2, 2, 2)] forState:UIControlStateNormal];
    [self.previewButton setBackgroundImage:[[UIImage imageNamed:@"secondary-button-background"] resizableImageWithCapInsets:UIEdgeInsetsMake(2, 2, 2, 2)] forState:UIControlStateNormal];
}

@end
