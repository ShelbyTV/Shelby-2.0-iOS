//
//  ShelbyUserProfileViewController.m
//  Shelby.tv
//
//  Created by Keren on 11/26/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyUserProfileViewController.h"
#import "ShelbyDataMediator.h"
#import "ShelbyUserStreamBrowseViewController.h"
#import "Roll.h"

@interface ShelbyUserProfileViewController()
@property (nonatomic, strong) ShelbyUserStreamBrowseViewController *currentBrowseVC;
@end

@implementation ShelbyUserProfileViewController {
    UIButton *_followButton, *_closeButton;
    UILabel *_username;
    UIActivityIndicatorView *_loadingSpinner;
    BOOL _followButtonShowsFollowing;
}

- (CGFloat)swapAnimationTime
{
    return 0;
}

- (void)setupNavBarView
{
    self.navBar = [[UIView alloc] init];
    [self.view addSubview:self.navBar];
    self.navBar.backgroundColor =  [UIColor colorWithPatternImage:[UIImage imageNamed:@"top-nav-bkgd.png"]];
    self.navBar.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[navBar]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:@{@"navBar":self.navBar}]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[navBar(44)]"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:@{@"navBar":self.navBar}]];

    _username = [[UILabel alloc] initWithFrame:CGRectMake(50, 10, self.view.frame.size.width-100, 24)];
    _username.textAlignment = NSTextAlignmentCenter;
    _username.text = self.profileUser.nickname;
    _username.backgroundColor = [UIColor clearColor];
    _username.textColor = kShelbyColorGray;
    _username.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.navBar addSubview:_username];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-90-[username]-90-|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:@{@"username":_username}]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-10-[username(24)]"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:@{@"username":_username}]];
    
    // Close Button
    _closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _closeButton.frame = CGRectMake(10, 5, 40, 34);
    [_closeButton setTitleColor:kShelbyColorGray forState:UIControlStateNormal];
    [_closeButton addTarget:self action:@selector(dismissUserProfile) forControlEvents:UIControlEventTouchUpInside];
    [_closeButton setTitle:@"Close" forState:UIControlStateNormal];
    _closeButton.titleLabel.font = kShelbyFontH4Bold;
    [self.navBar addSubview:_closeButton];
    
    // Follow Button
    _followButton = [UIButton buttonWithType:kShelbyFontH3Bold];
    _followButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    [_followButton setTitleColor:kShelbyColorGreen forState:UIControlStateNormal];
    [_followButton addTarget:self action:@selector(followButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    [self updateFollowButtonToShowFollowing:!_followButtonShowsFollowing];
    _followButton.titleLabel.font = kShelbyFontH4Bold;
    [self.navBar addSubview:_followButton];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[followButton(80)]-10-|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:@{@"followButton":_followButton}]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-5-[followButton(34)]"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:@{@"followButton":_followButton}]];
    
    //loading spinner
    _loadingSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    _loadingSpinner.hidesWhenStopped = YES;
    [self.navBar addSubview:_loadingSpinner];
    _loadingSpinner.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[spinner]-15-|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:@{@"spinner":_loadingSpinner}]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-13-[spinner]"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:@{@"spinner":_loadingSpinner}]];

}

- (void)dismissUserProfile
{
    [self dismissVideoReel];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)setIsLoading:(BOOL)isLoading
{
    if (isLoading) {
        [_loadingSpinner startAnimating];
        _followButton.hidden = YES;
    } else {
        [_loadingSpinner stopAnimating];
        _followButton.hidden = NO;
    }
}

- (void)setProfileUser:(User *)profileUser
{
    if (_profileUser != profileUser) {
        [self willChangeValueForKey:@"profileUser"];
        _profileUser = profileUser;
        self.currentBrowseVC.user = profileUser;
        
        [self updateFollowButtonToShowFollowing:[self.currentUser isFollowing:profileUser.publicRollID]];
        _username.text = self.profileUser.nickname;
        
        [self didChangeValueForKey:@"profileUser"];
    }
}

- (ShelbyStreamBrowseViewController *)initializeStreamBrowseViewController
{
    self.currentBrowseVC = [[ShelbyUserStreamBrowseViewController alloc] initWithNibName:@"ShelbyStreamBrowseView" bundle:nil];
    self.currentBrowseVC.user = self.profileUser;
    
    return self.currentBrowseVC;
}

- (ShelbyStreamBrowseViewController *)streamBrowseViewControllerForChannel:(DisplayChannel *)channel
{
    if ([self.currentBrowseVC.channel.roll.rollID isEqualToString:channel.roll.rollID]) {
        return self.currentBrowseVC;
    }
    
    return nil;
}

- (void)followButtonClicked
{
    if (_followButtonShowsFollowing) {
        [self.masterDelegate followRoll:self.profileUser.publicRollID];
        [self updateFollowButtonToShowFollowing:YES];
    } else {
        [self.masterDelegate unfollowRoll:self.profileUser.publicRollID];
        [self updateFollowButtonToShowFollowing:NO];
    }
}

- (void)updateFollowButtonToShowFollowing:(BOOL)doesFollow
{
    if ([self.currentUser.userID isEqualToString:self.profileUser.userID]) {
        _followButton.hidden = YES;
    } else {
        _followButton.hidden = NO;
        if (doesFollow) {
            [_followButton setTitle:@"UNFOLLOW" forState:UIControlStateNormal];
            _followButtonShowsFollowing = NO;
        } else {
            [_followButton setTitle:@"FOLLOW" forState:UIControlStateNormal];
            _followButtonShowsFollowing = YES;
        }
    }
}

@end
