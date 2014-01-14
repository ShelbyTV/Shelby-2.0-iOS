//
//  ShelbyUserInfoViewController.m
//  Shelby.tv
//
//  Created by Keren on 1/10/14.
//  Copyright (c) 2014 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyUserInfoViewController.h"
#import "ShelbyBrain.h"
#import "User+Helper.h"
#import "UIImageView+AFNetworking.h"

@interface ShelbyUserInfoViewController ()
@property (nonatomic, strong) UIViewController *followingVC;
@property (nonatomic, strong) IBOutlet UIView *switchContainer;
@property (nonatomic, strong) IBOutlet UIImageView *userAvatar;
@property (nonatomic, strong) IBOutlet UILabel *userNickname;
@property (nonatomic, strong) IBOutlet UILabel *userName;
@property (nonatomic, strong) User *user;

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

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(setEntriesNotification:)
                                                 name:kShelbyBrainSetEntriesNotification object:nil];
    

    [self.streamInfoVC willMoveToParentViewController:self];
    [self addChildViewController:self.streamInfoVC];
    [self.switchContainer addSubview:self.streamInfoVC.view];
    [self.streamInfoVC didMoveToParentViewController:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setEntriesNotification:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;
    
    NSMutableArray *channelEntries = userInfo[kShelbyBrainChannelEntriesKey];
    DisplayChannel *channel = userInfo[kShelbyBrainChannelKey];
    
    self.user = userInfo[kShelbyBrainFetchedUserKey];
    self.userName.text = self.user.name;
    self.userNickname.text = self.user.nickname;
    
    NSURLRequest *imageRequest = [NSURLRequest requestWithURL:[self.user avatarURL]];
    __weak ShelbyUserInfoViewController *weakSelf = self;
    [self.userAvatar setImageWithURLRequest:imageRequest placeholderImage:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
        weakSelf.userAvatar.image = image;
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
        //
    }];
    
    [self.streamInfoVC setEntries:channelEntries forChannel:channel];
}

- (IBAction)ActivityFollowingToggle:(id)sender
{
    UISegmentedControl *switcher = (UISegmentedControl *)sender;
    if (switcher.selectedSegmentIndex == 0) {
        self.switchContainer.backgroundColor = [UIColor redColor];
    } else {
        self.switchContainer.backgroundColor = [UIColor greenColor];
    }
}

- (IBAction)toggleFollowUser:(id)sender
{
    
}
@end
