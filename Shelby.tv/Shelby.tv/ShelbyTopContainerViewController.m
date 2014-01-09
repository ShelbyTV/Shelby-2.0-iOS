//
//  ShelbyTopContainerViewController.m
//  Shelby.tv
//
//  Created by Keren on 1/8/14.
//  Copyright (c) 2014 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyTopContainerViewController.h"
#import "ShelbyNavigationViewController.h"
#import "ShelbyVideoReelViewController.h"

@interface ShelbyTopContainerViewController ()
@property (nonatomic, strong) ShelbyVideoReelViewController *videoReelVC;
@property (nonatomic, strong) ShelbyNavigationViewController *sideNavigation;
@end

@implementation ShelbyTopContainerViewController

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

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString *segueIdentifier = segue.identifier;
    if ([segueIdentifier isEqualToString:@"SideNavigation"]) {
        self.sideNavigation = segue.destinationViewController;
    } else if ([segueIdentifier isEqualToString:@"VideoReel"]) {
        self.videoReelVC = segue.destinationViewController;
    } else if ([segueIdentifier isEqualToString:@"NowPlaying"]) {
        // TODO
    }
    
    if (self.sideNavigation && self.videoReelVC) {
        self.sideNavigation.videoReelVC = self.videoReelVC;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
