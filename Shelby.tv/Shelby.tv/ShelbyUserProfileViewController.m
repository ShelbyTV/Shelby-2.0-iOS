//
//  ShelbyUserProfileViewController.m
//  Shelby.tv
//
//  Created by Keren on 11/26/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyUserProfileViewController.h"
#import "ShelbyUserStreamBrowseViewController.h"

@interface ShelbyUserProfileViewController()
@property (nonatomic, strong) ShelbyUserStreamBrowseViewController *currentBrowseVC;
@end

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

    UILabel *username = [[UILabel alloc] initWithFrame:CGRectMake(50, 10, self.view.frame.size.width-100, 24)];
    username.textAlignment = NSTextAlignmentCenter;
    username.text = self.currentUser.nickname;
    username.backgroundColor = [UIColor clearColor];
    username.textColor = kShelbyColorGray;
    
    [self.navBar addSubview:username];
    
    // Close Button
    UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    closeButton.frame = CGRectMake(10, 5, 40, 34);
    [closeButton setTitleColor:kShelbyColorGray forState:UIControlStateNormal];
    [closeButton addTarget:self action:@selector(dismissUserProfile) forControlEvents:UIControlEventTouchUpInside];
    [closeButton setTitle:@"Close" forState:UIControlStateNormal];
    closeButton.titleLabel.font = kShelbyFontH4Bold;
    [self.navBar addSubview:closeButton];
    
    // Follow Button
    UIButton *followButton = [UIButton buttonWithType:UIButtonTypeCustom];
    followButton.frame = CGRectMake(250, 5, 60, 34);
    [followButton setTitleColor:kShelbyColorGray forState:UIControlStateNormal];
    [followButton addTarget:self action:@selector(followUserProfile) forControlEvents:UIControlEventTouchUpInside];
    [followButton setTitle:@"Follow" forState:UIControlStateNormal];
    followButton.titleLabel.font = kShelbyFontH4Bold;
    [self.navBar addSubview:followButton];
    
}

- (void)dismissUserProfile
{
    [self dismissVideoReel];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)followUserProfile
{
    [self.masterDelegate followUser:self.currentUser.publicRollID];
}

- (void)setCurrentUser:(User *)currentUser
{
    [super setCurrentUser:currentUser];
    
    self.currentBrowseVC.currentUser = currentUser;
}

- (ShelbyStreamBrowseViewController *)initializeStreamBrowseViewController
{
    self.currentBrowseVC = [[ShelbyUserStreamBrowseViewController alloc] initWithNibName:@"ShelbyStreamBrowseView" bundle:nil];
    self.currentBrowseVC.currentUser = self.currentUser;
    
    
    return self.currentBrowseVC;
}

- (ShelbyStreamBrowseViewController *)streamBrowseViewControllerForChannel:(DisplayChannel *)channel
{
    return self.currentBrowseVC;
}

@end
