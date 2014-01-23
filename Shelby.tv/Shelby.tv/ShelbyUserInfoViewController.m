//
//  ShelbyUserInfoViewController.m
//  Shelby.tv
//
//  Created by Keren on 1/10/14.
//  Copyright (c) 2014 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyUserInfoViewController.h"
#import "ShelbyBrain.h"
#import "ShelbyUserFollowingViewController.h"
#import "User+Helper.h"
#import "UIImageView+AFNetworking.h"

@interface ShelbyUserInfoViewController ()
@property (strong, nonatomic) ShelbyUserFollowingViewController *followingVC;
@property (nonatomic, strong) IBOutlet UIView *switchContainer;
@property (nonatomic, strong) IBOutlet UIImageView *userAvatar;
@property (nonatomic, strong) IBOutlet UILabel *userNickname;
@property (nonatomic, strong) IBOutlet UILabel *userName;

- (IBAction)ActivityFollowingToggle:(id)sender;
- (IBAction)toggleFollowUser:(id)sender;
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
    self.followingVC = [[UIStoryboard storyboardWithName:@"UserFollowing" bundle:nil] instantiateInitialViewController];
    [self.followingVC willMoveToParentViewController:self];
    self.followingVC.view.translatesAutoresizingMaskIntoConstraints = NO;
    [self addChildViewController:self.followingVC];
    [self.switchContainer addSubview:self.followingVC.view];
    [self.switchContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[following]|" options:0 metrics:nil views:@{@"following": self.followingVC.view}]];
    [self.switchContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[following]|" options:0 metrics:nil views:@{@"following": self.followingVC.view}]];
    [self.followingVC didMoveToParentViewController:self];
    
    //make sure proper view is on top
    [self ActivityFollowingToggle:nil];
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
    
    self.title = self.user.nickname;
    
    NSURLRequest *imageRequest = [NSURLRequest requestWithURL:[self.user avatarURL]];
    __weak ShelbyUserInfoViewController *weakSelf = self;
    [self.userAvatar setImageWithURLRequest:imageRequest placeholderImage:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
        weakSelf.userAvatar.image = image;
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
        //
    }];
}

- (IBAction)ActivityFollowingToggle:(id)sender
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

@end
