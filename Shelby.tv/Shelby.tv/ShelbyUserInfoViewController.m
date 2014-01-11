//
//  ShelbyUserInfoViewController.m
//  Shelby.tv
//
//  Created by Keren on 1/10/14.
//  Copyright (c) 2014 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyUserInfoViewController.h"
#import "ShelbyBrain.h"

@interface ShelbyUserInfoViewController ()
@property (nonatomic, strong) UIViewController *followingVC;
@property (nonatomic, strong) IBOutlet UIView *switchContainer;

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
    
    [self.streamInfoVC setupEntries:channelEntries forChannel:channel];
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
