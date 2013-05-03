//
//  ShelbyHomeViewController.m
//  Shelby.tv
//
//  Created by Keren on 5/1/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyHomeViewController.h"
#import "BrowseViewController.h"
#import "ShelbyBrain.h"
#import "User+Helper.h"

@interface ShelbyHomeViewController ()
@property (nonatomic, weak) IBOutlet UIView *topBar;

@property (nonatomic, strong) UIView *settingsView;
@property (nonatomic, strong) BrowseViewController *browseVC;

@end

@implementation ShelbyHomeViewController

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

    [self.topBar setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"topbar.png"]]];

    BrowseViewController *browseViewController = [[BrowseViewController alloc] initWithNibName:@"BrowseView" bundle:nil];

    [self setBrowseVC:browseViewController];
    [self addChildViewController:browseViewController];
    [browseViewController.view setFrame:CGRectMake(0, 44, browseViewController.view.frame.size.width, browseViewController.view.frame.size.height)];

    [self.view addSubview:browseViewController.view];
    
    [browseViewController didMoveToParentViewController:self];
    
    [self setupSettingsView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)setChannels:(NSArray *)channels
{
    _channels = channels;
    self.browseVC.channels = channels;
}

- (void)setEntries:(NSArray *)channelEntries forChannel:(DisplayChannel *)channel
{
    [self.browseVC setEntries:channelEntries forChannel:channel];
}

- (void)setCurrentUser:(User *)currentUser
{
    _currentUser = nil;//currentUser;
    // KP KP: TODO: need to have fetch user return the logged in user or nil.
//    [self setupSettingsView];
}

// KP KP: TODO: maybe create a special UserAvatarView, pass a target to it.
- (void)setupSettingsView
{
    // KP KP: TODO: once fetching user done correctly, add the two targets. 
    [self.settingsView removeFromSuperview];
    if (self.currentUser) {
        _settingsView = [[UIView alloc] initWithFrame:CGRectMake(950, 0, 60, 44)];
        UIImageView *userAvatar = [[UIImageView alloc] initWithFrame:CGRectMake(25, 7, 30, 30)];
        [userAvatar.layer setCornerRadius:5];
        [userAvatar.layer setMasksToBounds:YES];
        [AsynchronousFreeloader loadImageFromLink:self.currentUser.userImage
                                     forImageView:userAvatar
                                  withPlaceholder:nil
                                   andContentMode:UIViewContentModeScaleAspectFit];
        [self.settingsView addSubview:userAvatar];
        UIButton *settings = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 60, 44)];
//        [settings addTarget:self action:@selector(showSettings) forControlEvents:UIControlEventTouchUpInside];
        [self.settingsView addSubview:settings];
    } else {
        _settingsView = [[UIView alloc] initWithFrame:CGRectMake(950, 0, 120, 44)];
        UIButton *login = [UIButton buttonWithType:UIButtonTypeCustom];
        [login setFrame:CGRectMake(7, 7, 60, 30)];
        [login setBackgroundImage:[UIImage imageNamed:@"login.png"] forState:UIControlStateNormal];
        [login setTitle:@"Login" forState:UIControlStateNormal];
        [[login titleLabel] setFont:[UIFont fontWithName:@"HelveticaNeue-Bold" size:14]];
        [[login titleLabel] setTextColor:[UIColor whiteColor]];
//        [login addTarget:self action:@selector(login) forControlEvents:UIControlEventTouchUpInside];
        [self.settingsView addSubview:login];
    }
    
    [self.view addSubview:self.settingsView];
}

@end
