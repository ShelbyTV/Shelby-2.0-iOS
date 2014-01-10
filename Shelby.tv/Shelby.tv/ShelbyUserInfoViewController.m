//
//  ShelbyUserInfoViewController.m
//  Shelby.tv
//
//  Created by Keren on 1/10/14.
//  Copyright (c) 2014 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyUserInfoViewController.h"
#import "ShelbyStreamInfoViewController.h"

@interface ShelbyUserInfoViewController ()
@property (nonatomic, strong) ShelbyStreamInfoViewController *streamInfoVC;
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
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
