//
//  ShelbyUserInfoViewController.m
//  Shelby.tv
//
//  Created by Keren on 1/10/14.
//  Copyright (c) 2014 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyUserInfoViewController.h"
#import "ShelbyBrain.h"
#import "ShelbySignupViewController.h"
#import "ShelbyUserFollowingViewController.h"
#import "User+Helper.h"
#import "UIImageView+AFNetworking.h"

@interface ShelbyUserInfoViewController ()
@property (nonatomic, strong) IBOutlet UIView *switchContainer;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *userInfoContainerTopSpaceConstraint;
@property (nonatomic, strong) IBOutlet SignupHeaderView *headerView;
@property (nonatomic, strong) IBOutlet UIImageView *userAvatar;
@property (nonatomic, strong) IBOutlet UILabel *userNickname;
@property (nonatomic, strong) IBOutlet UILabel *userName;
@property (nonatomic, strong) IBOutlet UILabel *bio;
@property (nonatomic, strong) IBOutlet UIButton *followButton;
@property (nonatomic, strong) IBOutlet UIButton *editProfileButton;

- (IBAction)activityFollowingToggle:(id)sender;
- (IBAction)toggleFollowUser:(id)sender;
- (IBAction)editProfile:(id)sender;
@end

@implementation ShelbyUserInfoViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    //header
    [self setupUserDisplay];
    
    //switcher: video stream
    [self.streamInfoVC willMoveToParentViewController:self];
    [self addChildViewController:self.streamInfoVC];
    self.streamInfoVC.view.translatesAutoresizingMaskIntoConstraints = NO;
    [self.switchContainer addSubview:self.streamInfoVC.view];
    [self.switchContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[stream]|" options:0 metrics:nil views:@{@"stream": self.streamInfoVC.view}]];
    [self.switchContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[stream]|" options:0 metrics:nil views:@{@"stream": self.streamInfoVC.view}]];
    [self.streamInfoVC didMoveToParentViewController:self];
    
    //switcher: folowing
    [self.followingVC willMoveToParentViewController:self];
    self.followingVC.view.translatesAutoresizingMaskIntoConstraints = NO;
    [self addChildViewController:self.followingVC];
    [self.switchContainer addSubview:self.followingVC.view];
    [self.switchContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[following]|" options:0 metrics:nil views:@{@"following": self.followingVC.view}]];
    [self.switchContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[following]|" options:0 metrics:nil views:@{@"following": self.followingVC.view}]];
    [self.followingVC didMoveToParentViewController:self];
    self.followingVC.user = self.user;
    
    //make sure proper view is on top
    [self activityFollowingToggle:nil];
    
    User *currentUser = [User currentAuthenticatedUserInContext:[[ShelbyDataMediator sharedInstance] mainThreadContext]];
    if ([self.user.userID isEqualToString:currentUser.userID] && [self.user isAnonymousUser]) {
        self.userInfoContainerTopSpaceConstraint.constant = 100;
        self.headerView = [[NSBundle mainBundle] loadNibNamed:@"SignupHeaderView" owner:self options:nil][0];
        self.headerView.delegate = self;
        self.headerView.frame = CGRectMake(0, 64, 320, 80);
        [self.view addSubview:self.headerView];
        [self.view bringSubviewToFront:self.headerView];
        self.headerView.translatesAutoresizingMaskIntoConstraints = NO;
        
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[headerView]|"
                                                                          options:0
                                                                          metrics:nil
                                                                            views:@{@"headerView":self.headerView}]];
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-64-[headerView(80)]"
                                                                          options:0
                                                                          metrics:nil
                                                                            views:@{@"headerView":self.headerView}]];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    User *currentUser = [User currentAuthenticatedUserInContext:[[ShelbyDataMediator sharedInstance] mainThreadContext]];
    if ([self.user.userID isEqualToString:currentUser.userID] && [self.user isAnonymousUser]) {
        [self.user addObserver:self forKeyPath:@"userType" options:NSKeyValueObservingOptionNew context:nil];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if (self.headerView) {
        [self.user removeObserver:self forKeyPath:@"userType" context:nil];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (![self.user isAnonymousUser] && self.headerView) {
        [self.headerView removeFromSuperview];
        self.headerView = nil;
        self.userInfoContainerTopSpaceConstraint.constant = 0;
        [self.user removeObserver:self forKeyPath:@"userType" context:nil];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setUser:(User *)user
{
    if (_user != user) {
        _user = user;
        [self setupUserDisplay];
        self.followingVC.user = user;
    }
}

- (void)setupStreamInfoDisplayChannel:(DisplayChannel *)displayChannel
{
    self.streamInfoVC.displayChannel = displayChannel;
}

- (void)setupUserDisplay
{
    self.userName.text = self.user.name;
    self.userNickname.text = self.user.nickname;
    self.bio.text = self.user.bio;
    self.title = self.user.nickname;
    
    NSURLRequest *imageRequest = [NSURLRequest requestWithURL:[self.user avatarURL]];
    __weak ShelbyUserInfoViewController *weakSelf = self;
    [self.userAvatar setImageWithURLRequest:imageRequest placeholderImage:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
        weakSelf.userAvatar.image = image;
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
        //
    }];
    self.userAvatar.layer.cornerRadius = self.userAvatar.bounds.size.height / 2.f;
    self.userAvatar.layer.masksToBounds = YES;
    
    User *currentUser = [User currentAuthenticatedUserInContext:[[ShelbyDataMediator sharedInstance] mainThreadContext]];
    if ([currentUser.userID isEqualToString:self.user.userID]) {
        self.followButton.hidden = YES;
        if ([currentUser isAnonymousUser]) {
            self.editProfileButton.hidden = YES;
        } else {
            self.editProfileButton.layer.cornerRadius = self.editProfileButton.bounds.size.height / 8.f;
            self.editProfileButton.layer.masksToBounds = YES;
            self.editProfileButton.backgroundColor = kShelbyColorGreen;
        }
    } else {
        self.followButton.layer.cornerRadius = self.followButton.bounds.size.height / 8.f;
        self.followButton.layer.masksToBounds = YES;
        
        self.editProfileButton.hidden = YES;
        BOOL isFollowing = [currentUser isFollowing:self.user.publicRollID];
        [self updateFollowButton:isFollowing];
    }
}

- (void)updateFollowButton:(BOOL)isFollowing
{
    if (isFollowing) {
        //show unfollow
        [self.followButton setTitle:@"Following" forState:UIControlStateNormal];
        self.followButton.backgroundColor = kShelbyColorLightGray;
    } else {
        //show follow
        [self.followButton setTitle:@"Follow" forState:UIControlStateNormal];
        self.followButton.backgroundColor = kShelbyColorGreen;
    }

}

- (IBAction)activityFollowingToggle:(id)sender
{
    UISegmentedControl *switcher = (UISegmentedControl *)sender;
    if (switcher.selectedSegmentIndex == 0) {
        [self.switchContainer insertSubview:self.streamInfoVC.view aboveSubview:self.followingVC.view];
    } else {
        [self.switchContainer insertSubview:self.followingVC.view aboveSubview:self.streamInfoVC.view];
    }
}

- (IBAction)toggleFollowUser:(id)sender
{
    User *currentUser = [User currentAuthenticatedUserInContext:[[ShelbyDataMediator sharedInstance] mainThreadContext]];
    
    BOOL isFollowing = [currentUser isFollowing:self.user.publicRollID];
    BOOL currentButtonActionFollow = [self.followButton.titleLabel.text isEqualToString:@"Follow"];
    
    if ((currentButtonActionFollow && isFollowing) || (!currentButtonActionFollow && !isFollowing)) {
        return; // ignore multiple taps
    }
    
    [self updateFollowButton:!isFollowing];
    
    if (isFollowing) {
        [[ShelbyDataMediator sharedInstance] unfollowRoll:self.user.publicRollID];
    } else {
        [[ShelbyDataMediator sharedInstance] followRoll:self.user.publicRollID];
    }

}

- (IBAction)editProfile:(id)sender
{
    ShelbySignupViewController *signupVC = [[ShelbySignupViewController alloc] initWithNibName:@"SignupView-iPad" bundle:nil];
    signupVC.modalPresentationStyle = UIModalPresentationPageSheet;
    signupVC.prepareForSignup = NO;
    
    [((ShelbyNavigationViewController *)self.navigationController) presentViewController:signupVC animated:YES completion:nil];
    
}

#pragma mark - ShelbyVideoContentBrowsingViewControllerProtocol

- (void)scrollCurrentlyPlayingIntoView
{
    [self.streamInfoVC scrollCurrentlyPlayingIntoView];
}

- (DisplayChannel *)displayChannel
{
    return self.streamInfoVC.displayChannel;
}

#pragma mark - SignupHeaderDelegate
- (void)signupUser
{
    ShelbySignupViewController *signupVC = [[ShelbySignupViewController alloc] initWithNibName:@"SignupView-iPad" bundle:nil];
    signupVC.modalPresentationStyle = UIModalPresentationPageSheet;
    signupVC.prepareForSignup = YES;
    
    [((ShelbyNavigationViewController *)self.navigationController) presentViewController:signupVC animated:YES completion:nil];
}
@end
