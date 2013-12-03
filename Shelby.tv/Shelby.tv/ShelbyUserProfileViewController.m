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

@interface ShelbyUserProfileViewController()
@property (nonatomic, strong) ShelbyUserStreamBrowseViewController *currentBrowseVC;
@end

@implementation ShelbyUserProfileViewController {
    UIButton *_followButton;
    BOOL _followButtonShowsFollowing;
}

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
    username.text = self.profileUser.nickname;
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
    _followButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _followButton.frame = CGRectMake(230, 5, 80, 34);
    [_followButton setTitleColor:kShelbyColorGray forState:UIControlStateNormal];
    [_followButton addTarget:self action:@selector(followButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    [self updateFollowButtonToShowFollowing:!_followButtonShowsFollowing];
    _followButton.titleLabel.font = kShelbyFontH4Bold;
    [self.navBar addSubview:_followButton];
    
}

- (void)dismissUserProfile
{
    [self dismissVideoReel];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)setCurrentUser:(User *)currentUser
{
    STVAssert(NO, @"Should not set currentUser on a ProfileVC -- use profileUser");
}

- (void)setProfileUser:(User *)profileUser
{
    if (_profileUser != profileUser) {
        [self willChangeValueForKey:@"profileUser"];
        _profileUser = profileUser;

        self.currentBrowseVC.user = profileUser;
        
        User *currentLoggedInUser = [User currentAuthenticatedUserInContext:[[ShelbyDataMediator sharedInstance] mainThreadContext]];
        [self updateFollowButtonToShowFollowing:[currentLoggedInUser isFollowing:profileUser.publicRollID]];
        
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
    return self.currentBrowseVC;
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
    if (doesFollow) {
        [_followButton setTitle:@"Unfollow" forState:UIControlStateNormal];
        _followButtonShowsFollowing = NO;
    } else {
        [_followButton setTitle:@"Follow" forState:UIControlStateNormal];
        _followButtonShowsFollowing = YES;
    }
}

@end
