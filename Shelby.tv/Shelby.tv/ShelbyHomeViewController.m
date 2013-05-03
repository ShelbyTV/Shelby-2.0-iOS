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

@interface ShelbyHomeViewController ()
@property (nonatomic, strong) BrowseViewController *browseVC;
@property (nonatomic, weak) IBOutlet UIView *topBar;
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

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)setChannels:(NSArray *)channels
{
    self.browseVC.channels = channels;
}

@end
