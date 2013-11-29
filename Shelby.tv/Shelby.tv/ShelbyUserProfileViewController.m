//
//  ShelbyUserProfileViewController.m
//  Shelby.tv
//
//  Created by Keren on 11/26/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyUserProfileViewController.h"

@implementation ShelbyUserProfileViewController

- (CGFloat)swapAnimationTime
{
    return 0;
}

- (void)setupNavBarView
{
    self.navBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
    self.navBar.backgroundColor = [UIColor blackColor];
    [self.view addSubview:self.navBar];
    self.navBar.autoresizesSubviews = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    // Close Button
    UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    closeButton.frame = CGRectMake(10, 10, 40, 34);
    [closeButton setTitleColor:kShelbyColorGray forState:UIControlStateNormal];
    [closeButton addTarget:self action:@selector(dismissUserProfile) forControlEvents:UIControlEventTouchUpInside];
    [closeButton setTitle:@"Close" forState:UIControlStateNormal];
    closeButton.titleLabel.font = kShelbyFontH4Bold;
    [self.navBar addSubview:closeButton];
}

- (void)dismissUserProfile
{
    [self dismissVideoReel];
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
